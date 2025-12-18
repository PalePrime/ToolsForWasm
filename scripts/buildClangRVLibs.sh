#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/llvm-project/runtimes
DST_PATH=$WASM_ROOT/clangRV

C_COMPILER=$NATIVE_ROOT/clang/bin/clang
CXX_COMPILER=$NATIVE_ROOT/clang/bin/clang++

cmake --fresh -S $SRC_PATH -B $BUILD_ROOT/buildClangRVLibs \
 -DLLVM_ENABLE_RUNTIMES="libc;compiler-rt"  \
 -DCMAKE_C_COMPILER=$C_COMPILER \
 -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
 -DLLVM_LIBC_FULL_BUILD=ON \
 -DLIBC_TARGET_TRIPLE=riscv32i-unknown-elf \
 -DCMAKE_BUILD_TYPE=Release

# -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
# -DLLVM_TARGETS_TO_BUILD="WebAssembly;RISCV"

cmake --build $BUILD_ROOT/buildClangRVWasm --clean-first  #-j 4
#cmake --install $BUILD_ROOT/buildClangRVWasm
