#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/libftdi
DST_PATH=$WASM_ROOT/libftdi

$EM_ROOT/emcmake cmake -S $SRC_PATH -B $BUILD_ROOT/buildFtdiWasm \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_EXE_LINKER_FLAGS="$BASE_EM_LDFLAGS" \
  -DCMAKE_INSTALL_PREFIX="$DST_PATH" \
  -DCMAKE_INSTALL_LIBDIR="$DST_PATH/lib" \
  -DLIBUSB_INCLUDE_DIR="$WASM_ROOT/libusb/include/libusb-1.0" \
  -DLIBUSB_LIBRARIES="-L$WASM_ROOT/libusb/lib -lusb-1.0" \
  -DFTDI_EEPROM=OFF \
  -DEXAMPLES=OFF

cmake --build $BUILD_ROOT/buildFtdiWasm --clean-first
cmake --install $BUILD_ROOT/buildFtdiWasm
