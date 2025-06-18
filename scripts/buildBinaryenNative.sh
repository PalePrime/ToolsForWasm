#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/binaryen
DST_PATH=$NATIVE_ROOT/binaryen

cmake --fresh -S $SRC_PATH -B $BUILD_ROOT/buildBinaryenNative \
  -DBUILD_TESTS=OFF \
  -DCMAKE_INSTALL_PREFIX=$DST_PATH

cmake --build $BUILD_ROOT/buildBinaryenNative
cmake --install $BUILD_ROOT/buildBinaryenNative

