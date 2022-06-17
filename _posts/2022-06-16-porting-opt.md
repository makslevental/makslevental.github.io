---
layout: post
published: true
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: How to port a PyTorch model (OPT) to MLIR
---

I'm going to walk through how to port PyTorch model ([OPT](https://github.com/facebookresearch/metaseq/tree/main/projects/OPT)) to MLIR, starting from the :hug: [Hugging Face](https://huggingface.co/facebook/opt-350m) (HF) implementation.

<!--more-->

# The easy parts
## Step 1: MWE

Get a MWE with the right input (shape and dtype):

```python
from transformers import OPTModel, OPTConfig, GPT2Tokenizer

configuration = OPTConfig()
model = OPTModel(configuration)
model.eval() # freeze dropout and etc
tokenizer = GPT2Tokenizer.from_pretrained("facebook/opt-350m")

inputs = tokenizer("Hello, my dog is cute", return_tensors="pt")
input_ids, attention_mask = inputs.data["input_ids"], inputs.data["attention_mask"]
outputs = model(input_ids, attention_mask)
```

## Step 2: TorchScript

Get a TorchScript representation of the model; in this case you have to use `torch.jit.trace` because the model has way to much hijinks for `torch.jit.script` ([such as closures *defined in the forward* that call modules](https://github.com/huggingface/transformers/blob/39b4aba54d349f35e2f0bd4addbe21847d037e9e/src/transformers/models/opt/modeling_opt.py#L658)[^1]):

```python
configuration.return_dict = False # easier this way
...
ts = torch.jit.trace(model, (input_ids, attention_mask))
```

Immediately you get these scary warnings:

```
modeling_opt.py:513: TracerWarning: Converting a tensor to a Python boolean might cause the trace to be incorrect. We can't record the data flow of Python values, so this value will be treated as a constant in the future. This means that the trace might not generalize to other inputs!
  if input_shape[-1] > 1:
modeling_opt.py:64: TracerWarning: torch.tensor results are registered as constants in the trace. You can safely ignore this warning if you use this function to create tensors out of constant variables that would be the same every time you call this function. In any other case, this might cause the trace to be incorrect.
  mask = torch.full((tgt_len, tgt_len), torch.tensor(float("-inf")))
modeling_opt.py:203: TracerWarning: Converting a tensor to a Python boolean might cause the trace to be incorrect. We can't record the data flow of Python values, so this value will be treated as a constant in the future. This means that the trace might not generalize to other inputs!
  if attn_weights.size() != (bsz * self.num_heads, tgt_len, src_len):
modeling_opt.py:210: TracerWarning: Converting a tensor to a Python boolean might cause the trace to be incorrect. We can't record the data flow of Python values, so this value will be treated as a constant in the future. This means that the trace might not generalize to other inputs!
  if attention_mask.size() != (bsz, 1, tgt_len, src_len):
modeling_opt.py:242: TracerWarning: Converting a tensor to a Python boolean might cause the trace to be incorrect. We can't record the data flow of Python values, so this value will be treated as a constant in the future. This means that the trace might not generalize to other inputs!
  if attn_output.size() != (bsz * self.num_heads, tgt_len, self.head_dim):
```

Let's blissfully ignore those for now. From here on starts the deep deep pain...

# The hard parts

## Step 0: Try to compile

Blissfully unaware of what lies ahead, try to compile using `torch-mlir`'s APIs:

```python
module = torch_mlir.compile(
    model,
    (input_ids, attention_mask),
    output_type=torch_mlir.OutputType.LINALG_ON_TENSORS,
    use_tracing=True,
)
```

Note we're lowering to `lingalg`. This results in 

```python
Traceback (most recent call last):
  File "/home/mlevental/dev_projects/dSHARK/tank/pytorch/opt/from_Scratch.py", line 18, in <module>
    module = torch_mlir.compile(
  File "/home/mlevental/miniconda3/envs/dshark/lib/python3.9/site-packages/torch_mlir/__init__.py", line 149, in compile
    run_pipeline_with_repro_report(mb.module,
  File "/home/mlevental/miniconda3/envs/dshark/lib/python3.9/site-packages/torch_mlir/compiler_utils.py", line 53, in run_pipeline_with_repro_report
    raise Exception(f"""
Exception: 
Lowering TorchScript IR -> Torch Backend IR failed with the following diagnostics:
error: 'func.call' op operand type mismatch: expected operand type '!torch.float', but provided '!torch.number' for operand number 0
note: see current operation: %1025 = "func.call"(%130, %1021, %1022, %1023, %1024) {callee = @__torch_mlir_shape_fn.aten.arange} : (!torch.number, !torch.optional<int>, !torch.optional<int>, !torch.optional<Device>, !torch.optional<bool>) -> !torch.list<int>


Error can be reproduced with:
$ torch-mlir-opt -pass-pipeline='torchscript-module-to-torch-backend-pipeline' /tmp/OPTModel.mlir
Add '-print-ir-after-all -mlir-disable-threading' to get the IR dump for debugging purpose.
```

Well that's positively terrifying, and thus begins our "Dante's inferno" journey...

## Step 1: Surgery

So that exception is terrifying but at least there's a seemingly helpful suggestion. Assuming you have `torch-mlir` compiled, you can run the `torch-mlir-opt` command and get:

```
modeling_opt.py:65:0: error: 'func.call' op operand type mismatch: expected operand type '!torch.float', but provided '!torch.number' for operand number 0
modeling_opt.py:65:0: note: see current operation: %956 = "func.call"(%61, %952, %953, %954, %955) {callee = @__torch_mlir_shape_fn.aten.arange} : (!torch.number, !torch.optional<int>, !torch.optional<int>, !torch.optional<Device>, !torch.optional<bool>) -> !torch.list<int>

```

Okay I still have no idea what that means[^2] but again there's a helpful clue: `modeling_opt.py:65:0`. Let's see what's there:

```python
mask_cond = torch.arange(mask.size(-1))
```

Putting a breakpoint on that line what you see is that `mask.size(-1)` is a tensor[^4] while `torch.arange` expects integers. The fix is to wrap `mask.size(-1)` in `int`. So from here on out we're goin to be performing surgery on HF's implementation - the easiest way to do this cleanly is to fish out the `modeling_opt.py` file and change relevant paths; from

```python
from ...activations import ACT2FN
from ...modeling_outputs import BaseModelOutputWithPast, CausalLMOutputWithPast
from ...modeling_utils import PreTrainedModel
from ...utils import (
    add_code_sample_docstrings,
    add_start_docstrings,
    add_start_docstrings_to_model_forward,
    logging,
    replace_return_docstrings,
)
```

to

```python
from transformers import PreTrainedModel
from transformers.activations import ACT2FN
from transformers.modeling_outputs import BaseModelOutputWithPast, CausalLMOutputWithPast
```

Note that I forewent all of the `docstring` stuff.


## Step n+k: Keep trying to compile until (╯°□°)╯︵ ┻━┻ and then dig deeper

After patching that line, we try again and get

```python
Exception: 
Lowering TorchScript IR -> Torch Backend IR failed with the following diagnostics:
error: 'func.call' op operand type mismatch: expected operand type '!torch.float', but provided '!torch.number' for operand number 1
note: see current operation: %1023 = "func.call"(%126, %125, %1019, %1020, %1021, %1022) {callee = @__torch_mlir_shape_fn.aten.full} : (!torch.list<int>, !torch.number, !torch.optional<int>, !torch.optional<int>, !torch.optional<Device>, !torch.optional<bool>) -> !torch.list<int>
```

WTF isn't this the same exact error? Nope, looking more closely, it's about `torch.full`, which is exactly just above the previous line:

```python
mask = torch.full((tgt_len, tgt_len), torch.tensor(float("-inf")))
```

where evidently someone was trying to be a little too clever, because the actual call is

```python
mask = torch.full((tgt_len, tgt_len), float("-inf"))
```

Okay let's try again. This time we get:

```python
Exception: 
Lowering TorchScript IR -> Torch Backend IR failed with the following diagnostics:
error: failed to legalize operation 'torch.aten.to.dtype_layout' that was explicitly marked illegal
note: see current operation: %141 = "torch.aten.to.dtype_layout"(%140, %83, %101, %117, %96, %98, %98, %96) : (!torch.vtensor<[1,1,7,7],f32>, !torch.int, !torch.int, !torch.Device, !torch.none, !torch.bool, !torch.bool, !torch.none) -> !torch.vtensor<[1,1,7,7],f32>
```

Hmm this one is different. Using the handy `torch-mlir-opt` hint, we get sent to `modeling_opt.py:500`:

```python
combined_attention_mask = _make_causal_mask(
    input_shape, inputs_embeds.dtype, past_key_values_length=past_key_values_length
).to(inputs_embeds.device)
```

Ignoring the goofy condition[^3], this doesn't actually look right; the `torch-mlir` error mentions `dtype_layout` but this line is doing a `.to(inputs_embeds.device)`.
In this case the compiler is confused (location tracking specifically); the `aten.to.dtype_layout` call is actually in the same place as the other errors were, namely `_make_causal_mask`:

```python
def _make_causal_mask(input_ids_shape: torch.Size, dtype: torch.dtype, past_key_values_length: int = 0):
    """
    Make causal mask used for bi-directional self-attention.
    """
    bsz, tgt_len = input_ids_shape
    mask = torch.full((tgt_len, tgt_len), float("-inf"))
    mask_cond = torch.arange(int(mask.size(-1)))
    mask.masked_fill_(mask_cond < (mask_cond + 1).view(mask.size(-1), 1), 0)
    mask = mask.to(dtype) <--------------------

    if past_key_values_length > 0:
        mask = torch.cat([torch.zeros(tgt_len, past_key_values_length, dtype=dtype), mask], dim=-1)
    return mask[None, None, :, :].expand(bsz, 1, tgt_len, tgt_len + past_key_values_length)
```

I pasted the whole function because this thing is wonderful example ridiculous bend-over-backwards-abuse-duck-typing ML engineering, and we'll come back to it several more times.
The `dtype` for me, during all of the forward passes that I ran, is `torch.float32`. But the `dtype` of `mask` is also always `torch.float32` :shrug:.
Commenting out that line, and trying again we get:

```python
modeling_opt.py:500:0: error: failed to legalize operation 'torch.aten.to.dtype_layout' that was explicitly marked illegal
modeling_opt.py:500:0: note: see current operation: %72 = "torch.aten.to.dtype_layout"(%71, %14, %32, %48, %27, %29, %29, %27) : (!torch.vtensor<[1,1,7,7],f32>, !torch.int, !torch.int, !torch.Device, !torch.none, !torch.bool, !torch.bool, !torch.none) -> !torch.vtensor<[1,1,7,7],f32>
```

Well shit that really is the same error again[^5]. Commenting out `.to(inputs_embeds.device)` does fix/make progress (i.e. gives us a different error):

```python
error: unsupported byte, char or bool type for convertScalarToDtype 'f32'(scalar type) -> 'i1'(dtype)
error: failed to legalize operation 'torch.aten.to.dtype' that was explicitly marked illegal
note: see current operation: %641 = "torch.aten.to.dtype"(%640, %97, %112, %112, %110) : (!torch.vtensor<[1,1,7,7],f32>, !torch.int, !torch.bool, !torch.bool, !torch.none) -> !torch.vtensor<[1,1,7,7],i1>
```

which `torch-mlir-opt` tells is located at

```pythong
modeling_opt.py:134:0: error: failed to legalize operation 'torch.aten.view' that was explicitly marked illegal
modeling_opt.py:134:0: note: see current operation: %809 = "torch.aten.view"(%807, %808) : (!torch.tensor<[1,7,768],f32>, !torch.list<int>) -> !torch.tensor<[1,7,12,64],f32>
```

and where we find

```python
def _shape(self, tensor: torch.Tensor, seq_len: int, bsz: int):
    return tensor.view(bsz, seq_len, self.num_heads, self.head_dim).transpose(1, 2).contiguous()
```

Hmm I don't see any `dtype`s or anything. Putting a breakpoint there and very very patiently stepping we observe that sometimes `bsz` is a tensor.
Why? because it's read from `hidden_states.size()` in the caller (`OPTAttention.forward`). Again, I haven't figured out this mystery of why `.size()` returns tensors but the solution might be to cast in the caller:

```python
bsz, tgt_len, _ = map(int, hidden_states.size())
```

Trying again:

```python
Lowering Torch Backend IR -> Linalg-on-Tensors Backend IR failed with the following diagnostics:
error: unsupported byte, char or bool type for convertScalarToDtype 'f32'(scalar type) -> 'i1'(dtype)
error: failed to legalize operation 'torch.aten.to.dtype' that was explicitly marked illegal
note: see current operation: %630 = "torch.aten.to.dtype"(%629, %95, %110, %110, %108) : (!torch.vtensor<[1,1,7,7],f32>, !torch.int, !torch.bool, !torch.bool, !torch.none) -> !torch.vtensor<[1,1,7,7],i1>
```

Nope (╯°□°)╯︵ ┻━┻. At this point only thing to do is just eliminate all `.to`s; `_expand_mask` has two:

```python
def _expand_mask(mask: torch.Tensor, dtype: torch.dtype, tgt_len: Optional[int] = None):
    bsz, src_len = mask.size()
    tgt_len = tgt_len if tgt_len is not None else src_len

    # expanded_mask = mask[:, None, None, :].expand(bsz, 1, tgt_len, src_len).to(dtype)
    expanded_mask = mask[:, None, None, :].expand(bsz, 1, tgt_len, src_len)#.to(dtype)

    inverted_mask = 1.0 - expanded_mask

    # return inverted_mask.masked_fill(inverted_mask.to(torch.bool), torch.finfo(dtype).min)
    return inverted_mask.masked_fill(inverted_mask.to(torch.bool), torch.finfo(dtype).min
```

and one of those suspicious `.size()` calls. Commenting out the `.to`s gets you to a new circle of the inferno:

```
Process finished with exit code 139 (interrupted by signal 11: SIGSEGV)
```

Great.

# The harder parts

At this point we're gonna have to roll up our sleeves and dig into the implementation of `torch-mlir` so fire up your favorite IDE and I hope it has a debugger.
The first step is to get a representation we can feed to `torch-mlir-opt` just before this segfault.
Easiest way it to compile down to `torch` dialect and then do the lowering to `linalg` using `torch-mlir-opt`:

```python
module = torch_mlir.compile(
    model,
    (input_ids, attention_mask),
    output_type=torch_mlir.OutputType.TORCH,
    use_tracing=True,
)

asm_for_error_report = module.operation.get_asm(
    large_elements_limit=10, enable_debug_info=True)
open("opt.torch.mlir", "w").write(asm_for_error_report)
```

With `opt.torch.mlir` in hand, the args to pass to `torch-mlir-opt` are 

```
torch-mlir-opt -pass-pipeline="torch-backend-to-linalg-on-tensors-backend-pipeline" opt.torch.mlir -o opt.linalg.mlir
```

which gives us a nice[^6] stacktrace:

```
torch-mlir-opt: externals/llvm-project/llvm/../mlir/include/mlir/IR/Types.h:251: U mlir::Type::cast() const [U = mlir::RankedTensorType]: Assertion `isa<U>()' failed.
PLEASE submit a bug report to https://github.com/llvm/llvm-project/issues/ and include the crash backtrace.
Stack dump:
0.	Program arguments: cmake-build-debug/bin/torch-mlir-opt -pass-pipeline=torch-backend-to-linalg-on-tensors-backend-pipeline /home/mlevental/dev_projects/dSHARK/tank/pytorch/opt/opt.torch.mlir -o /home/mlevental/dev_projects/dSHARK/tank/pytorch/opt/opt.linalg.mlir
 #0  llvm::sys::PrintStackTrace(llvm::raw_ostream&, int) externals/llvm-project/llvm/lib/Support/Unix/Signals.inc:565:11
 #1  PrintStackTraceSignalHandler(void*) externals/llvm-project/llvm/lib/Support/Unix/Signals.inc:632:1
 #2  llvm::sys::RunSignalHandlers() externals/llvm-project/llvm/lib/Support/Signals.cpp:102:5
 #3  SignalHandler(int) externals/llvm-project/llvm/lib/Support/Unix/Signals.inc:407:1
 #4  __restore_rt (/lib/x86_64-linux-gnu/libpthread.so.0+0x14420)
 #5  raise /build/glibc-SzIz7B/glibc-2.31/signal/../sysdeps/unix/sysv/linux/raise.c:51:1
 #6  abort /build/glibc-SzIz7B/glibc-2.31/stdlib/abort.c:81:7
 #7  get_sysdep_segment_value /build/glibc-SzIz7B/glibc-2.31/intl/loadmsgcat.c:509:8
 #8  _nl_load_domain /build/glibc-SzIz7B/glibc-2.31/intl/loadmsgcat.c:970:34
 #9  (/lib/x86_64-linux-gnu/libc.so.6+0x33fd6)
#10  mlir::RankedTensorType mlir::Type::cast<mlir::RankedTensorType>() const externals/llvm-project/llvm/../mlir/include/mlir/IR/Types.h:0:3
#11  (anonymous namespace)::ConvertAtenViewOp::matchAndRewrite(mlir::torch::Torch::AtenViewOp, mlir::torch::Torch::AtenViewOpAdaptor, mlir::ConversionPatternRewriter&) const lib/Conversion/TorchToLinalg/DataMovement.cpp:103:38
#12  mlir::OpConversionPattern<mlir::torch::Torch::AtenViewOp>::matchAndRewrite(mlir::Operation*, llvm::ArrayRef<mlir::Value>, mlir::ConversionPatternRewriter&) const externals/llvm-project/llvm/../mlir/include/mlir/Transforms/DialectConversion.h:423:12
```

The source of the assert fails is `Types.h:251`:

```cpp
template <typename U> U Type::cast() const {
  assert(isa<U>());
  return U(impl);
}
```

and the explanation is that a cast to `mlir::RankedTensorType` failed. That cast occurred at `DataMovement.cpp:103:38`:

```cpp
class ConvertAtenViewOp : public OpConversionPattern<AtenViewOp> {
public:
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(AtenViewOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ...
    auto inputType = input.getType().cast<RankedTensorType>();
    ...
```

What this is saying is that the input to some `torch.aten.view` op couldn't be cast to `RankedTensorType`. Looking at `opt.torch.mlir`, we see instances of `torch.aten.view` that either look like

```llvm
%102 = torch.aten.view %99, %101 : !torch.vtensor<[7],si64>, !torch.list<int> -> !torch.vtensor<[7,1],si64> loc(#loc20)
```

or

```llvm
%132 = torch.aten.view %130, %131 : !torch.tensor<[1,7,768],f32>, !torch.list<int> -> !torch.tensor<[1,7,12,64],f32> loc(#loc13)
```

It turns out that `torch.vtensor` (value tensors) can be cast to `RankedTensorType` and  `torch.tensor` (non-value tensors) can't be (even though they both can be ranked and fully shape refined). Don't as me why.
Well why are there any non-value tensors hanging around anyway? Doesn't the `torch-backend-to-linalg-on-tensors-backend-pipeline` pass pipeline include the `torch-maximize-value-semantics` pass, which ostensibly converts all of these non-value tensors to value tensors (somehow)?
Turns out, for OPT, the `maximize-value-semantics` pass fails. The reason it fails is because, as of today, the `maximize-value-semantics` pass doesn't handle `torch.prim.TupleConstruct`, which operates on views or "view-like" ops; e.g., like in our `opt.torch.mlir`:

```llvm
...
%134 = torch.aten.contiguous %133, %int0 : !torch.tensor<[1,12,7,64],f32>, !torch.int -> !torch.tensor<[1,12,7,64],f32> loc(#loc13)
...
%151 = torch.aten.view %134, %150 : !torch.tensor<[1,12,7,64],f32>, !torch.list<int> -> !torch.tensor<[12,7,64],f32> loc(#loc28)
...
%852 = torch.prim.TupleConstruct %134, %139 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
```

and so the `%134 = torch.aten.contiguous` never gets "maximized" away and thus `torch.aten.view` gets passed a `torch.tensor`. In fact there are a lot of such `torch.prim.TupleConstruct` ops in `opt.torch.mlir`:

```llvm
    %852 = torch.prim.TupleConstruct %134, %139 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %853 = torch.prim.TupleConstruct %199, %204 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %854 = torch.prim.TupleConstruct %259, %264 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %855 = torch.prim.TupleConstruct %319, %324 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %856 = torch.prim.TupleConstruct %379, %384 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %857 = torch.prim.TupleConstruct %439, %444 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %858 = torch.prim.TupleConstruct %499, %504 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %859 = torch.prim.TupleConstruct %559, %564 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %860 = torch.prim.TupleConstruct %619, %624 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %861 = torch.prim.TupleConstruct %679, %684 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %862 = torch.prim.TupleConstruct %739, %744 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %863 = torch.prim.TupleConstruct %799, %804 : !torch.tensor<[1,12,7,64],f32>, !torch.tensor<[1,12,7,64],f32> -> !torch.tuple<tensor<[1,12,7,64],f32>, tensor<[1,12,7,64],f32>> loc(#loc0)
    %864 = torch.prim.TupleConstruct %852, %853, %854, %855, %856, %857, %858, %859, %860, %861, %862, %863 ....
    %865 = torch.prim.TupleConstruct %851, %864 
    %866 = torch.prim.TupleIndex %865, %int1 
    %867 = torch.copy.to_vtensor %851 : !torch.vtensor<[1,7,768],f32> loc(#loc0)
    return %867, %866 : !torch.vtensor<[1,7,768],f32>, !torch.tuple<tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>, tuple<tensor, tensor>> loc(#loc0)
```

What's going on here? I'll tell you what: clowntown. What's going on is HF's OPT implementation uses variable length tuples as a substitute for multiple similar (but related) architectures; so you have stuff like

```python
  if not self.do_layer_norm_before:
      hidden_states = self.final_layer_norm(hidden_states)

  outputs = (hidden_states,)

  if output_attentions:
      outputs += (self_attn_weights,)

  if use_cache:
      outputs += (present_key_value,)

  return outputs
```

and 

```python
      hidden_states = layer_outputs[0]
      if use_cache:
          next_decoder_cache += (layer_outputs[2 if output_attentions else 1],)

      if output_attentions:
          all_self_attns += (layer_outputs[1],)

  if self.project_out is not None:
      hidden_states = self.project_out(hidden_states)

  # add hidden states from the last decoder layer
  if output_hidden_states:
      all_hidden_states += (hidden_states,)

  next_cache = next_decoder_cache if use_cache else None
  if not return_dict:
      return tuple(v for v in [hidden_states, next_cache, all_hidden_states, all_self_attns] if v is not None)
```

and

```python
  output_attentions = output_attentions if output_attentions is not None else self.config.output_attentions
  output_hidden_states = (
      output_hidden_states if output_hidden_states is not None else self.config.output_hidden_states
  )
  return_dict = return_dict if return_dict is not None else self.config.use_return_dict

  # decoder outputs consists of (dec_features, layer_state, dec_hidden, dec_attn)
  outputs = self.model.decoder(
      ...
  )
  
  if not return_dict:
      output = (logits,) + outputs[1:]
      return (loss,) + output if loss is not None else output
```

What's the solution here? Medium-term, probably to take away people's keyboards :shrug: until they learn how to write better code.
Short-term the solution is to rewrite it yourself so that those branches are reflect in the structure of the model.

# Footnotes
  [^1]: Note I have no idea if this is reasonable in the context of transformer models (it might be, I'm not an AI thought leader, just a lowly compiler engineer).
  [^2]: Of course I actually do but at some point I didn't!
  [^3]: With respect to being able to extract a reasonable representation of this model...
  [^4]: This smells like a PyTorch bug, or at least unexpected behavior, but simultaneously I wouldn't be surprised if this is a recent change they made in order to support exactly this kind of goofy code (which queries for static features of the model rather than hardcoding) in a differentiable (or something like that) way.
  [^5]: This one I can't explain, i.e. why those two `.to`s are fused together (or something like that) by TorchScript.
  [^6]: I'm being sarcastic if you can't tell.