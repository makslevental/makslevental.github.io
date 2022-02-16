---
layout: post
published: true
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: torch.nn.Conv2d on FPGA through MLIR and Xilinx Vitis HLS
---

Welcome to my oddysey in trying go from high-level (PyTorch) to low-level (FPGA). Grab a cup of coffee because this is going to take a while...

# TL;DR

If you want to deploy PyTorch (at least a `Conv2d` layer) to FPGA you can do it by torturing yourself and Vitis HLS:

![Untitled](/images/torch_mlir_fpga/Untitled.png)

<!--more-->

If you just want to see code, it’s mostly [here](https://github.com/makslevental/torch-mlir/tree/hls/hls).

# PyTorch

We start with an innocuous PyTorch layer:

```python
import torch

conv = torch.nn.Conv2d(
  in_channels=1, out_channels=1, kernel_size=3, stride=1, padding=0
)

# not strictly necessary but makes things easier
for m in conv.modules():
	torch.nn.init.constant_(m.weight, 1.0)
	torch.nn.init.constant_(m.bias, 1.0)

# dtype is important/necessary
input = torch.arange(0, 64, dtype=torch.float32).reshape((1, 1, 8, 8))
print(input)
>>> tensor([[[[ 0.,  1.,  2.,  3.,  4.,  5.,  6.,  7.],
          [ 8.,  9., 10., 11., 12., 13., 14., 15.],
          [16., 17., 18., 19., 20., 21., 22., 23.],
          [24., 25., 26., 27., 28., 29., 30., 31.],
          [32., 33., 34., 35., 36., 37., 38., 39.],
          [40., 41., 42., 43., 44., 45., 46., 47.],
          [48., 49., 50., 51., 52., 53., 54., 55.],
          [56., 57., 58., 59., 60., 61., 62., 63.]]]])

output = conv(input)
print(output)
tensor([[[[ 82.,  91., 100., 109., 118., 127.],
          [154., 163., 172., 181., 190., 199.],
          [226., 235., 244., 253., 262., 271.],
          [298., 307., 316., 325., 334., 343.],
          [370., 379., 388., 397., 406., 415.],
          [442., 451., 460., 469., 478., 487.]]]])
```

Standard stuff

# Torch-MLIR to Affine

We’re going to use the Torch-MLIR project to lower PyTorch (part of the way) to LLVM; in particular my [hls branch](https://github.com/makslevental/torch-mlir/tree/hls/). Note that I’m not being too diligent about pinning dependencies so you might stumble upon this post in sometime and try to reproduce and fail - sorry!

The first step is to build version our `conv` that Torch-MLIR can consume:

```python
from torch_mlir.dialects.torch.importer.jit_ir import ModuleBuilder, ClassAnnotator

# i have no idea why but if you don't import this then linalg passes aren't registered
from torch_mlir_e2e_test.linalg_on_tensors_backends.refbackend import RefBackendInvoker

def make_layer(test_module, annotations):
    class_annotator = ClassAnnotator()
    recursivescriptmodule = torch.jit.script(test_module)
    class_annotator.exportNone(recursivescriptmodule._c._type())
    class_annotator.exportPath(recursivescriptmodule._c._type(), ["forward"])
    class_annotator.annotateArgs(
        recursivescriptmodule._c._type(), ["forward"], annotations
    )
    
    return recursivescriptmodule._c, class_annotator

layer = make_layer(
    conv,
    [
        None,
        ([1, 1, 8, 8], torch.float32, True),
    ],
)
mb = ModuleBuilder()
mb.import_module(*layer)
```

All of this annotation is necessary so that tensors (and eventually `memref`s are fully refined, i.e., have fully concrete shapes). Then we run through a sequence of lowering passes using Torch-MLIR’s infrastructure:

```python
PIPELINE = TORCH_PIPELINE + TO_LINALG_PIPELINE + BUFFERIZATION_PIPELINE + LOWERING_PIPELINE

with mb.module.context:
        mb.set_multithreading(False)
        pm = PassManager.parse(",".join(PIPELINE))
        pm.run(mb.module)

    asm_for_error_report = mb.module.operation.get_asm(
        large_elements_limit=100000, enable_debug_info=False
		)
    open("conv.affine.mlir", "w").write(asm_for_error_report)
```

where the pipeline definitions can be found [here](https://github.com/makslevental/torch-mlir/blob/d183103de64036674e8d30cb696e83edd086394e/hls/python/poc.py#L78-L150). Note that some of those passes are my own concoctions (e.g., `torch-hls-linalg-bufferize` and `torch-hls-drop-public-return`) so you’re going to need to either cherry-pick or build my fork of Torch-MLIR.

We only use Torch-MLIR to lower PyTorch to affine; the result is something like this:

```python
module attributes {torch.debug_module_name = "Conv2d"}  {
  memref.global "private" constant @__constant_1xf32 : memref<1xf32> = dense<1.000000e+00>
  memref.global "private" constant @__constant_1x1x3x3xf32 : memref<1x1x3x3xf32> = dense<1.000000e+00>
  func @forward(%arg0: memref<1x1x8x8xf32>, %arg1: memref<1x1x6x6xf32>) {
    %true = arith.constant true
    %c1 = arith.constant 1 : index
    %c6 = arith.constant 6 : index
    %c0 = arith.constant 0 : index
    %c3 = arith.constant 3 : index
    %0 = memref.get_global @__constant_1x1x3x3xf32 : memref<1x1x3x3xf32>
    %1 = memref.get_global @__constant_1xf32 : memref<1xf32>
    assert %true, "expect groups to be 1"
    scf.for %arg2 = %c0 to %c1 step %c1 {
      scf.for %arg3 = %c0 to %c1 step %c1 {
        scf.for %arg4 = %c0 to %c6 step %c1 {
          scf.for %arg5 = %c0 to %c6 step %c1 {
            %2 = memref.load %1[%arg3] : memref<1xf32>
            memref.store %2, %arg1[%arg2, %arg3, %arg4, %arg5] : memref<1x1x6x6xf32>
          }
        }
      }
    }
    scf.for %arg2 = %c0 to %c1 step %c1 {
      scf.for %arg3 = %c0 to %c1 step %c1 {
        scf.for %arg4 = %c0 to %c6 step %c1 {
          scf.for %arg5 = %c0 to %c6 step %c1 {
            scf.for %arg6 = %c0 to %c1 step %c1 {
              scf.for %arg7 = %c0 to %c3 step %c1 {
                scf.for %arg8 = %c0 to %c3 step %c1 {
                  %2 = arith.addi %arg4, %arg7 : index
                  %3 = arith.addi %arg5, %arg8 : index
                  %4 = memref.load %arg0[%arg2, %arg6, %2, %3] : memref<1x1x8x8xf32>
                  %5 = memref.load %0[%arg3, %arg6, %arg7, %arg8] : memref<1x1x3x3xf32>
                  %6 = memref.load %arg1[%arg2, %arg3, %arg4, %arg5] : memref<1x1x6x6xf32>
                  %7 = arith.mulf %4, %5 : f32
                  %8 = arith.addf %6, %7 : f32
                  memref.store %8, %arg1[%arg2, %arg3, %arg4, %arg5] : memref<1x1x6x6xf32>
                }
              }
            }
          }
        }
      }
    }
    return
  }
}
```

# Affine to LLVM IR through phism

The rest of the lowering we’ll do outside of the context of Torch-MLIR. First step is using just `mlir-opt` to produce llvm dialect:

```bash
mlir-opt \
	-lower-affine \
	-convert-scf-to-std \
	-convert-memref-to-llvm \
	-convert-arith-to-llvm \
	-convert-std-to-llvm='use-bare-ptr-memref-call-conv=1' \
	-reconcile-unrealized-casts \
   < conv.affine.mlir \
	 > conv.llvm.mlir
```

and then `mlir-translate` to get actual LLVM IR:

```bash
mlir-translate \
	-mlir-to-llvmir \
	< conv.llvm.mlir \
  > conv.ll
```

Finally, the last step before FPGA land, is to massage the LLVM IR into a form that Xilinx’s Vitis HLS can consume; for this we use the LLVM passes from [phism](https://github.com/kumasento/phism/). In particular, the passes in [MemRefToArray.cc](https://github.com/kumasento/phism/blob/8ba299fe18ec963a9569077c9a83d0c662c2370f/lib/llvm/Transforms/MemRefToArray.cc) and [VhlsLLVMRewriter.cc](https://github.com/kumasento/phism/blob/8ba299fe18ec963a9569077c9a83d0c662c2370f/lib/llvm/Transforms/VhlsLLVMRewriter.cc):

```bash
opt conv.ll \
  -S \
  -enable-new-pm=0 \
  -load "VhlsLLVMRewriter.so" \
  -mem2arr \
  -strip-debug \
  -instcombine \
  -xlnmath \
  -xlnname \
  -strip-attr \
  -xlnunroll \
  -xlnarraypartition \
  > conv.opt.vitis.ll
```

Two things to note: 

- We don’t use `-xlnanno -xlntop=forward` or whatever (more on this later)
- we use `-mem2arr`; this is crucial for getting kernel interfaces compatible with AXI Streaming

Finally we have something we can feed Vitis HLS (looks like [this](https://github.com/makslevental/torch-mlir/blob/d183103de64036674e8d30cb696e83edd086394e/hls/scripts/braggnn.opt.vitis.ll)). Now comes the painful part.

# Synthesizing using Vitis HLS

Vitis some time ago opened up an LLVM IR API ([news here](https://www.xilinx.com/about/blogs/ai-and-machine-learning-blog/2021/vitis-hls-front-end-now-open-source.html), [repo here](https://github.com/Xilinx/hls-llvm-project/)). Along with this open sourcing, they exposed hooks for hooking up your own `opt`.  That means you can feed Vitis HLS LLVM IR instead of C/C++:

```bash
set ::LLVM_CUSTOM_CMD {$LLVM_CUSTOM_OPT conv.opt.vitis.ll -o $LLVM_CUSTOM_OUTPUT}
```

Note this isn’t the hook itself - the hook calls this command. The hook itself is in `/common/scripts/hls_hooks.tcl` (more on this soon).

An example `run_hls.tcl` script looks like this:

```bash
open_project -reset proj
add_files dummy.cpp
set_top wrapper

open_solution -reset solution1
set_part "xc7a200tfbg484-3"
create_clock -period "100MHz"
config_export -format ip_catalog -rtl verilog

set ::LLVM_CUSTOM_CMD {$LLVM_CUSTOM_OPT conv.opt.vitis.ll -o $LLVM_CUSTOM_OUTPUT}

csynth_design
```

where `dummy.cpp` is 

```cpp
void forward() {}
```

just to make Vitis happy during the first parts of the synthesis process. `forward` here corresponds to your top level function **but recall we’re setting** `conv.forward` **** **as our top level**. I’ll get to that in a second.

This all works fine if you want to just run synthesis experiments (resources usage/area/wattage/latency etc.). But if you want to actually talk to this logic **this won’t be sufficient**.

# An AXI wrapper around your kernel

The simplest way that I’ve discovered to talk to kernels/logic/blobs of gates is using the AXI Stream interface (see [my](https://makslevental.github.io/Hello-World-DMA/) [other](https://makslevental.github.io/IO-to-FPGAs/) [posts](https://makslevental.github.io/Matmul-on-FPGA-PCIE/)). If you’re working with plain Vitis HLS, then pragmas such as 

```cpp
#pragma HLS INTERFACE axis port = in
#pragma HLS INTERFACE axis port = out
```

and template types such as `hls::stream<axis_t>` are really convenient for this. Since we’re not using Vitis, we don’t easily have them at our disposal (by default, Vitis will synthesize a BRAM interface for array arguments; ctrl+f `ap_memory` [here](https://docs.xilinx.com/r/en-US/ug1399-vitis-hls/Interfaces-for-Vivado-IP-Flow)). Since I’m a n00b, I neither know how to use a BRAM interface, nor do I know how to adjust this after the fact (i.e., in the Verilog/RTL itself).

My galaxy brain idea was to use a “wrapper” kernel that is annotated with pragmas that then calls my actual `conv.forward` kernel. **Talk about easier said than done**. The [wrapper kernel](https://github.com/makslevental/torch-mlir/blob/d183103de64036674e8d30cb696e83edd086394e/hls/scripts/wrapper.cpp) is straightforward (not unlike the kernel from my MatMul example):

```cpp
#include <inttypes.h>
#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"

#define N 8
#define N2 64 // N*N
#define M 6
#define M2 36
#define DWIDTH 512

void forward(float (&arg_2)[1][1][N][N], float (&arg_3)[1][1][M][M]);

...

extern "C" {
void wrapper(hls::stream<axis_t> &in, hls::stream<axis_t> &out) {
	#pragma HLS top name=wrapper
	#pragma HLS INTERFACE axis port = in
	#pragma HLS INTERFACE axis port = out

  float l_A[1][1][8][8];
  float l_C[1][1][6][6];

	...

  forward(l_A, l_C);
	
	...

	return;
}
}
```

Key thing to notice here is the forward declaration for `forward`; this is `conv.forward`. The starting place for trying this was making this replacement in `run_hls.tcl`:

```cpp
- add_files dummy.cpp
+ add_files wrapper.cpp
```

# Problems and Solutions

**This does not work**. The reason is that the `set ::LLVM_CUSTOM_CMD` that’s run in the hook completely ignores all prior work done by clang. So actually what results from making this substitution is Vitis complaining that you don’t have a top-level function because the only thing it sees is the llvm bitcode produced from `conv.opt.vitis.ll` (because, recall, we did not annotate `conv.forward` as the top-level).

Regardless, come with me on a journey of the most insane debugging I'v ever done.


## Linking

After many hours of digging and poring and `llvm-dis`ing, I figured out the solution. The solution is to “compile” `conv.op.vitis.ll` in the hook (i.e., transform to bitcode) *and link against what Vitis HLS has done up to that point*. That means you need to insert something like this into the hook itself (`/common/scripts/hls_hooks.tcl`):

```cpp
exec -ignorestderr \ 
	Vitis_HLS/2021.1/lnx64/tools/clang-3.9-csynth/bin/opt \
	conv.opt.vitis.ll \ 
  -o proj/solution1/.autopilot/db/a.g.ld.5.5.user.bc
run_link_or_opt 
  -out proj/solution1/.autopilot/db/a.g.ld.5.6.user.bc \
  -args "proj/solution1/.autopilot/db/a.g.ld.4.m2.bc proj/solution1/.autopilot/db/a.g.ld.5.5.user.bc"
run_link_or_opt -opt \ 
-out proj/solution1/.autopilot/db/a.g.ld.6.user.bc -args "proj/solution1/.autopilot/db/a.g.ld.5.6.user.bc -hls-top-function-name=wrapper"
```

This works like this:

1. `exec` compiles (to bitcode) `conv.opt.vitis.ll`
2. `run_link_or_opt -out` links the output of step 1 against the transformations that Vitis has done on `wrapper.cpp` *up until this point*.
3. `run_link_or_opt -opt -out` runs an optimization pass that reannotates the top-level (I’m not sure if this is absolutely necssary).

Note that you’re reading and writing to the `.autopilot/db/` directory (talk about brittle...).

## Name Mangling

**This almost works**. The error you will get now is that `wrapper.cpp` is trying to call an undefined `forward` (all this and more at `.autopilot/db/autopilot.flow.log`). What’s happening is that, while `llvm-link` is successfully linking `conv.opt.vitis.ll` with `a.g.ld.4.m2.bc`, it is not at any point name mangling `forward`, while the reference to `forward` in `wrapper` *is name mangled*. I.e., references look like `@_Z7forwardPA1_A8_A8_fPA1_A6_A6_f`. I have not figured out how to make this happen automatically, so what I did was write a stub in Vitis HLS (i.e., the GUI) with the right signature, have Vitis HLS run synthesis, and then `llvm-dis` the results and copy+paste into `conv.opt.vitis.ll`. In addition I grabbed the attributes that Vitis HLS adds automatically; the relevant bits are

```cpp
define void @_Z7forwardPA1_A8_A8_fPA1_A6_A6_f([1 x [8 x [8 x float]]]*, [1 x [6 x [6 x float]]]*) #0

!7 = distinct !DISubprogram(name: "forward", linkageName: "_Z7forwardPA1_A8_A8_fPA1_A6_A6_f", scope: !8, file: !8, line: 3, type: !9, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !2)
```

I also annotated `forward` with `__attribute__((used)) void forward` just in case, which produces

```cpp
@llvm.used = appending global [1 x i8*] [i8* bitcast (void ([1 x [1 x [8 x [8 x float]]]]*, [1 x [1 x [6 x [6 x float]]]]*)* @_Z7forwardPA1_A8_A8_fPA1_A6_A6_f to i8*)], section "llvm.metadata"
```

You’ll have to experiment with how much you pull from the bottom of disassembled `forward` (i.e., `!9` and the rest that are referenced).

## Array Decay

**This still does not work** (pulling hair out yet?). You will get errors about the declaration for `forward` and the call site in `wrapper` being different. Notice that the signature that Vitis produces from

```cpp
 void forward(float [1][1][N][N], float [1][1][M][M]);
```

is actually

```cpp
void forward(float (*) [1][8][8], float (*) [1][6][6])
```

(try `c++filt _Z7forwardPA1_A8_A8_fPA1_A6_A6_f`). This is because of [arrays decay to pointers](https://www.geeksforgeeks.org/what-is-array-decay-in-c-how-can-it-be-prevented/); this shows up in the bitcode for `wrapper` as 

```cpp
%arraydecay = getelementptr inbounds [1 x [1 x [8 x [8 x float]]]], [1 x [1 x [8 x [8 x float]]]]* %l_A, i32 0, i32 0, !dbg !1957
%arraydecay9 = getelementptr inbounds [1 x [1 x [6 x [6 x float]]]], [1 x [1 x [6 x [6 x float]]]]* %l_C, i32 0, i32 0, !dbg !1958
call void @_Z7forwardPA1_A8_A8_fPA1_A6_A6_f([1 x [8 x [8 x float]]]* %arraydecay, [1 x [6 x [6 x float]]]* %arraydecay9), !dbg !1959
```

(with maybe a bitcast).

The just prior link to [geeksforgeeks](https://www.geeksforgeeks.org/what-is-array-decay-in-c-how-can-it-be-prevented/) actually ended up having the solution (first time ever I think...); change the declaration of `forward` in `wrapper.cpp` to

```cpp
void forward(float (&arg_2)[1][1][N][N], float (&arg_3)[1][1][M][M]);
```

to get a mangled name like `_Z7forwardRA1_A1_A8_A8_fRA1_A1_A6_A6_f` and use the corresponding signature 

```cpp
void @_Z7forwardRA1_A1_A8_A8_fRA1_A1_A6_A6_f([1 x [1 x [8 x [8 x float]]]]* dereferenceable(256) %l_A, [1 x [1 x [6 x [6 x float]]]]* dereferenceable(144) %l_C)
```

when you copy+paste into `conv.opt.vitis.ll`.

## Synthesis

After jumping through all of those hoops you should be able to synthesize and implement successfully. You can then create an IP core (using `config_export -format ip_catalog -rtl  verilog` and `export_design -rtl verilog -format ip_catalog`) and use that IP core in the same way as I did for [MatMul](https://makslevental.github.io/Matmul-on-FPGA-PCIE/) (i.e., with AXI Stream Width Converters and etc). 

If you get a synthesis error in Vivado about `floating point v7_1_12.v` missing then you might be using an outdated version of `vitis_hls` (i.e., Vitis HLS); this issue cleared up for me going from `2021.1` to `2021.2`.

# Finally!

Using a script similar to the `[matmul.py](https://gist.github.com/makslevental/69107d0e566040b24bc317354b6372d9)` script

```python
import os
import numpy as np
import asyncio

MATRIX_DIM = 8
NUM_EL_MATRIX = MATRIX_DIM * MATRIX_DIM
DATA_TYPE = np.float32
DATA_BYTES = np.dtype(DATA_TYPE).itemsize

MAT_A = np.arange(0, NUM_EL_MATRIX, dtype=DATA_TYPE).reshape(MATRIX_DIM, MATRIX_DIM)

async def to_device():
  xdma_axis_wr_data = os.open("/dev/xdma0_h2c_0", os.O_WRONLY)

  print(f"{MAT_A=}")

  buffer = MAT_A
  os.write(xdma_axis_wr_data, buffer.tobytes())

async def from_device():
  xdma_axis_rd_data = os.open("/dev/xdma0_c2h_0", os.O_RDONLY)

  buffer_size = 6 * 6 * DATA_BYTES
  data = os.read(xdma_axis_rd_data, buffer_size)
  output = np.frombuffer(data, dtype=DATA_TYPE).reshape(6, 6)
  print(f"{output=}")
  # why am i getting 48 bytes left in the stream?
  print(os.read(xdma_axis_rd_data, 48))

async def conv():
  # don't flip the order!
  await to_device()
  await from_device()

asyncio.run(conv())
```

As the note in `from_device` says, after reading from the FPGA there seem to be 48 bytes left that need to cleared out. I have no clue why it’s 48 (i.e., 12 floats) but that’s a battle for another day. 

Pics or didn’t happen:

![Untitled](/images/torch_mlir_fpga/Untitled.png)