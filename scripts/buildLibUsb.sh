#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/libusb
DST_PATH=$WASM_ROOT/libusb

cd $SRC_PATH

./bootstrap.sh

mkdir -p $BUILD_ROOT/buildLibusbWasm

cd $BUILD_ROOT/buildLibusbWasm

_CPPFLAGS=""
_CXXFLAGS=""
_LDFLAGS="$BASE_EM_LDFLAGS"

$EM_ROOT/emconfigure $SRC_PATH/configure CXXFLAGS="$_CXXFLAGS" LDFLAGS="$_LDFLAGS" CPPFLAGS="$_CPPFLAGS" \
  --host=wasm32-emscripten \
  --prefix="$DST_PATH"

make
make install
