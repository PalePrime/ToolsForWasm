#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/fujprog
DST_PATH=$NATIVE_ROOT/fujprog

cmake -S $SRC_PATH -B $BUILD_ROOT/buildFujprogNative \
  -DCMAKE_INSTALL_PREFIX=$DST_PATH

cmake --build $BUILD_ROOT/buildFujprogNative
