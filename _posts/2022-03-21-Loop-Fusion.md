---
layout: post
published: true
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: What's going on when fusing affine loops in MLIR?
---

 <!--more-->

# Setting

Suppose you have this MLIR program:

```cpp
// loops.mlir

func @kernel() {
  %m = memref.alloc() : memref<10x10xf32>
  %s0 = arith.constant 7 : index
  %s1 = arith.constant 11 : index
  %s2 = arith.constant 13 : index
  %c1 = arith.constant 1.0 : f32
  affine.for %i0 = 0 to 101 {
    affine.for %i1 = 0 to 51 {
      %a0 = affine.apply affine_map<(d0, d1)[s0, s1] ->
          (d0 * 2 - d1 + -7 * s0 + 3)> (%i0, %i1)[%s0, %s1]
      %a1 = affine.apply affine_map<(d0, d1)[s0, s1] ->
          (d0 * 9 + d1 * 3 + 13 * s1 - 10)> (%i0, %i1)[%s0, %s1]
      affine.store %c1, %m[%a0, %a1] : memref<10x10xf32>
    }
  }

  affine.for %i2 = 0 to 100 {
    affine.for %i3 = 0 to 50 {
      %a0 = affine.apply
        affine_map<(d0, d1)[s0, s1] -> (d0 * 2 - 1)> (%i2, %i3)[%s1, %s2]
      %a1 = affine.apply
        affine_map<(d0, d1)[s0, s1] -> (d1 * 3 + s0 + s1 * 3)> (%i2, %i3)[%s1, %s2]
      %v0 = affine.load %m[%a0, %a1] : memref<10x10xf32>
    }
  }

  return
}
```

and you run `mlir-opt -debug -affine-loop-fusion="fusion-maximal" < loops.mlir`. 
What do you see? Lots of gobbledygook: 

```bash
Load new dialect in Context builtin
Load new dialect in Context builtin
Load new dialect in Context memref
Load new dialect in Context arith
Load new dialect in Context affine
Load new dialect in Context func
Load new dialect in Context cf

...

Checking for dependence at depth: 1 between:
affine.store %cst, %0[%1, %2] : memref<10x10xf32>
%3 = affine.load %0[%1, %2] : memref<10x10xf32>

srcRel
Domain: 0, Range: 4, Symbols: 0 Locals: 0
6 constraints
(Value Value None None  const)
2 -1 -1 0 -46 = 0
9 3 0 -1 133 = 0
1 0 0 0 0 >= 0
-1 0 0 0 100 >= 0
0 1 0 0 0 >= 0
0 -1 0 0 50 >= 0

dstRel
Domain: 0, Range: 4, Symbols: 0 Locals: 0
(Value Value None None  const)
2 0 -1 0 -1 = 0
0 3 0 -1 50 = 0
1 0 0 0 0 >= 0
-1 0 0 0 99 >= 0
0 1 0 0 0 >= 0
0 -1 0 0 49 >= 0

...

dstRel.inverse
Domain: 0, Range: 4, Symbols: 0 Locals: 0
(None None Value Value  const)
-1 0 2 0 -1 = 0
0 -1 0 3 50 = 0
0 0 1 0 0 >= 0
0 0 -1 0 99 >= 0
0 0 0 1 0 >= 0
0 0 0 -1 49 >= 0

dstRel.compose
Domain: 0, Range: 4, Symbols: 0 Locals: 0
(Value Value Value Value  const)
-2 1 2 0 45 = 0
-9 -3 0 3 -83 = 0
1 0 0 0 0 >= 0
-1 0 0 0 100 >= 0
0 1 0 0 0 >= 0
0 -1 0 0 50 >= 0
0 0 1 0 0 >= 0
0 0 -1 0 99 >= 0
0 0 0 1 0 >= 0
0 0 0 -1 49 >= 0

...
```

Actually you won't see all of this - you need to add `.dump()` statements in the appropriate places in [AffineAnalysis.cpp](https://github.com/llvm/llvm-project/blob/487629cc61b56d9346a387411a2454c7be02526a/mlir/lib/Dialect/Affine/Analysis/AffineAnalysis.cpp#L599).

But never mind that - these clearly suggest some kind of [CSP](https://en.wikipedia.org/wiki/Constraint_satisfaction_problem) thing is going on in the background.
Indeed this is the case - whether a fusion is possible in this case (the case of Producer-Consumer fusion) comes down to whether there's a valid insertion point for the producer loop nest (the first one) inside the consumer loop nest (the second one).
Such a valid insertion point must respect the [implicit data dependencies](https://github.com/llvm/llvm-project/blob/01daf97a0b5a2450a84af76f8bdd7636488f125d/mlir/lib/Dialect/Affine/Utils/LoopFusionUtils.cpp#L246) of the two loop nests, namely, in this case, the [RAW](https://en.wikipedia.org/wiki/Hazard_(computer_architecture)#Read_after_write_(RAW)) dependency between `affine.store %c1, %m[%a0, %a1]` and `%v0 = affine.load %m[%a0, %a1]`.
Because the memory accesses of both loop nests are non-trivial (vis-a-vis the affine maps) it's not easy to see (or compute) that such a dependency exists and whether the loop nests can be fused at some depth.
The debug messages give a rough outline of what's being checked but it's subtle so I'll attempt to describe it in greater detail here.

# Details

Consider that in order to fuse the loops we need to find the maximum depth in the consumer loop nest at which we can insert the producer loop body.
This is equivalent to finding the minmium `d` such that there's a dependency between `affine.store %c1, %m[%a0, %a1]` and `%v0 = affine.load %m[%a0, %a1]` (since inserting at depth `d+1` would violate the dependency at depth `d`).
In order to compute such a `d`, [getMaxLoopDepth](https://github.com/llvm/llvm-project/blob/01daf97a0b5a2450a84af76f8bdd7636488f125d/mlir/lib/Dialect/Affine/Utils/LoopFusionUtils.cpp#L246) determines a set of constraints on the loop bounds and the memory accesses (at both the `store` and the `load`) that define an integer set and verifies that the set is non-empty. 

In the first loop nest we have the iteration domain $(i, j) \in \\{[0, 100] \times [0, 50]\\}$ and memory access relation

$$
\begin{align}
a_0 &= 2i - 1j- 46\\
a_1 &= 9i+3j + 133
\end{align}
$$

where I've evaluated the symbols and constants.
In the second loop nest we have the iteration domain $(i, j) \in \\{[0, 99] \times [0, 49]\\}$ and memory access relation

$$
\begin{align}
a_0 &= 2i+0j-1\\
a_1 &= 0i+3j + 50
\end{align}
$$

where I've evaluated the symbols and constants *and included the implicit iteration domain variables* (i.e., $0d_{0}$ and $0d_{1}$).
These two sets of equations, along with the loop bounds, match the `srcRel` and `dstRel` print outs (after bringing all terms to one side):

```
srcRel
Domain: 0, Range: 4, Symbols: 0 Locals: 0
6 constraints
(Value Value None None  const)
2 -1 -1 0 -46 = 0
9 3 0 -1 133 = 0
1 0 0 0 0 >= 0
-1 0 0 0 100 >= 0
0 1 0 0 0 >= 0
0 -1 0 0 50 >= 0

dstRel
Domain: 0, Range: 4, Symbols: 0 Locals: 0
(Value Value None None  const)
2 0 -1 0 -1 = 0
0 3 0 -1 50 = 0
1 0 0 0 0 >= 0
-1 0 0 0 99 >= 0
0 1 0 0 0 >= 0
0 -1 0 0 49 >= 0
```

where the `None None` columns represent $a_0, a_1$.
Naturally, these represent [simplex tableaus](https://en.wikipedia.org/wiki/Simplex_algorithm#Simplex_tableau).
In order to simultaneously describe both iteration domains and memory access relations (at the `store` and the `load`) we must connect/relate/map between them.
Abstractly, this is accomplished by inverting `dstRel` and then composing it with `srcRel`.
In reality this amounts to setting the affine maps equal to each other:

$$
\begin{align*}
2i + -1j + -46 &= 2i' + 0j' + -1  \\
9i +  3j + 133 &= 0i' + 3j' + 50
\end{align*}
$$

$$
\implies
$$

$$
\begin{align*}
2i + -1j + -2i' + 0j' +-45 &= 0  \\
9i +  3j +  0i' +-3j' + 83 &= 0
\end{align*}
$$

This corresponds to (modulo a minus sign) 

```
dstRel.compose
Domain: 0, Range: 4, Symbols: 0 Locals: 0
(Value Value Value Value  const)
-2 1 2 0 45 = 0
-9 -3 0 3 -83 = 0
1 0 0 0 0 >= 0
-1 0 0 0 100 >= 0
0 1 0 0 0 >= 0
0 -1 0 0 50 >= 0
0 0 1 0 0 >= 0
0 0 -1 0 99 >= 0
0 0 0 1 0 >= 0
0 0 0 -1 49 >= 0
```