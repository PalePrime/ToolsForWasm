#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/fujprog
DST_PATH=$WASM_ROOT/fujprog


#$EM_ROOT/emcmake cmake -S $SRC_PATH -B $BUILD_ROOT/buildFujprogWasm \
#  -DCMAKE_EXE_LINKER_FLAGS="$BASE_EM_LDFLAGS"

#cmake --build $BUILD_ROOT/buildFujprogWasm
