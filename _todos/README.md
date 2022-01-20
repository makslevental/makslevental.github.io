- [FPGAs/HLS](#fpgas-hls)
  * [NiteFury and Litefury: Xilinx FPGA development board kit in M.2 form factor](#nitefury-and-litefury--xilinx-fpga-development-board-kit-in-m2-form-factor)
  * [FINN-HLS](#finn-hls)
  * [Parallel Programming for FPGAs](#parallel-programming-for-fpgas)
  * [PipelineC: Example: Basic Neural Network](#pipelinec--example--basic-neural-network)
  * [Transformations of High-Level Synthesis Codes for High-Performance Computing](#transformations-of-high-level-synthesis-codes-for-high-performance-computing)
  * [XLS: Accelerated HW Synthesis](#xls--accelerated-hw-synthesis)
  * [Compile code into silicon](#compile-code-into-silicon)
  * [A tutorial on non-separable 2D convolutions in Vivado HLS](#a-tutorial-on-non-separable-2d-convolutions-in-vivado-hls)
  * [DASS: Combining Dynamic & Static Scheduling in High-level Synthesis](#dass--combining-dynamic---static-scheduling-in-high-level-synthesis)
  * [AutoDNNchip: An Automated DNN Chip Predictor and Builder for Both FPGAs and ASICs](#autodnnchip--an-automated-dnn-chip-predictor-and-builder-for-both-fpgas-and-asics)
  * [A scalable High-Level Synthesis framework on MLIR](#a-scalable-high-level-synthesis-framework-on-mlir)
- [MLIR](#mlir)
  * [ESI cosimulation model](#esi-cosimulation-model)
  * [Buffer Placement and Sizing for High-Performance Dataflow Circuits](#buffer-placement-and-sizing-for-high-performance-dataflow-circuits)
  * [MLIR-based AIEngine toolchain](#mlir-based-aiengine-toolchain)
  * [Latency hiding / pipeline representation in MLIR](#latency-hiding---pipeline-representation-in-mlir)
  * [Better modelling of pipeline loops](#better-modelling-of-pipeline-loops)
  * [Writing a (MLIR) Pass](#writing-a--mlir--pass)
  * [What is the strategy for tensor->memref conversion? (bufferization)](#what-is-the-strategy-for-tensor--memref-conversion---bufferization-)
  * [Phism: Polyhedral High-Level Synthesis in MLIR](#phism--polyhedral-high-level-synthesis-in-mlir)
  * [This a CIRCT fork to work on the HIR dialect.](#this-a-circt-fork-to-work-on-the-hir-dialect)
- [Static analysis](#static-analysis)
  * [A Static Analyzer for Detecting Tensor Shape Errors in Deep Neural Network Training Code](#a-static-analyzer-for-detecting-tensor-shape-errors-in-deep-neural-network-training-code)
  * [Software Verification and Analysis Using Z3](#software-verification-and-analysis-using-z3)
- [Compression](#compression)
  * [RealTime Data Compression](#realtime-data-compression)
  * [Are Huffman codes self-synchronizing?](#are-huffman-codes-self-synchronizing-)
  * [What algorithm is ncclAllReduce using?](#what-algorithm-is-ncclallreduce-using-)
- [GPUs](#gpus)
  * [Dissecting the NVidia Turing T4 GPU via Microbenchmarking (citadel paper)](#dissecting-the-nvidia-turing-t4-gpu-via-microbenchmarking--citadel-paper-)
- [C++/Software](#c---software)
  * [Tracy Profiler](#tracy-profiler)
  * [How To Write Fast Numerical Code: A Small Introduction](#how-to-write-fast-numerical-code--a-small-introduction)
  * [How to JIT - an introduction](#how-to-jit---an-introduction)
- [Parametric programming](#parametric-programming)
  * [Jean-Philippe (JP) Richard](#jean-philippe--jp--richard)
  * [Parametric Integer Programming Library](#parametric-integer-programming-library)

# FPGAs/HLS

## NiteFury and Litefury: Xilinx FPGA development board kit in M.2 form factor
something something anush told me about it

https://github.com/RHSResearchLLC/NiteFury-and-LiteFury

## FINN-HLS
try to figure out what they're doing that makes their ?libraries/kernels/modules? fast

https://github.com/Xilinx/finn-hlslib

## Parallel Programming for FPGAs
stephen's book on writing hls suited c++. read to try to figure out what can be recycled into the ir

https://kastner.ucsd.edu/hlsbook/

## PipelineC: Example: Basic Neural Network

Julian Kemmerer's project that discusses the important things to consider when pipelining an NN

https://github.com/JulianKemmerer/PipelineC/wiki/Example:-Basic-Neural-Network

## Transformations of High-Level Synthesis Codes for High-Performance Computing

no clue yet

https://arxiv.org/pdf/1805.08288.pdf

## XLS: Accelerated HW Synthesis

google's hls thing - potentially integrate with MLIR

https://github.com/google/xls

https://news.ycombinator.com/item?id=24354083

## Compile code into silicon

that weird toolchain thing - might be useful for compiling down to lattice using yosys

https://www.siliconcompiler.com/

## A tutorial on non-separable 2D convolutions in Vivado HLS

might be useful for learning how to use vivado to get fast code for NNs

https://basile.be/2019/03/18/a-tutorial-on-non-separable-2d-convolutions-in-vivado-hls/

## DASS: Combining Dynamic & Static Scheduling in High-level Synthesis

is this a path from pytorch to hls?

https://jianyicheng.github.io/papers/ChengTCAD21.pdf

## AutoDNNchip: An Automated DNN Chip Predictor and Builder for Both FPGAs and ASICs

related work on pytorch to fpga

https://arxiv.org/abs/2001.03535

https://github.com/RICE-EIC/AutoDNNchip

## A scalable High-Level Synthesis framework on MLIR

https://github.com/hanchenye/scalehls

related work on pytorch to fpga

# MLIR

## ESI cosimulation model

mike's suggestion for quickest route to exposing internals of FPGAs

https://circt.llvm.org/docs/ESI/cosim/

## Buffer Placement and Sizing for High-Performance Dataflow Circuits

algo that still needs to be implemented in handshake in order to reduce number of gates

https://dl.acm.org/doi/10.1145/3373087.3375314

## MLIR-based AIEngine toolchain

stephen's thing for going from MLIR to versal boards

https://github.com/Xilinx/mlir-aie

https://github.com/Xilinx/mlir-xten

## Latency hiding / pipeline representation in MLIR

recommendation from stephen? mike? regarding improving pytorch -> vitis hls flow

https://llvm.discourse.group/t/latency-hiding-pipeline-representation-in-mlir/4591/6

## Better modelling of pipeline loops

recommendation from stephen? mike? regarding improving pytorch -> vitis hls flow

https://llvm.discourse.group/t/better-modelling-of-pipeline-loops/3917

## Writing a (MLIR) Pass

guide on how to write an MLIR pass 

https://github.com/joker-eph/llvm-project-with-mlir/blob/master/mlir/g3doc/WritingAPass.md

## What is the strategy for tensor->memref conversion? (bufferization)

useful potentially for comparing against what i'm doing naively

https://llvm.discourse.group/t/what-is-the-strategy-for-tensor-memref-conversion-bufferization/1938

## Phism: Polyhedral High-Level Synthesis in MLIR

https://github.com/kumasento/phism

## This a CIRCT fork to work on the HIR dialect.

bongdhula's CIRCT dialect 

https://github.com/mcl-csa/circt-hir

https://arxiv.org/pdf/2103.00194.pdf





# Static analysis

## A Static Analyzer for Detecting Tensor Shape Errors in Deep Neural Network Training Code

https://arxiv.org/pdf/2112.09037.pdf


## Software Verification and Analysis Using Z3 

use for something somehow involving tensor shapes? ala that google paper

https://news.ycombinator.com/item?id=25973194

https://stackoverflow.com/questions/21708404/it-is-possible-to-use-llvm-bytecode-as-z3-input/21736304

https://github.com/llvm/llvm-project/search?q=dump%28%29


# Compression

## RealTime Data Compression

Yann Collet's blog about zstd

https://fastcompression.blogspot.com/


## Are Huffman codes self-synchronizing?

useful starting point for thinking about whether ANS codes are self-synchronizing

https://cs.stackexchange.com/questions/100464/are-huffman-codes-self-synchronizing

## What algorithm is ncclAllReduce using?

starting point for how to shoehorn dietgpu into a ccl

https://github.com/NVIDIA/nccl/issues/256


# GPUs

## Dissecting the NVidia Turing T4 GPU via Microbenchmarking (citadel paper)

might be interesting for learning stuff about GPU arch

https://arxiv.org/pdf/1903.07486.pdf

# C++/Software

## Tracy Profiler

https://github.com/wolfpld/tracy

## How To Write Fast Numerical Code: A Small Introduction

general stuff that's useful for thinking about arch tuning

https://users.ece.cmu.edu/~franzf/papers/gttse07.pdf

## How to JIT - an introduction

sooner or later need to read this to understand wtf a jit really is

https://eli.thegreenplace.net/2013/11/05/how-to-jit-an-introduction

# Parametric programming

## Jean-Philippe (JP) Richard

email richard and ask about the problem

https://cse.umn.edu/isye/jean-philippe-jp-richard

## Parametric Integer Programming Library

https://github.com/periscop/piplib
