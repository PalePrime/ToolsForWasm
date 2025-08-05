#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/fujprog
DST_PATH=$WASM_ROOT/fujprog


$EM_ROOT/emcmake cmake  --fresh -S $SRC_PATH -B $BUILD_ROOT/buildFujprogWasm \
  -DLIBFTDI_INCLUDE_DIRS="$WASM_ROOT/libftdi/include/libftdi1" \
  -DLIBFTDI_LIBRARIES="-L$WASM_ROOT/libftdi/lib -lftdi1" \
  -DLIBUSB_INCLUDE_DIRS="$WASM_ROOT/libusb/include/libusb-1.0" \
  -DLIBUSB_LIBRARIES="-L$WASM_ROOT/libusb/lib -lusb-1.0" \
  -DCMAKE_EXE_LINKER_FLAGS="\
    $BASE_EM_LDFLAGS \
    -lembind \
    -sASYNCIFY=1 \
  "

cmake --build $BUILD_ROOT/buildFujprogWasm
