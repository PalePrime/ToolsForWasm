#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/llvm-project/llvm
DST_PATH=$NATIVE_ROOT/clang

cmake -S $SRC_PATH -B $BUILD_ROOT/buildClangNative \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="AArch64;WebAssembly;RISCV" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCLANG_DEFAULT_LINKER=lld \
  -DCLANG_DEFAULT_RTLIB=compiler-rt \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DDEFAULT_SYSROOT=$HOST_SDK \
  -DCMAKE_INSTALL_PREFIX=$DST_PATH

cmake --build $BUILD_ROOT/buildClangNative
cmake --install $BUILD_ROOT/buildClangNative

