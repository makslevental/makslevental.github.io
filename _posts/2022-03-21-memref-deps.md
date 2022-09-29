---
layout: post
published: true
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: MemRef dependence checks in MLIR
---

 <!--more-->

# Setting

Suppose you have this MLIR program representing two nested for loops:


<a name="firstloopnest"></a>
```cpp
// loops.mlir

#map0 = affine_map<(d0, d1) -> (d0)>
#map1 = affine_map<(d0, d1) -> (d1)>
#map2 = affine_map<(d0, d1) -> (d0 - 2)>

func.func @kernel() {
  %0 = memref.alloc() : memref<10x10xf32>
  %cst = arith.constant 7.000000e+00 : f32
  affine.for %arg0 = 0 to 9 {
    affine.for %arg1 = 0 to 9 {
      %1 = affine.apply #map0(%arg0, %arg1)
      %2 = affine.apply #map1(%arg0, %arg1)
      affine.store %cst, %0[%1, %2] : memref<10x10xf32>
      %3 = affine.apply #map2(%arg0, %arg1)
      %4 = affine.apply #map1(%arg0, %arg1)
      %5 = affine.load %0[%3, %4] : memref<10x10xf32>
    }
  }
  return
}
```

Note that a more succinct IR is

```cpp
// loops.mlir

#map0 = affine_map<(d0, d1) -> (d0)>
#map1 = affine_map<(d0, d1) -> (d1)>
#map2 = affine_map<(d0, d1) -> (d0 - 2)>

func.func @kernel() {
  %0 = memref.alloc() : memref<10x10xf32>
  %cst = arith.constant 7.000000e+00 : f32
  affine.for %arg0 = 0 to 9 {
    affine.for %arg1 = 0 to 9 {
      affine.store %cst, %0[%arg0, %arg1] : memref<10x10xf32>
      %5 = affine.load %0[%arg0 - 2, %arg1] : memref<10x10xf32>
    }
  }
  return
}
```

If you're not familiar with MLIR syntax, the (roughly) equivalent python program is 

```python
import numpy as np

map0 = lambda d0, d1: d0
map1 = lambda d0, d1: d1
map2 = lambda d0, d1: d0 - 2

def kernel():
  v0 = np.empty((10, 10))
  vcst = 7.000000e+00
  for varg0 in range(0, 9):
    for varg1 in range(0, 9):
      v1 = map0(varg0, varg1)
      v2 = map1(varg0, varg1)
      v0[v1, v2] = vcst
      v3 = map2(varg0, varg1)
      v4 = map1(varg0, varg1)
      v5 = v0[v3, v4]
  return
```

What are the loop carried observed? A close look shows that 

```cpp
%5 = affine.load %0[%arg0 - 2, %arg1] : memref<10x10xf32>
```

depends on 

```cpp
affine.store %cst, %0[%arg0, %arg1] : memref<10x10xf32>
```

from two iterations prior of the outer loop (i.e., on `%arg0`) through the affine map 

```cpp
#map2 = affine_map<(d0, d1) -> (d0 - 2)>
...
%3 = affine.apply #map2(%arg0, %arg1)
```
The dependency (`%arg1`) on the same store statement but in the same iteration is not considered a loop carried dependency; it's not *carried* over from one loop iteration to another.

# MLIR Affine Analysis

You can get a very formal analysis of this dependency by running `mlir-opt -test-memref-dependence-check < loop.mlir` and sprinkling `std::cerr` and `<thing>.dump()` around in [mlir::checkMemrefAccessDependence](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/lib/Dialect/Affine/Analysis/AffineAnalysis.cpp#L584). 

What do you see? Lots of gobbledygook: 

```bash
srcRel
Domain: 0, Range: 4, Symbols: 0, Locals: 0
6 constraints
(Value Value None None  const)
 1   0  -1   0   0    =    0
 0   1   0  -1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0

dstRel
Domain: 0, Range: 4, Symbols: 0, Locals: 0
6 constraints
(Value Value None None  const)
 1   0  -1   0  -2    =    0
 0   1   0  -1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0

srcDomain
Domain: 0, Range: 2, Symbols: 0, Locals: 2
6 constraints
(Value Value Local Local  const)
 1   0  -1   0   0    =    0
 0   1   0  -1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0

dstDomain
Domain: 0, Range: 2, Symbols: 0, Locals: 2
6 constraints
(Value Value Local Local  const)
 1   0  -1   0  -2    =    0
 0   1   0  -1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0

dstRel.inverse();
Domain: 0, Range: 4, Symbols: 0, Locals: 0
6 constraints
(None None Value Value  const)
-1   0   1   0  -2    =    0
 0  -1   0   1   0    =    0
 0   0   1   0   0   >=    0
 0   0  -1   0   8   >=    0
 0   0   0   1   0   >=    0
 0   0   0  -1   8   >=    0

dstRel.compose(srcRel);
Domain: 0, Range: 4, Symbols: 0, Locals: 0
10 constraints
(Value Value Value Value  const)
-1   0   1   0  -2    =    0
 0  -1   0   1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0
 0   0   1   0   0   >=    0
 0   0  -1   0   8   >=    0
 0   0   0   1   0   >=    0
 0   0   0  -1   8   >=    0

Dependence polyhedron:
Domain: 0, Range: 2, Symbols: 0, Locals: 0
2 constraints
(None None  const)
1   0  -2   =   0
0   1   0   =   0
```

## Affine Relations and Constraints

The tableaus above are pretty-printed representations of the affine constraints ([FlatAffineValueConstraints](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/include/mlir/Dialect/Affine/Analysis/AffineStructures.h#L37)) and affine relations ([FlatAffineRelation](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/include/mlir/Dialect/Affine/Analysis/AffineStructures.h#L513)) that define the so-called "Dependence Polyhedron" (the final tableau printed above).
Each of the tableaus (irrespective of whether its a print corresponding to a `FlatAffineValueConstraints` or a `FlatAffineRelation`) represents an integer polyhedron (both `FlatAffineValueConstraints` and `FlatAffineRelation` are subclasses of [IntegerPolyhedron](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/include/mlir/Analysis/Presburger/IntegerRelation.h#L804)).

Let's look at the first one <a name="firsttableau"></a>

```bash
srcRel
6 constraints
(Value Value None None  const)
 1   0  -1   0   0    =    0
 0   1   0  -1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0
 ```

This tableau is a `.dump()` of a `FlatAffineRelation` (indicated by the `rel` in `srcRel`) corresponding to the `MemRefAccess` on the source `memref` (`affine.store %0[%1, %2]`); it is constructed from the affine map that maps the iteration domain (of the loop under consideration) to the elements of the `memref`.
Relation here connotes [relation](https://en.wikipedia.org/wiki/Relation_(mathematics)) in the mathematical sense, i.e., a set of ordered pairs over two sets commonly referred to as the domain and range. 
The tableau codifies the pair of affine maps that index `memref`; codifies in sense of defining the access relation as a set of equations (thereby effectuating the mapping from the domain to the range) and a set of constraints on $\mathbb{Z}$ (thereby defining the domain).
It's a little hard to make out but a slightly less trivial access map better illustrates the representation:


<a name="nontrivial"></a>
```cpp
affine.for %i0 = 0 to 10 {
  affine.for %i1 = 0 to 7 {
    affine.store %cst, %0[%i0 + 3 * %i1, 4 * %i0 + 5 * %i1] : memref<10x10xf32>
    %a = affine.load %0[%i0 + %i1, %i0 + 2 * %i1 + 3] : memref<10x10xf32>
  }
}
```

With memory locations for `%0` represented as `%m0`, `%m1` (i.e., the range of the affine map/relation), the corresponding access relation for the load looks like

$$ \begin{align*}
  (\texttt{i0}, \texttt{i1}) &\rightarrow (\texttt{m0}, \texttt{m1}) \\
  (\texttt{i0}, \texttt{i1}) &\rightarrow (\texttt{n0}, \texttt{n1}) \\
  \texttt{m0} &= \texttt{i0} + \texttt{i1}\\
  \texttt{m1} &= \texttt{i0} + 2\times\texttt{i1} + 3\\

  \texttt{n0} &= \texttt{i0} + 3\times\texttt{i1}\\
  \texttt{n1} &= 4\times\texttt{i0} + 5\times\texttt{i1} \\
\end{align*} $$

which is pretty-printed as

```bash
srcRel
Domain: 0, Range: 4, Symbols: 0, Locals: 0
6 constraints
(Value Value None None  const)
   1    1   -1    0    0 = 0
   1    2    0   -1    3 = 0
   1    0    0    0    0 >= 0
  -1    0    0    0    9 >= 0
   0    1    0    0    0 >= 0
   0   -1    0    0    6 >= 0
```

and thus we see that the first two columns correspond to the domain variables (`%i0`, `%i1` in this case), the second two columns correspond to the range variables (`%m0`, `%m1` in this case), and the last column (on the left hand side) corresponds to constants.

A quick <a name="quickcomment"></a> comment on 

```bash
Domain: 0, Range: 4, Symbols: 0, Locals: 0
(Value Value None None  const)
```

The meanings of [Domain, Range, Symbols, Locals](https://github.com/llvm/llvm-project/blob/5a3fe9a039992935b18f386499cad9aa85eb7f23/mlir/include/mlir/Analysis/Presburger/PresburgerSpace.h#L31) are slightly technical but these strings are printed from [FlatAffineValueConstraints::printSpace](https://github.com/llvm/llvm-project/blob/7a58dd1046a8052619d173b769f32f2df3aafbe8/mlir/lib/Dialect/Affine/Analysis/AffineStructures.cpp#L1370), where the relevant bit is

```cpp
  for (unsigned i = 0, e = getNumDimAndSymbolVars(); i < e; i++) {
    if (hasValue(i))
      os << "Value ";
    else
      os << "None ";
```

where `hasValue` "Returns true if the pos^th variable has an associated Value." 
This is all to say that the reason the columns corresponding to the domain variables are annotated with `Value` while the columns corresponding to the range variables are annotated with `None` is because (as the `hasValue` comment string implies) the range variables aren't actually associated with SSA values[^1].



Back to the tableau itself; one "dead giveaway" about the semantics are the inequality constraints, which capture the loop bounds:

```bash
 1    0    0    0    0  >=    0
-1    0    0    0    9  >=    0
```

captures `0  <= %i0 < 10` and 

```bash
 0    1    0    0    0  >=    0
 0   -1    0    0    6  >=    0
 ```

captures `0  <= %i1 < 7`. Note that, seemingly, the header `Domain: 0, Range: 4, Symbols: 0, Locals: 0` is misleading, since there are in fact
two domain variables and two range variables (this might be a bug in the pretty printing since [FlatAffineRelation](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/include/mlir/Dialect/Affine/Analysis/AffineStructures.h#L508-L512) claims to explicitly distinguish between the two kinds of variables).

Back to the [original tableau](#firsttableau), we can see that it accurately describes the instruction `affine.store %cst, %0[%1, %2]` in the context of the loop nest.
The remainder of the `(src|dst)Rel` and `(src|dst)Domain` tableaus represent the same thing.

## Inverse and Composition

The remaining three tableaus (labeled `dstRel.inverse();`, `dstRel.compose(srcRel);`, `Dependence polyhedron:`) are more interesting.
Comparing 

```cpp
dstRel.inverse();
6 constraints
(None None Value Value  const)
-1   0   1   0  -2    =    0
 0  -1   0   1   0    =    0
 0   0   1   0   0   >=    0
 0   0  -1   0   8   >=    0
 0   0   0   1   0   >=    0
 0   0   0  -1   8   >=    0
```

with

```
dstRel
6 constraints
(Value Value None None  const)
 1   0  -1   0  -2    =    0
 0   1   0  -1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0
 ```

we can see that "inverting" an access relation simply amounts to exchanging the roles of the domain and range variables (see [here](#quickcomment) for the significance of `Value` and `None`).

Composition is even more clever; 


```bash
dstRel.compose(srcRel);
Domain: 0, Range: 4, Symbols: 0, Locals: 0
10 constraints
(Value Value Value Value  const)
-1   0   1   0  -2    =    0
 0  -1   0   1   0    =    0
 1   0   0   0   0   >=    0
-1   0   0   0   8   >=    0
 0   1   0   0   0   >=    0
 0  -1   0   0   8   >=    0
 0   0   1   0   0   >=    0
 0   0  -1   0   8   >=    0
 0   0   0   1   0   >=    0
 0   0   0  -1   8   >=    0
```

While the first 6 rows appear to be the same as `dstRel` do not be fooled - in fact they are not the same (difference of a negative sign). 
And it only appears as such because this is a trivial example.
Again it pays to look at a non-trivial example; using the same [nontrivial](#nontrivial) loop nest as before, we observe these tableaus:

```bash
srcRel
Domain: 0, Range: 4, Symbols: 0, Locals: 0
6 constraints
(Value Value None None  const)
   1    1   -1    0    0 = 0
   1    2    0   -1    3 = 0
   1    0    0    0    0 >= 0
  -1    0    0    0    9 >= 0
   0    1    0    0    0 >= 0
   0   -1    0    0    6 >= 0

dstRel
Domain: 0, Range: 4, Symbols: 0, Locals: 0
6 constraints
(Value Value None None  const)
   1    3   -1    0    0 = 0
   4    5    0   -1    0 = 0
   1    0    0    0    0 >= 0
  -1    0    0    0    9 >= 0
   0    1    0    0    0 >= 0
   0   -1    0    0    6 >= 0

dstRel.compose(srcRel);
Domain: 0, Range: 4, Symbols: 0, Locals: 0
10 constraints
(Value Value Value Value  const)
  -1   -1    1    3    0 = 0
  -1   -2    4    5   -3 = 0
   1    0    0    0    0 >= 0
  -1    0    0    0    9 >= 0
   0    1    0    0    0 >= 0
   0   -1    0    0    6 >= 0
   0    0    1    0    0 >= 0
   0    0   -1    0    9 >= 0
   0    0    0    1    0 >= 0
   0    0    0   -1    6 >= 0
```

What's happening here is the construction of **a mapping between iteration domain of `srcAccess` to the iteration domain of `dstAccess` through accesses the same memory locations**.
Recall the loop body:

```bash
  affine.store %cst, %0[%i0 + 3 * %i1, 4 * %i0 + 5 * %i1] : memref<10x10xf32>
  %a = affine.load %0[%i0 + %i1, %i0 + 2 * %i1 + 3] : memref<10x10xf32>
```

You can formalize the mapping (as already mentioned)

$$ \begin{align*}
  (\texttt{i0}, \texttt{i1}) &\rightarrow (\texttt{m0}, \texttt{m1}) \\
  (\texttt{i0}, \texttt{i1}) &\rightarrow (\texttt{n0}, \texttt{n1}) \\
  \texttt{m0} &= \texttt{i0} + \texttt{i1}\\
  \texttt{m1} &= \texttt{i0} + 2\times\texttt{i1} + 3\\

  \texttt{n0} &= \texttt{i0} + 3\times\texttt{i1}\\
  \texttt{n1} &= 4\times\texttt{i0} + 5\times\texttt{i1} \\
\end{align*} $$

Then setting $(\texttt{m0}, \texttt{m1}) \equiv (\texttt{n0}, \texttt{n1})$ to enforce accesses to the same memory locations and relabeling appropriately

$$ \begin{align*}
  \texttt{i0} + 3\times\texttt{i1} &= \texttt{i0}' + \texttt{i1}'\\
  4\times\texttt{i0} + 5\times\texttt{i1} &= \texttt{i0}' + 2\times\texttt{i1}' + 3\\
\end{align*} $$

or 

$$ \begin{align*}
  -\texttt{i0}' - \texttt{i1}' + \texttt{i0} + 3\times\texttt{i1} &= 0\\
  -\texttt{i0}' - 2\times\texttt{i1}' + 4\times\texttt{i0} + 5\times\texttt{i1} -3 &=  0\\
\end{align*} $$

Thus, the composition "algorithm" proceeds like this:

1. Convert `srcRel` from an affine relation `(srcDomain, srcRange)` to an affine relation `(srcDomain, srcRange ⨯ dstRange)` and `dstRel` from an affine relation `(dstDomain, dstRange)` to an affine relation `(srcDomain ⨯ dstDomain, dstRange)`
  a. `srcRel.appendRangeVar(dstRel.getNumRangeDims());`
  a. `dstRel.insertDomainVar(0, srcRel.getNumDomainDims());`
  b. `dstRel.mergeSymbolVars(srcRel);` - merge and align symbol variables of `dstRel` and `srcRel` such that **both** get union of symbols that are unique
  c. `dstRel.mergeLocalVars(srcRel);` - same (but the implementation is [hairier](https://github.com/llvm/llvm-project/blob/7a58dd1046a8052619d173b769f32f2df3aafbe8/mlir/lib/Analysis/Presburger/IntegerRelation.cpp#L1151-L1163))
2. Convert `srcRel` from `(srcDomain, srcRange ⨯ dstRange)` to `(srcDomain, dstRange)` by converting first `srcRange` range vars to local vars.
  a. `removeDims = srcRel.getNumRangeDims();`
  b. `srcRel.convertToLocal(VarKind::SetDim, srcRel.getNumDomainDims(), srcRel.getNumDomainDims() + removeDims);`
3. Convert `dstRel` from `(srcDomain ⨯ dstDomain, dstRange)` to `(srcDomain, dstRange)` by converting last `dstDomain` domain vars to local vars.
  a. `dstRel.convertToLocal(VarKind::SetDim, dstRel.getNumDomainDims() - removeDims, dstRel.getNumDomainDims());`
4. Add and match domain of `srcRel` to domain of `dstRel`.
5. Add and match range of `dstRel` to range of `srcRel`.
6. Append `dstRel` to `srcRel` and simplify constraints.


The total effect is to construct a map (and access relation) from `srcDomain` to `dstRange`. The two critical steps are (2, 3), i.e., converting `srcRange` range vars to local vars and converting last `dstDomain` domain vars to local vars and then equating them.

Let's walk through this while `dump()`ing along the way.

1. Convert `srcRel` from an affine relation `(srcDomain, srcRange)` to an affine relation `(srcDomain, srcRange ⨯ dstRange)` and `dstRel` from an affine relation `(dstDomain, dstRange)` to an affine relation `(srcDomain ⨯ dstDomain, dstRange)`

   ```bash
   >> unsigned removeDims = srcRel.getNumRangeDims();
   >> srcRel.appendRangeVar(getNumRangeDims()); 
   
   srcRel
   Domain: 0, Range: 6, Symbols: 0, Locals: 0
   6 constraints
   (Value Value None None None None  const)
    1    1   -1    0    0    0    0   =    0
    1    2    0   -1    0    0    3   =    0
    1    0    0    0    0    0    0  >=    0
   -1    0    0    0    0    0    9  >=    0
    0    1    0    0    0    0    0  >=    0
    0   -1    0    0    0    0    6  >=    0

   >> dstRel.insertDomainVar(0, srcRel.getNumDomainDims());

   dstRel
   Domain: 0, Range: 6, Symbols: 0, Locals: 0
   6 constraints
   (None None None None Value Value  const)
    0    0   -1    0    1    3    0 = 0
    0    0    0   -1    4    5    0 = 0
    0    0    0    0    1    0    0 >= 0
    0    0    0    0   -1    0    9 >= 0
    0    0    0    0    0    1    0 >= 0
    0    0    0    0    0   -1    6 >= 0
   
   >> dstRel.mergeSymbolVars(srcRel);

   srcRel 
   Domain: 0, Range: 6, Symbols: 0, Locals: 0
   6 constraints
   (Value Value None None None None  const)
     1    1   -1    0    0    0    0 = 0
     1    2    0   -1    0    0    3 = 0
     1    0    0    0    0    0    0 >= 0
    -1    0    0    0    0    0    9 >= 0
     0    1    0    0    0    0    0 >= 0
     0   -1    0    0    0    0    6 >= 0

   dstRel
   Domain: 0, Range: 6, Symbols: 0, Locals: 0
   6 constraints
   (None None None None Value Value  const)
     0    0   -1    0    1    3    0 = 0
     0    0    0   -1    4    5    0 = 0
     0    0    0    0    1    0    0 >= 0
     0    0    0    0   -1    0    9 >= 0
     0    0    0    0    0    1    0 >= 0
     0    0    0    0    0   -1    6 >= 0
    
    >> dstRel.mergeLocalVars(srcRel);
    
    srcRel
    Domain: 0, Range: 6, Symbols: 0, Locals: 0
    6 constraints
    (Value Value None None None None  const)
     1    1   -1    0    0    0    0 = 0
     1    2    0   -1    0    0    3 = 0
     1    0    0    0    0    0    0 >= 0
    -1    0    0    0    0    0    9 >= 0
     0    1    0    0    0    0    0 >= 0
     0   -1    0    0    0    0    6 >= 0

    dstRel
    Domain: 0, Range: 6, Symbols: 0, Locals: 0
    6 constraints
    (None None None None Value Value  const)
     0    0   -1    0    1    3    0 = 0
     0    0    0   -1    4    5    0 = 0
     0    0    0    0    1    0    0 >= 0
     0    0    0    0   -1    0    9 >= 0
     0    0    0    0    0    1    0 >= 0
     0    0    0    0    0   -1    6 >= 0
   ```
  Notice that not much happens here other than that both relations grow to 7 columns; this is because there are no symbolic variables in our loop nest.

2. Convert `srcRel` from `(srcDomain, srcRange ⨯ dstRange)` to `(srcDomain, dstRange)` by converting first `srcRange` range vars to local vars.

   ```bash
   >> srcRel.convertToLocal(VarKind::SetDim, srcRel.getNumDomainDims(), srcRel.getNumDomainDims() + removeDims);
   >> srcRel.dump();
   
   srcRel
   Domain: 0, Range: 4, Symbols: 0, Locals: 2
   6 constraints
   (Value Value None None Local Local  const)
     1    1    0    0   -1    0    0 = 0
     1    2    0    0    0   -1    3 = 0
     1    0    0    0    0    0    0 >= 0
    -1    0    0    0    0    0    9 >= 0
     0    1    0    0    0    0    0 >= 0
     0   -1    0    0    0    0    6 >= 0
   ```
   Notice the only difference here is the 3rd and 4th columns (the range columns corresponding to `srcRange`) have been swapped with the 5th and 6th columns and relabeled as `Local`.

3. Convert `dstRel` from `(srcDomain ⨯ dstDomain, dstRange)` to `(srcDomain, dstRange)` by converting last `dstDomain` domain vars to local vars.

   ```bash
   >> dstRel.convertToLocal(VarKind::SetDim, dstRel.getNumDomainDims() - removeDims, dstRel.getNumDomainDims());
   
   dstRel
   Domain: 0, Range: 4, Symbols: 0, Locals: 2
   6 constraints
   (None None Value Value Local Local  const)
      0    0    1    3   -1    0    0 = 0
      0    0    4    5    0   -1    0 = 0
      0    0    1    0    0    0    0 >= 0
      0    0   -1    0    0    0    9 >= 0
      0    0    0    1    0    0    0 >= 0
      0    0    0   -1    0    0    6 >= 0
   ```
   Notice the only difference here is the 3rd and 4th columns (the domain columns corresponding to `dstDomain`) have been shuffled and relabeled as `Local`.

4. Add and match domain of `srcRel` to domain of `dstRel`.

   ```bash
   srcRel
   Domain: 0, Range: 4, Symbols: 0, Locals: 2
   6 constraints
   (Value Value Value Value Local Local  const)
      1    1    0    0   -1    0    0 = 0
      1    2    0    0    0   -1    3 = 0
      1    0    0    0    0    0    0 >= 0
     -1    0    0    0    0    0    9 >= 0
      0    1    0    0    0    0    0 >= 0
      0   -1    0    0    0    0    6 >= 0
   ```

5. Add and match range of `dstRel` to range of `srcRel`.

   ```bash
   dstRel
   Domain: 0, Range: 4, Symbols: 0, Locals: 2
   6 constraints
   (Value Value Value Value Local Local  const)
      0    0    1    3   -1    0    0 = 0
      0    0    4    5    0   -1    0 = 0
      0    0    1    0    0    0    0 >= 0
      0    0   -1    0    0    0    9 >= 0
      0    0    0    1    0    0    0 >= 0
      0    0    0   -1    0    0    6 >= 0
   ```

6. Append `dstRel` to `srcRel` and simplify constraints.

   ```bash
   srcRel.append(*dstRel);
   
   srcRel
   Domain: 0, Range: 4, Symbols: 0, Locals: 2
   12 constraints
   (Value Value Value Value Local Local  const)
      1    1    0    0   -1    0    0 = 0
      1    2    0    0    0   -1    3 = 0
      0    0    1    3   -1    0    0 = 0
      0    0    4    5    0   -1    0 = 0
      1    0    0    0    0    0    0 >= 0
     -1    0    0    0    0    0    9 >= 0
      0    1    0    0    0    0    0 >= 0
      0   -1    0    0    0    0    6 >= 0
      0    0    1    0    0    0    0 >= 0
      0    0   -1    0    0    0    9 >= 0
      0    0    0    1    0    0    0 >= 0
      0    0    0   -1    0    0    6 >= 0
  ```
  Now this really is just a concatenation of equality constraints and the inequality constraints corresponding to the `srcRel` and the `dstRel`.
  ```bash
   
   srcRel.removeRedundantLocalVars();
   
   srcRel
   Domain: 0, Range: 4, Symbols: 0, Locals: 0
   10 constraints
   (Value Value Value Value  const)
     -1   -1    1    3    0 = 0
     -1   -2    4    5   -3 = 0
      1    0    0    0    0 >= 0
     -1    0    0    0    9 >= 0
      0    1    0    0    0 >= 0
      0   -1    0    0    6 >= 0
      0    0    1    0    0 >= 0
      0    0   -1    0    9 >= 0
      0    0    0    1    0 >= 0
      0    0    0   -1    6 >= 0
   
   *dstRel = srcRel;
   ```
   The local variables are now redundant because `srcRange` and `dstDomain` have been equated.
   Notice that the elimination is simply gaussian elimination on the last two columns.

## `checkMemrefAccessDependence`

Finally we have enough context to understand how memref access dependencies are checked. 
After taking the inverse of `srcRel` and composing it with `dstRel` **you have a relation between iteration domain of `srcAccess` to the iteration domain of `dstAccess` which access the same memory locations**.
Then [`srcAccess` happens before `dstAccess` ordering constraints](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/lib/Dialect/Affine/Analysis/AffineAnalysis.cpp#L366) are added, based on the number of common loops (up to some user-specified loop depth).
For our [original](#firstloopnest) doubly-nested loop-nest, with "induction variables" `%i` and `%j` wrt the `srcAccess` iteration domain and `%i'` and `%j'` wrt the `dstAccess` iteration domain, equality constraints for all common loops are added except for the "nearest" (i.e., the loop whose body both statements appear in) and a "happen at least one iteration prior" constraint is added for the nearest loop:

1. At loop depth 1, `%i' >= %i + 1`, i.e.
   ```
   %i  %j  %i'   %j'   c 
   -1   0   1     0   -1 >= 0
   ```
  i.e. `-%i + %i' - 1 >= 0` $\iff$ `%i' >= %i + 1`

2. At loop depth 2, `%i' == %i` and `%j' >= %j + 1`, i.e.
   ```
   %i   %j   %i'  %j'   c 
   -1    0    1    0    0 = 0
    0   -1    0    1   -1 >= 0
   ```
   
3. At loop depth 3 (which essentially encodes the dataflow in the enclosing loop body), `%i' == %i` and `%j' == %j`, i.e.,
   ```
   %i   %j   %i'  %j'   c 
   -1    0    1    0    0 = 0
    0   -1    0    1    0 = 0
   ```

Finally the constraint system is [checked for feasibility](https://github.com/llvm/llvm-project/blob/146c3ea0755b05bf764f0a4f80e6aa75005e1351/mlir/lib/Analysis/Presburger/IntegerRelation.cpp#L595) using a combination of [Gaussian](https://en.wikipedia.org/wiki/Gaussian_elimination) and [Fourier-Motzkin elimination](https://en.wikipedia.org/wiki/Fourier%E2%80%93Motzkin_elimination); if the constraint system is infeasible then there's no dependence between the accesses.
If the system is feasible then a dependence does exist and for such a dependence a "direction/distance vector" can be [computed](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/lib/Dialect/Affine/Analysis/AffineAnalysis.cpp#L393).
Distance vectors components are represented by the interval `[lb, ub]` with `lb == ub`; direction vectors components are represented by the interval `[lb, ub]` with `lb < ub`.
In the case of the [nontrivial](#nontrivial) loop nest, for example, there is a dependence from the store to the load at depth 1 with a corresponding pair of dependence vectors (one for each common loop nest) `[1, 7], [-1, 3]`.
In this case (for the nontrivial loop) it's not so clear what these quantities describe so we return to the [original](#firstloopnest); for that loop nest the computed tuples are `[2, 2], [0, 0]` between the store and the load at depth 1, expressing exactly what we observed in the beginning: the load depends on stores from two loop iterations prior.


# Footnotes

[^1]: In reality [mlir::getRelationFromMap](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/lib/Dialect/Affine/Analysis/AffineStructures.cpp#L1752) builds a `FlatAffineValueConstraints` system, which just boils down to a matrix representation (e.g., [variables are just columns](https://github.com/llvm/llvm-project/blob/6d6f6c4d3f40b2d0220fca73b27b8e74e64ba55a/mlir/lib/Analysis/Presburger/IntegerRelation.cpp#L265-L266) in this matrix).


<!-- Actually you won't see all of this - you need to add `.dump()` statements in the appropriate places in [AffineAnalysis.cpp](https://github.com/llvm/llvm-project/blob/487629cc61b56d9346a387411a2454c7be02526a/mlir/lib/Dialect/Affine/Analysis/AffineAnalysis.cpp#L599).

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
``` -->