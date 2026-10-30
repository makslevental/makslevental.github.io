---
layout: post
published: false
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: PyTorch Memory Planning
tags: [pytorch, compilers]
---

This is the first of two posts which will cover my work on memory planning for PyTorch: this part will cover finishing touches to static memory planning (i.e., that which can be done by only looking at the graph IR), while the next will cover what I'm calling memory planning by memorization (i.e., that which can be done by performing an initial "profiling" pass to capture tensor allocations and frees).

**TL;DR**

* Static memory planning is ready for beta testing.
* Heuristic strategies for static memory planning generally achieve optimal memory usage, differing only on internal fragmentation.
* Static memory planning misses most allocations.

<!--more-->

# Background

I've been working on memory planning for PyTorch since the beginning of my internship (see [first half note](https://fb.workplace.com/notes/4191620827598919)). 
The goal is to anticipate all (or as many as possible) allocations for intermediate/temporary tensors and "plan" for them.
Intermediate or temporary tensors are tensors that are neither inputs nor outputs to a `Block`. 
To plan here means that an appropriately sized swath of memory (with size `total_size` bytes) is allocated once (e.g., prior to an inference pass) 

```cpp
// malloc, jemalloc, or posix_memalign etc.
void* buffer = malloc(total_size);
auto storage = c10::Storage(
    c10::Storage::use_byte_size_t(),
    total_size,
    std::move(buffer),
    /*allocator=*/nullptr,
    /*resizable=*/false
);
```

and from then on indexed into "by hand" for each subsequent (and statically identified) temporary tensor:

```cpp
// size, sizes, strides, device_type, dtype determined for each tensor
uint8_t* start = static_cast<uint8_t*>(storage.data());
void* src = static_cast<void*>(start + offset);
auto tensor = at::from_blob(
    src, sizes, strides, 
    at::TensorOptions(device_type).dtype(dtype)
);
tensor.storage().set_nbytes(size);
```

The point of such planning is to save on CPU time spent holding locks for large allocations (see [D26771348](https://www.internalfb.com/diff/D26771348)).
Note that this similar to [Slab allocation](https://en.wikipedia.org/wiki/Slab_allocation) but differs in that (at least currently) we only allocate a single slab (rather than several specialized to different e.g. tensor shapes).

Given this planning approach to allocating memory, there are four (maybe 3.5) challenges:

1. Finding the `sizes`, `strides`, and `dtype` for each intermediate tensor in order to compute how much memory each will require, i.e. `size`.
2. Finding the lifetimes of all intermediate tensors, where lifetime means first and last `pc` (or some proxy thereof) values, between which the tensor is (potentially) used by some operator.
3. Finding the `total_size` and `offset`s such that no two tensors, whose lifetimes overlap, either overwrite each other or buffer overflow.
4. Finding the *optimal* `total_size` and `offset`s such that the "high-water mark" of memory used does not exceed that of eager mode allocation, where "high-water mark" means the most allocated at any time by eager mode; since we will reserve that much memory for the duration of the inference pass, we should at least not exceed the requirements on memory imposed by eager mode.

# Implementation

The implementation consists implementations of various strategies that compute the `offset`s and `size`s and the introduction of two new primitive operators:

1. `prim::AllocateSlab`, which makes the initial large, single slab allocation and outputs a "reusable" tensor `IValue::Storage` wrapping that slab.
  1. For example `prim::AllocateSlab[total_size=1344, device_type=0]()`
2. `prim::AllocateTensor`, corresponding to a temporary tensor that will be used by an operator. It takes the slab created by `prim::AllocateStorage` as input and the `offset` and `size` and `profiled_type` of the temporary tensor as attributes and uses `at::from_blob` to create a "slice" of the slab. It outputs that slice, which is then passed to the operator (through the `out` parameter of its out variant). Note that this necessitates the operator *having* an out variant *and* type information for the outputs (currently being collected using the shape analysis passes).
  1. For example `prim::AllocateTensor[profiled_type=Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu), size=448, offset=0](%4)`.
3. `prim::ReleaseSlab`, which frees the slab and the contexts for temporary tensors.

The graph pass that inserts these operators transform looks something like this:

```llvm
graph(%0 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu),
      %1 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu),
      %2 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu),
      %3 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu)):
  %4 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu) = aten::mm(%0, %1)
  %5 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu) = aten::mm(%2, %3)
  %6 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu) = aten::mm(%4, %5)
  %7 : int = prim::Constant[value=1]()
  %8 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu) = aten::add(%5, %6, %7)
  return (%8)
```

to this

```llvm
graph(%0 : Tensor,
      %1 : Tensor,
      %2 : Tensor,
      %3 : Tensor):
  %4 : Storage = prim::AllocateSlab[total_size=1344, device_type=0]()
  %5 : Tensor = prim::AllocateTensor[profiled_type=Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu), size=448, offset=0](%4)
  %6 : Tensor = aten::mm(%0, %1, %5)
  %7 : Tensor = prim::AllocateTensor[profiled_type=Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu), size=448, offset=448](%4)
  %8 : Tensor = aten::mm(%2, %3, %7)
  %9 : Tensor = prim::AllocateTensor[profiled_type=Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu), size=448, offset=896](%4)
  %10 : Tensor = aten::mm(%6, %8, %9)
  %11 : int = prim::Constant[value=1]()
  %12 : Tensor = aten::add(%8, %10, %11)
   = prim::ReleaseSlab(%4, %5, %7, %9)
  return (%12)
```

where I've erased shape information on the outputs of the operators for which we're managed memory to make the presentation clearer.

# Greedy Strategies for Memory Planning

As covered in [first note](https://fb.workplace.com/notes/4191620827598919), the challenges associated with memory planning can be formulated precisely as a Mixed Integer Problem (MIP) and thus solved analytically.
The second half of my internship has been occupied by implementing and experimenting with heuristic solutions; I've implemented and benchmarked on toy models (i.e., torchhub) roughly three strategies (with derivations therein):

1. **Linear Scan**: This is basically the classical [register allocation algorithm](http://web.cs.ucla.edu/~palsberg/course/cs132/linearscan.pdf) but adapted to the context of tensor allocation. The key heuristic in the classical algorithm is that registers should be "spilled" (e.g., to ram) according to latest ending lifetimes. That is to say, on allocating a register for some variable `var_x`, if al registers have already been allocated and if there exists a register allocated for a variable `var_y` whose lifetime ends after the lifetime of `var_x`, then that register should be reassigned to `var_x` and `var_y` should be spilled. The adaptation to the tensor allocation context is to treat the slab as the register file and spill tensors with late end times by incrementing `total_size` (when planning). There are some other heuristics used to reduce fragmentation but this latest lifetime endpoint heuristic is the key distinguishing feature of linear scan.
2. **Greedy by Size**: This heuristic (and the next) comes from a [paper](https://arxiv.org/pdf/2001.03288.pdf) from the TF team that explored many of the same challenges and solutions. The heuristic entails allocating tensors in reverse order of their size. The largest tensor gets `offset = 0` and subsequent tensors get offsets determined by lifetime intersection and a "small gap" heuristic: if a tensor can be allocated in between two other tensors, whose lifetimes it intersects with, it should be allocated such that the gap between these two adjacent tensors is least. The point of this further heuristic is to reduce fragmentation. 
3. **Greedy by Breadth (of operator)**: Intuitively we expect large tensors to be used by some subset of operators concurrently and in close "temporal" proximity of each other. For example, a convolution layer with a large convolution kernel will take a large input and produce a large output. Thus, we might satisfy a large number of lifetime and size constraints by allocating for tensors associated with such operators, i.e. those with high *breadth* (the sum of all sizes of all inputs and outputs of the operator). Hence, the greedy by breadth heuristic involves sorting all operators in reverse order according to breadth and allocating input and output tensors per operator. Amongst input and output tensors of a given operator we allocate just as in greedy by size (in reverse order of their size, along with the smallest gap heuristic).

Greedy by size employs two heuristics, namely sorting in reverse order by size and taking the tightest fit for non-intersecting tensors. 
We can amend each of these heuristics easily to produce many more derivative (and hopefully self-explanatory) strategies: **Greedy by Size with First Gap**, **Greedy by Longest Lifetime and Size with First Gap**, **Greedy by Longest Lifetime and Size with Smallest Gap**. 
A similar exercise is possible for Greedy by Breadth but since the crucial heuristic there is sorting by operator breadth it likely wouldn't matter and so we omit such implementations.

# Results

Recall that the naive strategy is the one where we simply "stack" all tensors and compute offsets according to where the tensors appear in the stack.
The naive strategy can be thought of as a baseline but it's a rather poor one at that (more on this later).

First up we have a comparison of memory usage across all strategies

<!-- <img src="/images/memory_planning/memory_usage_for_strats_and_models_for_static_plans.svg" type="image/svg+xml"> -->
<img src="/images/memory_planning/memory_usage_for_strats_and_models_for_static_plans.svg">

The obvious thing to note is that all of the strategies perform almost exactly the same in terms of memory usage, achieving optimal usage as indicated by parity with the MIP solution.
The prompts the question: along what dimensions do the greedy strategies differ? The answer is that they differ with respect to the fragmentation of `total_size` initially allocated region.
Take for example BERT; compare 

Greedy by Size (with smallest gap)

<img src="/images/memory_planning/bert_static_greedy_by_size_with_smallest_gap.svg" type="image/svg+xml">

vs. Greedy by Breadth

<img src="/images/memory_planning/bert_static_greedy_by_breadth.svg" type="image/svg+xml">

Note that the color coding here represents **the order in which the heuristic decides the allocation**.

<img src="/images/memory_planning/colorscale.svg" type="image/svg+xml">

Putting aside the "cubist" nature of these representations, we can see that, in some sense, Greedy by Size with Smallest Gap fragments the allocation slightly less so than Greedy by Breadth.
In particular notice Greedy by Breadth seemingly places these small allocations farther from offset 0 than necessary




<div class="image123">
    <div class="imgContainer" style="display:inline-block;">
        <img src="/images/memory_planning/bert_greedy_by_breadth_fragment.png" height=700>
        <p>Greedy by Breadth</p>
    </div>
    &nbsp;&nbsp;&nbsp;
    <div class="imgContainer" style="display:inline-block;">
        <img src="/images/memory_planning/bert_greedy_by_size_fragment.png" height=700>
        <p>Greedy by Size (with smallest gap)</p>
    </div>
</div>

On the other hand Greedy by Size (with smallest gap) fails in other ways; in particular since it chooses the smallest gap rather than first, it also fragments dual to Greedy by Breadth

<div class="image123">
    <div class="imgContainer" style="display:inline-block;">
        <img src="/images/memory_planning/bert_greedy_by_breadth_fragment_2.png" height=700>
        <p>Greedy by Breadth</p>
    </div>
    &nbsp;&nbsp;&nbsp;
    <div class="imgContainer" style="display:inline-block;">
        <img src="/images/memory_planning/bert_greedy_by_size_fragment_2.png" height=700>
        <p>Greedy by Size (with smallest gap)</p>
    </div>
</div>




This kind of fragmentation is internal fragmentation since we hold the entire slab for the duration of the forward pass. 
We tolerate such fragmentation as a cost (wrt the cost/benefit analysis) of memory planning (relative to eager allocation) but we could easily strike a balance: consider the envelope of "memory envelope" of the Greedy by Breadth:

<img src="/images/memory_planning/resnet18_static_greedy_by_breadth_with_envelope.svg" type="image/svg+xml">
<p>resnet18_static_greedy_by_breadth_with_envelope</p>

By making a few strategic (no pun intended) frees we could release memory back to the system at no operational cost to us:

<img src="/images/memory_planning/resnet18_static_greedy_by_breadth_with_shading.svg" type="image/svg+xml">
<p>resnet18_static_greedy_by_breadth_with_shading</p>

Interestingly enough the MIP solution has the worst fragmentation of all strategies: 

<img src="/images/memory_planning/resnet18_solve_mip.svg" type="image/svg+xml">

where I've used a monochrome color scale since I don't know the order in which MIP solver decides the allocations.

If we consider the formulation from the [first note](https://fb.workplace.com/notes/4191620827598919), then this makes a lot of intuitive sense: the MIP only cares about minimizing `total_size`. 
Once that minimum is attained with all intersection constraints satisfied, the MIP finishes without any consideration for internal fragmentation.
A simple adjustment to the objective such as 

<!-- $$
\min\mathtt{total\_size} + \sum_i \mathtt{offset}_i
$$ -->
$$
\begin{align}
\mathtt{total\_size} &:= \max\left(\mathtt{offset}_i\right)\\
\min &\; \mathtt{total\_size} \\
\end{align}
$$

suffices to further encourage the MIP solver to minimize internal fragmentation

<img src="/images/memory_planning/resnet18_solve_cp.svg" type="image/svg+xml">

Clearly such a solution differs nominally (if at all) from any of the heuristic solutions (and now takes much longer to compute).

One final note on seeming "corner cases" such as

<img src="/images/memory_planning/corner_cases.png">

This is not erroneous but due to tensors that intersect at one op such as:

```
%5 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu) = aten::mm(%2, %3)
%6 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu) = aten::mm(%4, %5)
%7 : int = prim::Constant[value=1]()
%8 : Float(10, 10, strides=[10, 1], requires_grad=0, device=cpu) = aten::add(%5, %6, %7)
```

from the above graph, where `%5` and `%6` up until `%8` is created.
If you're saying to yourself that this is due to the abstract nature of the graph and that in fact those tensors potentially can be decoupled (i.e., their lifetimes don't actually intersect when you could look at the implementation of `aten::add`) you're almost right (since indeed `%8 = %5+%7*%6` actually does imply intersecting lifetimes) but definitely on the right track (see the epilogue).


# Conclusion

Static memory planning is ready for use (modulo a few small tweaks).
The results are good and there's room to grow the current implementation according to various needs (such as internal fragmentation).

# Epilogue

You might be thinking to yourself that the naive allocation strategy is a poor baseline.
You are right.
How well do these allocation strategies relative to eager memory allocation?
Very poorly but not for lack of trying; in fact planning only the memory allocations that are visible in the graph misses large portions of allocated memory and large fractions of the total number of allocations.

<img src="/images/memory_planning/rel_mem_usage.svg" type="image/svg+xml">

The reason this happens is there are plenty of tensors that are allocated and free within the scope of one op; for example `bmm_out_sparse_cuda` (just a random op I found that does this...):

```cpp
  if (result.is_contiguous()) {
    tmp_result = result;
    need_copy_result = false;
  } else {
    tmp_result = at::empty(
      {num_matrices, dim_k, dim_i}, 
      result.options(), 
      at::MemoryFormat::Contiguous
    );
    need_copy_result = true;
  }

  ...

  if (need_copy_result) {
    result.copy_(tmp_result);
  }
```

where `tmp_result` is obviously freed when `bmm_out_sparse_cuda` returns.

```llvm
  %9 : Float(1, 64, strides=[256, 1], requires_grad=0, device=cpu), 
  %10 : Float(1, 64, strides=[256, 1], requires_grad=0, device=cpu), 
  %11 : Float(1, 64, strides=[256, 1], requires_grad=0, device=cpu), 
  %12 : Float(1, 64, strides=[256, 1], requires_grad=0, device=cpu) = prim::ConstantChunk[chunks=4, dim=1](%8)
```

<img src="/images/memory_planning/resnet18_static_naive.svg" type="image/svg+xml">