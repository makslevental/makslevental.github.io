---
layout: post
published: true
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: Working with MLIR
---

Random tips on working with the MLIR (LLVM) (and, possibly, other large C++ codebases).
These are in no particular order[^1]. Skim (don't peruse) and come back and use `ctrl+f`.

<!--more-->

# CMake

CMake is annoying/complicated/widely used (and LLVM's CMake patterns are triply so). Enough said. This is just a 5s intro (there are [tutorials](https://cliutils.gitlab.io/modern-cmake/) but who wants to be a CMake expert 🤷).

## Configure/build

Standard (LLVM) flow:

```shell
\$ pwd
~dev_projects/llvm-project/llvm
\$ git fetch --all && git pull
\$ mkdir build && cd build
\$ cmake .. [CMAKE BUILD ARGS] 
\$ ninja all 
```

Note that `..` is not an ellipsis (it's the parent directory shell shortcut/expansion/thing).

**Note that the root CMakeLists.txt for llvm project is actually llvm-project/llvm/CMakeLists.txt**, not `llvm-project/CMakeLists.txt`[^2].

## Variables

To declare/define a variable that can be passed in from CLI (i.e., when configuring):
```
set(MY_VARIABLE "option_value" CACHE STRING "Some user-specified option")
```
Then

```shell
cmake -DMY_VARIABLE=option_value2 ...
```

will make that variable available; e.g.,

```
message(STATUS "my variable value is ${MY_VARIABLE}")
```

## Useful/necessary defines for llvm

```shell
-DPython3_FIND_STRATEGY=LOCATION
-DPython3_ROOT_DIR="$(which python)/../../"
-DCMAKE_INSTALL_PREFIX=llvm_install
-DLLVM_ENABLE_PROJECTS=mlir
-DMLIR_ENABLE_BINDINGS_PYTHON=ON
```

This first two flags/options are standard CMake and might be optional; in particular `-DPython3_ROOT_DIR=...` - I might be doing things wrong that `Python_FIND_VIRTUALENV` never seems to work for me but 🤷.
The second two are LLVM project CMake options and (obviously) necessary if you want to work with MLIR and the MLIR Python bindings.
LLVM has a lot of CMake [options](https://llvm.org/docs/CMake.html); be aware but don't get distracted.

## Debugging

There are probably better ways to do this (see [here](https://stackoverflow.com/a/38864618/9045206)) but a quick/dirty way is "printf" debugging:

```
message(FATAL_ERROR ${variable you want to print})
```

If you're having trouble with changes to your configuration not taking effect, blow away your `build/CMakeCache.txt` or the the whole build directory - the latter being quite expensive (a full rebuild being a consequence/repercussion) but the wait is worth the sanity preserved.


# Linking/symbols


## Use `LD_DEBUG_OUTPUT=ldlog LD_DEBUG=all LD_BIND_NOT=1` to track down linker errors

This will dump (to `ldlog.<PID>`) all of the symbol resolution that the linker performs at runtime.

In general, a quick scan of [man ld.so](https://man7.org/linux/man-pages/man8/ld.so.8.html) is useful for being aware of possible flags to pass to the runtime linker/loader.

Along the same lines (linker errors), use `nm -gDC something.so` to figure out which symbols are present in a shared object:

```shell
nm -gDC _mlir.cpython-310-x86_64-linux-gnu.so | grep -C10 SuccessorRange

...

0000000000220340 T llvm::WithColor::WithColor(llvm::raw_ostream&, llvm::HighlightColor, llvm::ColorMode)
00000000002209b0 T llvm::WithColor::~WithColor()
00000000002209b0 T llvm::WithColor::~WithColor()
00000000001d1620 T llvm::write_hex(llvm::raw_ostream&, unsigned long, llvm::HexPrintStyle, std::optional<unsigned long>)
                 U mlir::SuccessorRange::SuccessorRange(mlir::Operation*)
```

`T` means is present/defined/accessible from the `.so` itself while `U` means the symbol is undefined (and must be sought elsewhere by the runtime linker/loader). Again `man nm` is useful for a listing of the definitions of other possible labels.


**On Mac OS** this is `DYLD_PRINT_SEARCHING=1 DYLD_PRINT_BINDINGS=1 DYLD_PRINT_LIBRARIES=1`; additionally `LD_PRELOAD` is `DYLD_INSERT_LIBRARIES`.

## Use `c++filt` to demangle symbol names

Names in symbol tables in objects/binaries/whatever are "name mangled"; something like `_ZN4mlir14SuccessorRangeC1EPNS_9OperationE` will appear in a symbol table and can be "demangled":

```shell
$ c++filt _ZN4mlir14SuccessorRangeC1EPNS_9OperationE

mlir::SuccessorRange::SuccessorRange(mlir::Operation*)
```

## Fixing `undefined symbol: _ZN4mlir14...`

If you're getting an undefined symbol error (at runtime or compile time), make sure you've linked the *right* MLIR (or LLVM) targets/libraries. For example, I kept getting (through python bindings...)

```
ImportError: /home/mlevental/dev_projects/SharkPy/pi/_mlir.cpython-310-x86_64-linux-gnu.so: undefined symbol: _ZN4mlir14SuccessorRangeC1EPNS_9OperationE
```

This function is defined at [mlir/lib/IR/Block.cpp#L323](https://github.com/llvm/llvm-project/blob/f55ed88936f3cdf0e9c0ac9c52761dd199b6ab2b/mlir/lib/IR/Block.cpp#L323), which is included in the `MLIRIR` target/library, [specified by the sibling/adjacent CMakeList.txt](https://github.com/llvm/llvm-project/blob/02c2ecb9c6c355b8b6f650d258077bd9cca0aacf/mlir/lib/IR/CMakeLists.txt#L6). Adding that dependency 

```
target_link_libraries(_mlir PRIVATE LLVMSupport MLIRIR)
```

in *my* CMakeLists.txt fixed my problem.


### Fixing missing `typeinfo for mlir::python::PyOperation`

This is a particular case of undefined symbol:

```shell
_loopy_mlir.cpython-310-x86_64-linux-gnu.so: undefined symbol: _ZTIN4mlir6python11PyOperationE
c++filt _ZTIN4mlir6python11PyOperationE
typeinfo for mlir::python::PyOperation
```

This is about [Runtime type information (RTTI)](https://en.wikipedia.org/wiki/Run-time_type_information), which `pybind11` uses to magically cast/infer things about types passed around:

```c++
m.def("walk_operation",
      [](PyOperation &self, std::function<void(MlirOperation)> callback) {
        unwrap(self.get())->walk([&callback](Operation *op) {
          callback(wrap(op));
        });
      });
```

**which takes PyOperation &self** as an argument, which is defined in [`mlir/lib/Bindings/Python/IRModule.h`](https://github.com/llvm/llvm-project/blob/88f7b4d5b6f47dfe3e8d891fbaafe5e93a4f7648/mlir/lib/Bindings/Python/IRModule.h#L534) and bound to the Python `ir.Operation` class `ir.Operation` in [`mlir/lib/Bindings/Python/IRCore.cpp`](https://github.com/llvm/llvm-project/blob/88f7b4d5b6f47dfe3e8d891fbaafe5e93a4f7648/mlir/lib/Bindings/Python/IRCore.cpp#L2773). The "typeinfo" (in the C++ RTTI sense) isn't exported _as a symbol_ by the stock MLIR Python bindings:

```shell
$ nm -gDC _mlir.cpython-310-x86_64-linux-gnu.so | grep typeinfo | grep PyOperation
<bupkiss>
```

but is needed by extensions that might wish to avail themselves of that code:

```shell
$ nm -gDC _loopy_mlir.cpython-310-x86_64-linux-gnu.so | grep typeinfo | grep PyOperation
    U typeinfo for mlir::python::PyOperation
```

The solution is to annotate `PyOperation` with `__attribute__ ((visibility("default")))`:

```c++
class PYBIND11_EXPORT __attribute__ ((visibility("default"))) PyOperation {
```

Note that `pybind11` already has such a macro:

```c++
#define PYBIND11_EXPORT __attribute__ ((visibility("default")))
```

Once you do this, and recompile, you see all of the "typeinfo":

```shell
$ nm -gDC _mlir.cpython-310-x86_64-linux-gnu.so | grep typeinfo | grep PyOperation
000000000036c4e8 V typeinfo for mlir::python::PyOperation
0000000000260bf0 V typeinfo name for mlir::python::PyOperation
```

**But that's not enough**; The symbol is there in the symbol table:

```shell
$ readelf -s -W -C _mlir.cpython-310-x86_64-linux-gnu.so | grep typeinfo | grep PyOperation
687: 000000000036c4e8    56 OBJECT  WEAK   DEFAULT   23 typeinfo for mlir::python::PyOperation
635: 0000000000260bf0    28 OBJECT  WEAK   DEFAULT   16 typeinfo name for mlir::python::PyOperation
```

but it's a `WEAK` symbol (the `V` in the `nm` ouput stands for "vague"). For whatever reason, vague/weak symbols[^4] aren't visible by default when a C extension is loaded, which by default is under the `RTLD_LOCAL` method (see [`man dlopen`](https://linux.die.net/man/3/dlopen)). The solution is to load the `_mlir.cpython-310-x86_64-linux-gnu.so` extension using `RTLD_GLOBAL`:

```python
@contextlib.contextmanager
def dl_open_guard():
    old_flags = sys.getdlopenflags()
    sys.setdlopenflags(old_flags | ctypes.RTLD_GLOBAL)
    yield
    sys.setdlopenflags(old_flags)

with dl_open_guard():
    # noinspection PyUnresolvedReferences
    from loopy.loopy_mlir._mlir_libs import _mlir
```

### Fixing missing `__ZTVN4mlir4PassE` i.e. `typeinfo for mlir::Pass`

This is also about RTTI but in a different way because while the Python extensions in MLIR are compiled with RTTI (in order to support `pybind11`), the rest of MLIR is not (by default).
Thus if you see this, it means you're compiling something which then links against MLIR libs and expects them to have `typeinfo`, which they will not. 
The solution is to compile your thing without RTTI as well; add this to you `CMakeLists.txt`:

```
if (NOT LLVM_ENABLE_RTTI)
    message(STATUS "NOT LLVM_ENABLE_RTTI")
    if (MSVC)
        string(REGEX REPLACE "/GR" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /GR-")
    else ()
        string(REGEX REPLACE "-frtti" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti")
    endif ()
endif ()
```

## `libstdc++.so.6: version `GLIBCXX_3.4.30' not found`

If you get an error like 

```
ImportError: miniconda3/envs/loopy/bin/../lib/libstdc++.so.6: version `GLIBCXX_3.4.30' not found (required by loopy/loopy/loopy_mlir/_mlir_libs/libLoopyMLIRAggregateCAPI.so.15)
```

it means some library that you're loading (`libLoopyMLIRAggregateCAPI.so.15` in this case) depends on a version of `libstdc++` that you don't have in your `LD_LIBRARY_PATH`. Either this means you just don't have it on your system (in which case you need to install it or upgrade the version you do have) or the loader isn't finding the correct `libstdc++.so.6`. In this case the loader is trying to use `miniconda3/envs/loopylib/libstdc++.so.6`, which I can verify, indeed, isn't up to date (only supports upto `GLIBCXX_3.4.29`):

```shell
strings /home/mlevental/miniconda3/envs/loopylib/libstdc++.so.6 | grep GLIBCXX

...

GLIBCXX_3.4.23
GLIBCXX_3.4.24
GLIBCXX_3.4.25
GLIBCXX_3.4.26
GLIBCXX_3.4.27
GLIBCXX_3.4.28
GLIBCXX_3.4.29
GLIBCXX_DEBUG_MESSAGE_LENGTH
...
```

The annoying thing is that I do have a sufficiently upto date `libstdc++.so.6` on my system:

```shell
strings /usr/lib/x86_64-linux-gnu/libstdc++.so.6 | grep GLIBCXX

GLIBCXX_3.4.28
GLIBCXX_3.4.29
GLIBCXX_3.4.30
GLIBCXX_DEBUG_MESSAGE_LENGTH
```

but the loader isn't picking that one. Most likely because `conda` rewrites the `LD_LIBRARY_PATH`.

Further complicating issue was that if I loaded some libraries in a different order (loading the `_mlir` python extension first before my own) the loader did find the right `libstdc++.so.6`). That means this is some issue of `RPATH` or `RUNPATH` (see [here](https://medium.com/obscure-system/rpath-vs-runpath-883029b17c45)).
You can debug this by using `LD_DEBUG_OUTPUT=ldlog LD_DEBUG=all LD_BIND_NOT=1` (see below for more info on this) but the quick/dirty solution is just to upgrade `libstdc++.so.6` in the environment:

```shell
conda install -c conda-forge libstdcxx-ng=12
```


# Torch-MLIR

## Update submodules

Usual "workflow" when starting fresh is:

```git fetch --all && git pull main && git submodule update --init --recursive```

## `torch-mlir` and `pytorch` version discrepancies

If you get something like this when trying to install the `torch-mlir` python packages

```
ERROR: Cannot install torch-mlir==0.0.1, torch==2.0.0.dev20230120 and torchvision==0.15.0.dev20230120+cpu because these package versions have conflicting dependencies.

The conflict is caused by:
    The user requested torch==2.0.0.dev20230120
    torchvision 0.15.0.dev20230120+cpu depends on torch
    torch-mlir 0.0.1 depends on torch==2.0.0.dev20230106
```

i.e., it seems like you have some weird circular dependency (you're trying to install `pytorch` in order to install `torch-mlir` but `torchvision` depends on a version that's different from the *stated* version depended on by `torch-mlir`), what's happening is **you already had `pytorch` installed at some point during the build process of torch-mlir** (`torch-mlir` reads the version that it depends on from your [current virtual environment](https://github.com/makslevental/torch-mlir/blob/6e0b5b9ba740bf19110e58215135b84608c14e0e/setup.py#L164)). **Solution:** uninstall `pytorch` (`pip uninstall torch torchvision`) and reinstall `torch-mlir` like this

```shell
pip <whatever you're doing> --force-reinstall -f https://download.pytorch.org/whl/nightly/cpu/torch_nightly.html
```

(`-f` for "find links", in order to find the right/needed version of `pytorch` and `torchvision`).


## Minimal out-of-tree build

The default build is "in-tree" i.e., it builds LLVM at the same time as Torch-MLIR (just prior but you get it). 
If you have LLVM already built somewhere else you can build Torch-MLIR "out-of-tree".
**The minimal CMake config for the LLVM build is something like**

```
-DLLVM_ENABLE_PROJECTS="mlir" \
-DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=mold" \
-DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=mold" \
-DCMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=mold" \
-DCMAKE_C_COMPILER_LAUNCHER=ccache \
-DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
-DCMAKE_INSTALL_PREFIX=/home/mlevental/dev_projects/torch-mlir/llvm_install \
-DMLIR_ENABLE_BINDINGS_PYTHON=ON \
-DPython3_EXECUTABLE=/home/mlevental/dev_projects/torch-mlir/venv/bin/python \
-DLLVM_INSTALL_UTILS=ON
```

Note `LLVM_INSTALL_UTILS=ON` is necessary for `FileCheck` and etc to be copied into the install `bin` directory but for some reason `llvm-lit` isn't copied (Torch-MLIR uses these for its own testing).

Then the minimal CMake config for Torch-MLIR itself is something like

```
-DTORCH_MLIR_OUT_OF_TREE_BUILD=ON
-DCMAKE_PREFIX_PATH=/home/mlevental/dev_projects/torch-mlir/llvm_install
-DPython3_EXECUTABLE=/home/mlevental/dev_projects/torch-mlir/venv/bin/python
```

Note that the `DPython3_EXECUTABLE` should be the same in both CMakes.


# Improving compile times

LLVM is huge, it's gonna take a while to build/compile the first time, no way around it. Subsequent builds should be reasonable (unless you're touching some header that's included everywhere). You can improve things sometimes/a little.


## Use `ccache` to cache compiled ~things

[https://ccache.dev/](https://ccache.dev/).

CMake and et al. already cache compiled objects (`.a`s and `.so`s and etc.) but `ccache` does better (by caching at the translation unit or something like that?). 

Install `ccache` using `brew` or `apt-get` or whatever and either set it globally to be your compiler (using its own `.bashrc` aliases) or (more robustly) pass these CMake flags:

```
-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
```

**Sometimes you need to flush the `ccache` cache** (e.g., if you see linker errors about missing symbols): `ccache -C`.


## Use a faster linker `lld` (or `mold`)

I.e., use a faster linker; `lld` is shipped with LLVM[^3] and [mold is in various places](https://github.com/rui314/mold#install). Then include these CMake flags:

```
-DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=lld"
-DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=lld"
-DCMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=lld"
```

# Random

## `Type` and `Context`

Types are uniqued to the context they were created in; thus 

```shell
error: 'arith.mulf' op requires the same type for all operands and results
```

even though

```cpp
%3 = "arith.constant"() {value = 1.000000e+00 : f64} : () -> f64
...
%6 = "affine.load"(%4, %5, %5) {map = #map1} : (memref<10x10xf64>, index, index) -> f64
%7 = "arith.mulf"(%6, %3) : (f64, f64) -> f64
```

is because while `%3` and `%6` are the same "type", they are not the same `Type` (because they were created, by my code, in different contexts).

# Footnotes
  [^1]: I am updating this as they occur to me (and adding/prepending at the top).
  [^2]: MLIR, Clang, Polly, etc. are LLVM "in-tree" projects that are enabled using `-DLLVM_ENABLE_PROJECTS=mlir;...`.
  [^3]: You can install a system version of LLVM (`brew install llvm` or `apt-get install llvm`), which will include `clang`, `lldb`, `lld`, etc., *while* working on `llvm-project`. You can also "bootstrap", i.e., build `clang` (using `gcc`) and etc. from your current `llvm-project` source and then use those built binaries to continue to work on `llvm-project`. The former is probably the saner approach. **Note that distro/brew releases of LLVM do not currently ship with MLIR** (except on Fedora for some reason 🤷).
  [^4]: Maybe it's just all symbols aren't available for symbol resolution? That's what [`man dlopen`](https://linux.die.net/man/3/dlopen) seems to suggest regarding `RTLD_GLOBAL` vs. `RTLD_LOCAL`.