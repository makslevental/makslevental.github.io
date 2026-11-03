---
layout: post
published: true
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: What happens when you use float induction variables
tags: [llvm, compilers]
---

**TL;DR**: A story about investigating a performance regression and the frustrations of fixing it.
<!--more-->
# Background

What happens when you do something like this in Clang/LLVM?

```c
float out[8];
for (float f = 0; f < 8; f += 1)
  out[(int)f] = f * f;
```

Before [#90942](https://github.com/llvm/llvm-project/pull/90942), it will probably be fully unrolled.
But _after_ #90942, it might not be and that's "probably bad"™[^1].
Specifically if you compile with `-ffast-math`, which the PR identifies as "non-deterministic" w.r.t constant folding, this loop will not be unrolled (see [below](#weeds-why-scev-gave-up) for exactly why SCEV[^2] gives up in this case).

In the "biz" this is called a "regression". There are several ways to mitigate this (the regression). You could just turn off `-ffast-math`. But if you do in fact consider this a regression (you care about performance) then you probably enjoy the `fast` part of `-ffast-math`.
You could rewrite the loop as

```c
float out[8];
for (int f = 0; f < 8; f += 1)
  out[f] = (float)f * (float)f;
```

if you're the code owner/can send a patch. But I don't write real code, I'm a compiler engineer. So I intended to solve it using a rewrite/pass.
Lucky for me there's already a pass which ostensibly does exactly what I want: [IndVarSimplify](https://github.com/llvm/llvm-project/blob/12de240666d9a8174f3f473ee4c20dd2818be8b4/llvm/lib/Transforms/Scalar/IndVarSimplify.cpp#L478), which does exactly what the manual rewrite would. Then the next time SCEV is run maybe a static trip count can be computed 🤞.
And indeed it does work, the loop is unrolled, so the performance regression is mitigated and you/I/we can just go to lunch right? Yea, right. What actually happened to me was some of my benchmarks recovered performance and some of them regressed further!

The issue is `IndVarSimplify` doesn't only rewrite noninteger induction variables, it also performs a bunch of [other transformations](https://github.com/llvm/llvm-project/blob/12de240666d9a8174f3f473ee4c20dd2818be8b4/llvm/lib/Transforms/Scalar/IndVarSimplify.cpp#L2164-L2180):
1. **float IV rewriting**: already described;
2. **IV widening and simplification**: `i32` counters which would be extended on every iteration to index 64-bit addresses (`sext i32 %i to i64`) are just replaced with `i64` (in order to eliminate the repeated `sext` in the loop itself);
3. **exit value rewriting**: values computed in the loop and used after are just replaced with a closed-form value instead (assuming SCEV can figure it out);
4. **exit condition canonicalization**: rewrites exit compares into simpler forms, such as signed compares into unsigned when both sides are known to be non-negative (and also moves the loop-invariant parts of the compare, like `zext`/`trunc` of the bound, out of the loop);
5. **loop exit elimination**: in loops with several exits, conditional exits which are provably never taken are folded away;
6. **linear function test replacement (LFTR)**: rewrites the exit test as an equality check `iv != limit`, with limit computed from the trip count (again, assuming SCEV can figure out the trip count);
7. **sinking of unused invariants**: values computed in the preheader which are only used after the loop are moved into the exit block.

Now, each of these transformations in isolation might be reasonably safe (assumed to be actual optimizations rather than "pessimizations") and even more broadly the whole pass in toto might be reasonable as well for _most_ programs on _most_ targets.
But you should never underestimate the [NFL](https://en.wikipedia.org/wiki/No_free_lunch_theorem): compilers _mathematically_ cannot be optimal across all programs across all targets.
Academically, you can probably talk about Pareto-optimal frontiers of _something_ (some metric) but I don't think any real industrial compiler attempts to discover such a frontier given the enormous input space of programs.
So building/maintaining/extending a compiler inevitably becomes a tedious game of [Whack-A-Mole](https://en.wikipedia.org/wiki/Whac-A-Mole)[^3].

# Dissecting `IndVarSimplify`

Two of the culprits behind the collateral damage (regressions on other benchmarks) were **LFTR** and **sinking of unused invariants**[^4].
Generally, these are reasonable rewrites: shorter live ranges improve performance.
Together with the unrolling and the specific target I'm working on, they backfired.

## Sinking

Sinking backfired in a kind of straightforward way: an instruction which was previously in the preheader (and loop-invariant) was moved to the loop's exit block but unbeknownst to the optimizer (i.e., LLVM) the latency of that instruction was being hidden by the loop body. Moving it to the exit block "exposed" the full latency of the instruction. Concretely you can imagine something like

```llvm
entry:
  %w = load float, ptr %w.p, align 4
  %len = call float @llvm.sqrt.f32(float %w)
  %norm = fdiv float 1.000000e+00, %len
  br label %loop
loop:
  ...         ; %len and %norm not used in here
exit:
  ...
```

becomes

```llvm
entry:
  %w = load float, ptr %w.p, align 4
  br label %loop
loop:
  ...
exit:
  %len = call float @llvm.sqrt.f32(float %w)
  %norm = fdiv float 1.000000e+00, %len
  ...
```

In theory, this transformation frees a register or two for use in the loop body, but it's completely agnostic to the actual latency of the operations.
So `sqrt` and `fdiv`, which are slow on most targets and previously had their latency hidden ("pipelined"/overlapped) because they ran in parallel with the instructions in the loop body, are now on the critical path (they can't start before the loop is completely finished)[^5].

## LFTR

LFTR backfired in a more subtle way.
LFTR rewrites a loop's exit test to be a simple equality comparison against a computed trip count[^6]:

```llvm
define i32 @sum_bytes(ptr %a, i32 %start, i32 %end) {
...
loop:
  %i = phi i32 [ %start, %entry ], [ %inc, %loop ]
  %p = getelementptr inbounds i8, ptr %a, i32 %i
  ...                          ; load from %p, add it to the sum
  %inc = add nsw i32 %i, 1     ; inc = i + 1
  %cmp = icmp slt i32 %i, %end ; cmp = i < end
  br i1 %cmp, label %loop, label %exit
exit:
  ...
}
```

becomes

```llvm
loop.preheader:
  %endp1 = add i32 %end, 1
  br label %loop
loop:
  %p = getelementptr inbounds i8, ptr %a, i32 %i
  ...
  %inc = add i32 %i, 1                 ; inc = i + 1
  %exitcond = icmp ne i32 %inc, %endp1 ; exitcond = inc != endp1
  br i1 %exitcond, label %loop, label %exit.loopexit
```

Three things happened:
1. The exit test moved from the pre-incremented `%i` to the post-incremented `%inc`, against a new limit `end + 1` computed in the preheader;
2. `%endp1` was introduced, and its live range is the entire loop;
3. The `nsw`[^7] was dropped because the exit branch now compares `%inc`, and branching on poison would be UB the original program didn't have. So the flag goes unless SCEV can prove no wrap, which it can't: `%end` could be `INT_MAX`.

Number 3 is the crucial change. Before LFTR, with no users of `%inc` except the `phi`, keeping and propagating the `nsw` is "safe". This means a downstream run of SCEV can conclude something like `sext(%inc) == sext(%i + 1) == sext(%i) + 1` (because the equation holds iff addition doesn't overflow). Hence, something like loop-unrolled loads, where the load address `%p` is a fixed stride, can be optimized[^8]:

{% raw %}
```
%p   -->  {((sext i32 %start to i64) + %a),+,4}<nw><%loop>
%p.1 -->  {((sext i32 (1 + %start) to i64) + %a),+,4}<nw><%loop>
%p.2 -->  {((sext i32 (2 + %start) to i64) + %a),+,4}<nw><%loop>
%p.3 -->  {((sext i32 (3 + %start) to i64) + %a),+,4}<nw><%loop>
```
{% endraw %}

(`<nw>` is SCEV's "no self-wrap" flag; together with the `sext` folded into the recurrence, it means the four addresses advance in lockstep with constant offsets.)

# Weeds: Why SCEV gave up

SCEV doesn't model floating point at all: `%f` isn't an add recurrence, it's just an opaque `float` phi.
The only way SCEV ever got a trip count for this loop was brute force.
When the exit condition depends on phis whose values can be constant folded from one iteration to the next, `computeExitCountExhaustively` just simulates the loop, folding `%f.next = 0 + 1`, `1 + 1`, ... and the comparison, for a bounded number of iterations, until the exit condition would trigger (`%cmp` is false).

That was changed in [#90942](https://github.com/llvm/llvm-project/pull/90942) _intentionally_: if an operation can produce a different result at run time than the one the constant folder computes (because later passes are allowed to reassociate it, contract it into an FMA, replace a divide with a reciprocal multiply, ...), then a trip count computed by folding it at compile time isn't actually a fact about the program.
So constant folding got an `AllowNonDeterministic` flag, SCEV passes `false`, and with `false` FP binary operators carrying `nsz`, `reassoc`, `contract` or `arcp` don't fold (and neither do NaN results or FP libcalls). Since `-ffast-math` implies all four of those, `fadd fast` no longer folds and the trip count is no longer computed by SCEV.

# Resolution

The resolution was not a magical fix: I simply guarded against both LFTR and sinking in the `IndVarSimplify` pass itself (early exit before those transformations ran) and that sufficiently recovered performance without sacrificing (much) performance elsewhere. The compiler gods giveth and the compiler gods taketh 🤷.

# Footnotes

[^1]: E.g., on GPUs you typically unroll small loops to remove loop overhead (counter update, compare, branch, etc.) and expose independent work (like loads and stores which can be latency hidden) to the instruction scheduler.
[^2]: **SCEV**, which stands for [Scalar Evolution](https://www.npopov.com/2023/10/03/LLVM-Scalar-evolution.html), is an analysis which tries to statically infer properties of numeric values such as ranges. It does this by discovering arithmetic [recurrence relations](https://en.wikipedia.org/wiki/Recurrence_relation) and using their closed forms to compute quantities of interest (such as IV bounds). Here specifically what SCEV used to infer successfully was the loop trip count.
[^3]: Alternatively, why the [full employment theorem for compiler engineers](https://en.wikipedia.org/wiki/Full-employment_theorem) exists. Note: this is just my "2 cents". Naturally, there are lots of smart people working on compilers who probably think differently.
[^4]: How did I figure this out? It should come as no surprise in the year 2026 AD: Claude.
[^5]: They cannot be scheduled before the exit block because the LLVM scheduler only operates at basic block (BB) granularity (one BB at a time) and no later pass hoists the sunk code back above the loop.
[^6]: Recall, the trip count (for loop unrolling) was the whole purpose for using `IndVarSimplify`.
[^7]: `nsw` means "no signed wrap". It's a flag on integer add, sub, mul and shl in LLVM IR which "promises" that the operation, read as signed math, never overflows. If it does overflow anyway (e.g. `INT_MAX + 1`), the result is _poison_.
[^8]: The loop can be "strength reduced" (LSR) by turning the address math into plain pointer bumps (e.g., just adding 4 bytes each iteration). That is to say, without `nsw`, LSR can't transform `%a + sext(%i + k)` into strided pointers or constant offsets. Instead, it must compute `%i+1`, `%i+2`, `%i+3` and keep the 32-bit IV live, which adds extra index values per loop iteration (which contributes to register pressure).
