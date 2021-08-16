---
layout: post
published: true
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: PyTorch Tensor and Operator weedy details
---

This "brain dump" will consist of weedy implementation details about PyTorch that I picked up during my '21 summer internship. I'll describe what a PyTorch `Tensor` actually is (stride, `dtype`, and layout), what are "views", what a PyTorch operator is and how its executed, and how to create a new operator. Note that this post is mostly about the `C++` side of things.

# Prologue: Dispatch

The implementation of `Tensor`, and therefore much of operating on `Tensor`s, is closely coupled with the implementation of the PyTorch "dispatcher". The point of the dispatcher is that it factors the implementation of an operator into multiple *kernels*, each of which implements functionality for a specific *dispatch key*, e.g. different hardware platforms such as CPU and GPU but also "metaphorical" platforms such as [MetaTensor](https://github.com/pytorch/pytorch/blob/a421cba325bd816e8b6f40b8823533819124ab71/aten/src/ATen/native/MetaTensor.cpp). The reason this isn't straightforward is because `Tensors` come in all shapes and sizes (more on this in the forthcoming). The dispatcher determines what the highest priority dispatch key is at the time you call an operator (by considering the types of the tensor arguments as well as some thread local state), and delegates to the kernel for that dispatch key. The dispatcher aims, in principle, to reproduce the power of primitive (i.e., baked into a language) [Dynamic dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch) but in a way that's extensible (i.e., such that new dispatch targets can be added without wholesale recompilation). You can "observe" the dispatcher performing its magic by inspecting a stack trace; for example, `conv2d`

```cpp
  auto x = torch::arange(
      60, 
      torch::dtype(torch::kFloat).requires_grad(true)
    ).reshape({1, 3, 5, 4});
  auto weight = torch::arange(
      36, 
      torch::dtype(torch::kFloat).requires_grad(true)
    ).reshape({2, 3, 3, 2});
  auto y = torch::nn::functional::conv2d(x, weight);
```

produces this stack trace (breakpoint @ `ConvolutionMM2d.cpp:406`)

```
frame #0:  at::native::slow_conv2d_forward_out_cpu(...) at ConvolutionMM2d.cpp:406:43
frame #1:  at::native::slow_conv2d_forward_cpu(...) at ConvolutionMM2d.cpp:493:3
frame #2:  at::(...)::(...)::wrapper__thnn_conv2d_forward(...) at RegisterCPU.cpp:20725:10
frame #3:  c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) [inlined] c10::impl::detail::WrapFunctionIntoFunctor_<...>::operator(...)(...) at WrapFunctionIntoFunctor.h:13:16
frame #4:  c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) at make_boxed_from_unboxed_functor.h:423
frame #5:  std::__1::tuple<...> c10::callUnboxedKernelFunction<...>(...) at KernelFunction_impl.h:57:12
frame #6:  std::__1::tuple<...> c10::Dispatcher::redispatch<...>(...) const [inlined] std::__1::tuple<...> c10::KernelFunction::call<...>(...) const at KernelFunction_impl.h:67:16
frame #7:  std::__1::tuple<...> c10::Dispatcher::redispatch<...>(...)> const&, c10::DispatchKeySet, at::Tensor const&, at::Tensor const&, c10::ArrayRef<...>, c10::optional<...> const&, c10::ArrayRef<...>, c10::ArrayRef<...>) const at Dispatcher.h:536
frame #8:  at::_ops::thnn_conv2d_forward::redispatch(...) [inlined] c10::TypedOperatorHandle<...>::redispatch(...) const at Dispatcher.h:398:41
frame #9:  at::_ops::thnn_conv2d_forward::redispatch(...) at Operators.cpp:36409
frame #10: at::redispatch::thnn_conv2d_forward(...) at RedispatchFunctions.h:12169:16
frame #11: torch::autograd::VariableType::(...)::thnn_conv2d_forward(...)::$_127::operator(...)(...) const at VariableType_1.cpp:11025:12
frame #12: torch::autograd::VariableType::(...)::thnn_conv2d_forward(...) at VariableType_1.cpp:11023:15
frame #13: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) [inlined] c10::impl::detail::WrapFunctionIntoFunctor_<...>::operator(...)(...) at WrapFunctionIntoFunctor.h:13:16
frame #14: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) at make_boxed_from_unboxed_functor.h:440
frame #15: std::__1::tuple<...> c10::callUnboxedKernelFunction<...>(...) at KernelFunction_impl.h:57:12
frame #16: at::_ops::thnn_conv2d_forward::call(...) [inlined] std::__1::tuple<...> c10::KernelFunction::call<...>(...) const at KernelFunction_impl.h:67:16
frame #17: at::_ops::thnn_conv2d_forward::call(...) [inlined] std::__1::tuple<...> c10::Dispatcher::call<...>(...)> const&, at::Tensor const&, at::Tensor const&, c10::ArrayRef<...>, c10::optional<...> const&, c10::ArrayRef<...>, c10::ArrayRef<...>) const at Dispatcher.h:527
frame #18: at::_ops::thnn_conv2d_forward::call(...) [inlined] c10::TypedOperatorHandle<...>::call(...) const at Dispatcher.h:393
frame #19: at::_ops::thnn_conv2d_forward::call(...) at Operators.cpp:36401
frame #20: at::thnn_conv2d_forward(...) at Functions.h:11084:12
frame #21: at::native::thnn_conv2d(...) at ConvolutionMM2d.cpp:615:22
frame #22: at::(...)::(...)::wrapper__thnn_conv2d(...) at RegisterCompositeImplicitAutograd.cpp:7732:10
frame #23: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) [inlined] c10::impl::detail::WrapFunctionIntoFunctor_<...>::operator(...)(...) at WrapFunctionIntoFunctor.h:13:16
frame #24: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) at make_boxed_from_unboxed_functor.h:423
frame #25: at::Tensor c10::callUnboxedKernelFunction<...>(...) at KernelFunction_impl.h:57:12
frame #26: at::_ops::thnn_conv2d::call(...) [inlined] at::Tensor c10::KernelFunction::call<...>(...) const at KernelFunction_impl.h:67:16
frame #27: at::_ops::thnn_conv2d::call(...) [inlined] at::Tensor c10::Dispatcher::call<...>(...)> const&, at::Tensor const&, at::Tensor const&, c10::ArrayRef<...>, c10::optional<...> const&, c10::ArrayRef<...>, c10::ArrayRef<...>) const at Dispatcher.h:527
frame #28: at::_ops::thnn_conv2d::call(...) [inlined] c10::TypedOperatorHandle<...>::call(...) const at Dispatcher.h:393
frame #29: at::_ops::thnn_conv2d::call(...) at Operators.cpp:36363
frame #30: at::thnn_conv2d(...) at Functions.h:11069:12
frame #31: at::native::_convolution_nogroup(...) at Convolution.cpp:1058:18
frame #32: at::(...)::(...)::wrapper___convolution_nogroup(...) at RegisterCompositeImplicitAutograd.cpp:1528:10
frame #33: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) [inlined] c10::impl::detail::WrapFunctionIntoFunctor_<...>::operator(...)(...) at WrapFunctionIntoFunctor.h:13:16
frame #34: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) at make_boxed_from_unboxed_functor.h:423
frame #35: at::Tensor c10::callUnboxedKernelFunction<...>(...) at KernelFunction_impl.h:57:12
frame #36: at::_ops::_convolution_nogroup::call(...) [inlined] at::Tensor c10::KernelFunction::call<...>(...) const at KernelFunction_impl.h:67:16
frame #37: at::_ops::_convolution_nogroup::call(...) [inlined] at::Tensor c10::Dispatcher::call<...>(...)> const&, at::Tensor const&, at::Tensor const&, c10::optional<...> const&, c10::ArrayRef<...>, c10::ArrayRef<...>, c10::ArrayRef<...>, bool, c10::ArrayRef<...>) const at Dispatcher.h:527
frame #38: at::_ops::_convolution_nogroup::call(...) [inlined] c10::TypedOperatorHandle<...>::call(...) const at Dispatcher.h:393
frame #39: at::_ops::_convolution_nogroup::call(...) at Operators.cpp:4994
frame #40: at::_convolution_nogroup(...) at Functions.h:1514:12
frame #41: at::native::_convolution(...) at Convolution.cpp:968:16
frame #42: at::(...)::(...)::wrapper___convolution(...) at RegisterCompositeImplicitAutograd.cpp:1495:10
frame #43: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) [inlined] c10::impl::detail::WrapFunctionIntoFunctor_<...>::operator(...)(...) at WrapFunctionIntoFunctor.h:13:16
frame #44: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) at make_boxed_from_unboxed_functor.h:423
frame #45: at::Tensor c10::callUnboxedKernelFunction<...>(...) at KernelFunction_impl.h:57:12
frame #46: at::_ops::_convolution::call(...) [inlined] at::Tensor c10::KernelFunction::call<...>(...) const at KernelFunction_impl.h:67:16
frame #47: at::_ops::_convolution::call(...) [inlined] at::Tensor c10::Dispatcher::call<...>(...)> const&, at::Tensor const&, at::Tensor const&, c10::optional<...> const&, c10::ArrayRef<...>, c10::ArrayRef<...>, c10::ArrayRef<...>, bool, c10::ArrayRef<...>, long long, bool, bool, bool, bool) const at Dispatcher.h:527
frame #48: at::_ops::_convolution::call(...) [inlined] c10::TypedOperatorHandle<...>::call(...) const at Dispatcher.h:393
frame #49: at::_ops::_convolution::call(...) at Operators.cpp:4937
frame #50: at::_convolution(...) at Functions.h:1499:12
frame #51: at::native::convolution(...) at Convolution.cpp:754:10
frame #52: at::(...)::(...)::wrapper__convolution(...) at RegisterCompositeImplicitAutograd.cpp:1484:10
frame #53: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) [inlined] c10::impl::detail::WrapFunctionIntoFunctor_<...>::operator(...)(...) at WrapFunctionIntoFunctor.h:13:16
frame #54: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) at make_boxed_from_unboxed_functor.h:423
frame #55: at::Tensor c10::callUnboxedKernelFunction<...>(...) at KernelFunction_impl.h:57:12
frame #56: at::_ops::convolution::call(...) [inlined] at::Tensor c10::KernelFunction::call<...>(...) const at KernelFunction_impl.h:67:16
frame #57: at::_ops::convolution::call(...) [inlined] at::Tensor c10::Dispatcher::call<...>(...)> const&, at::Tensor const&, at::Tensor const&, c10::optional<...> const&, c10::ArrayRef<...>, c10::ArrayRef<...>, c10::ArrayRef<...>, bool, c10::ArrayRef<...>, long long) const at Dispatcher.h:527
frame #58: at::_ops::convolution::call(...) [inlined] c10::TypedOperatorHandle<...>::call(...) const at Dispatcher.h:393
frame #59: at::_ops::convolution::call(...) at Operators.cpp:4880
frame #60: at::convolution(...) at Functions.h:1484:12
frame #61: at::native::conv2d(...) at Convolution.cpp:586:10
frame #62: at::(...)::(...)::wrapper__conv2d(...) at RegisterCompositeImplicitAutograd.cpp:1561:10
frame #63: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) [inlined] c10::impl::detail::WrapFunctionIntoFunctor_<...>::operator(...)(...) at WrapFunctionIntoFunctor.h:13:16
frame #64: c10::impl::wrap_kernel_functor_unboxed_<...>::call(...) at make_boxed_from_unboxed_functor.h:423
frame #65: at::Tensor c10::callUnboxedKernelFunction<...>(...) at KernelFunction_impl.h:57:12
frame #66: at::_ops::conv2d::call(...) [inlined] at::Tensor c10::KernelFunction::call<...>(...) const at KernelFunction_impl.h:67:16
frame #67: at::_ops::conv2d::call(...) [inlined] at::Tensor c10::Dispatcher::call<...>(...)> const&, at::Tensor const&, at::Tensor const&, c10::optional<...> const&, c10::ArrayRef<...>, c10::ArrayRef<...>, c10::ArrayRef<...>, long long) const at Dispatcher.h:527
frame #68: at::_ops::conv2d::call(...) [inlined] c10::TypedOperatorHandle<...>::call(...) const at Dispatcher.h:393
frame #69: at::_ops::conv2d::call(...) at Operators.cpp:5051
frame #70: at::conv2d(...) at Functions.h:1529:12
frame #71: auto torch::nn::functional::detail::conv2d(...)::'lambda'(...)::operator(...)<...>(...) const at conv.h:85:14

...

frame #85: torch::nn::functional::detail::conv2d(...) at conv.h:84:10
frame #86: torch::nn::functional::conv2d(...) at conv.h:113:10
frame #87: main(...) at main_static_resnet.cpp:414:12
```

All of the calls to `c10::Dispatcher` (and various related helpers) are the signature methods (no pun intended) of the dispatcher. Note that the call and template arguments that deteremine dispatch that have been elided here; the [full, formatted stack trace is revealing](https://gist.github.com/makslevental/b2de2b5db22b1033c3b0f4951349a2b2).

# What is a Tensor?

## TensorImpl

# What are views?

# What is an operator?
## Execution (i.e., JIT)

# How to author an operator 

The first step is to decide whether your operator can defined as a composition of existing operators or wholecloth novel. This aspect of your operator determines whether you'll need to also author the corresponding backward function (i.e., the function that computes the gradients corresponding to a forward application of your operator). If it can be then your backward will be automatically "inferred" by the [autograd facilities](https://pytorch.org/docs/stable/notes/autograd.html). For the sake of this discussion let's assume you needed need to define a custom gradients function as well. In particular let's mock up an implementation of not-as-of-yet-real "time traveling" convolutions[^1].

The first step is to find a nice, cozy, warm spot your function declaration in [native_functions.yaml](https://github.com/pytorch/pytorch/blob/50fc8e8250adafb564e59dc90b39aca6d9b2cee9/aten/src/ATen/native/native_functions.yaml). This yaml file is the figurative entry point of the code generation performed by PyTorch's build system at compile time, i.e., these definitions are used to [generate](https://github.com/pytorch/pytorch/blob/a421cba325bd816e8b6f40b8823533819124ab71/tools/codegen/gen.py) the heaps and heaps of code that comprises the dispatcher. Since we're working on a new type of convolution we'll insert this declaration somewhere near the rest of the convolution declarations:

```yaml
- func: time_traveling_conv(Tensor self, Tensor weight, int[2] kernel_size, Tensor? bias=None, int[2] stride=1, int[2] padding=0, *, int[] time) -> Tensor
  python_module: nn
```

The complete description of the operator definition schema DSL (i.e., the `func:` part) is [here](https://github.com/pytorch/pytorch/blob/50fc8e8250adafb564e59dc90b39aca6d9b2cee9/aten/src/ATen/native/README.md#func) but I'll briefly go over the semantics present in this declaration.

* `Tensor? <ident>` declares an optional (`?`) `Tensor` input (naturally) which will be referred to by `ident` in the generated code
* `*` is the same as the python convention, indicating that the following arguments must be passed in by keyword
* `int[] <ident>=1` or `int[n] <ident>=1` declares a list like input (actually `ArrayRef<int64_t>`, defined [here](https://github.com/pytorch/pytorch/blob/master/c10/util/ArrayRef.h#L305)) with a default argument (`1`) in case of omission. The optional length specifier has the effect that arguments passed at the python layer are expanded to a list `n` times, e.g., like in the case of `kernel=3`, which correspond to `kernel=[3,3, ..., 3]` with the correct dimensions corresponding to the convolution.
* `-> Tensor` indicates the output type of the operator

The remainder of the keys (there are many [other possible such keys](https://github.com/pytorch/pytorch/blob/50fc8e8250adafb564e59dc90b39aca6d9b2cee9/aten/src/ATen/native/README.md#dispatch)) in the yaml dict give cues to code generation, e.g., `python_module: nn` means that python bindings for this operator will be generated under the `nn` namespace. We now need to provide an implementation of `time_traveling_conv` somewhere under [aten/src/ATen/native](https://github.com/pytorch/pytorch/tree/50fc8e8250adafb564e59dc90b39aca6d9b2cee9/aten/src/ATen/native). For example for our CPU implementation we could write this:

```cpp
Tensor time_traveling_conv(const Tensor & self, const Tensor & weight, IntArrayRef kernel_size, const c10::optional<Tensor>& bias_opt, IntArrayRef stride, IntArrayRef padding, IntArrayRef time) {
  c10::MaybeOwned<Tensor> bias_maybe_owned = at::borrow_from_optional_tensor(bias_opt);
  c10::MaybeOwned<Tensor> timeline_maybe_owned = at::borrow_from_optional_tensor(bias_opt);
  const Tensor& bias = *bias_maybe_owned;
  const Tensor& timeline = *timeline_maybe_owned;
  return std::get<0>(at::time_traveling_conv_forward(self, weight, kernel_size, bias, stride, padding));
}
```

A couple of things to note here:

* All parameters are reference parameters (either explicitly or implicitly, like `IntArrayRef`)
* Optional parameters are packaged as `c10::optional<type>`
* There's a tail call to `time_traveling_conv_forward`

The last point is the most critical: we employ dispatch again to encapsulate some of the logic of our actual implementation, namely that it should have multiple outputs (why will be addressed shortly). Thus we need another definition in `native_functions.yaml`:

```yaml
- func: time_traveling_conv_forward(Tensor self, Tensor weight, int[2] kernel_size, Tensor? bias, int[2] stride, int[2] padding, *, int[] time) -> (Tensor output, Tensor finput, Tensor fgrad_input)
  python_module: nn
  dispatch:
    CPU: time_traveling_conv_forward_cpu
    CUDA: time_traveling_conv_forward_gpu
```

where we introduce additional declarative structure. Particularly relevant are the `dispatch` keys: `CPU: time_traveling_conv_forward_cpu` indicates that, for tensors with `DeviceType::CPU`, the implementation that should run is `time_traveling_conv_forward_gpu` (similarly `CUDA: time_traveling_conv_cuda`). These two implementations we also need to provide and in principle they could dispatch again, themselves. In practice two or three dispatch iterations is sufficient to capture all of the specialization necessary (since two already implies at least $2^2=4$ different implementations). We'll leave `time_traveling_conv_forward_cpu` and `time_traveling_conv_forward_gpu` to your imagination.

Finally we come to defining derivatives for the novel operator. As we decided at the outset, `time_traveling_conv` requires a de novo function for computing its gradients, and thus we must follow a similar sort of process for [tools/autograd/derivatives.yaml](https://github.com/pytorch/pytorch/blob/a421cba325bd816e8b6f40b8823533819124ab71/tools/autograd/derivatives.yaml). For example

```yaml
- name: time_traveling_conv_forward(Tensor self, Tensor weight, int[2] kernel_size, Tensor? bias, int[2] stride, int[2] padding, int[] time) -> (Tensor output, Tensor finput, Tensor fgrad_input)
  self, weight, bias: "grad.defined() ? time_traveling_conv_backward(grad, self, weight, kernel_size, stride, padding, time, finput, fgrad_input, grad_input_mask) : std::tuple<Tensor, Tensor, Tensor>()"
```

Again, some things to note:

* We define the derivative of `time_traveling_conv_forward`rather than `time_traveling_conv`. This is because `time_traveling_conv_forward` returns `Tensor finput, Tensor fgrad_input` in addition to the desired convolution, which are cached by the runtime, and necessarily used in computing the gradients. Incidentally this is why `time_traveling_conv` tail calls to `time_traveling_conv_forward` in the first place.
* We define the gradients of three inputs of `time_traveling_conv_forward`, namely `self`, `weight`, and `bias`.
* We use a conditional that checks whether the `grad` of the output[^2] is defined. Since this can be undefined[^3] we optimize this case by returning `std::tuple<Tensor, Tensor, Tensor>()` immediately rather than performing the requisite checks in `time_traveling_conv_backward`.

And that's all there is to it. Having provided the necessary implementations, you can build from source and all of the python and C++ dispatch code will be generated for you. Note that if you created some new `.cpp` files you will need to add them to [tools/build_variables.bzl](https://github.com/pytorch/pytorch/blob/a421cba325bd816e8b6f40b8823533819124ab71/tools/build_variables.bzl) so that the build system picks them up.

# Footnotes

[^1]: If anyone *does* actually dream up such a convolution I expect at least an acknowledgement.
[^2]: The gradients passed in from some subsequent operator applied the output of our operator during the forward pass.
[^3]: Can someone say vanishing gradients?
