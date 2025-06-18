#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../../activate.sh

mkdir -p $BUILD_ROOT/test
cd $BUILD_ROOT/test

for File in "printargs" "random_pi" ;
  do
    echo $File
    $NATIVE_ROOT/clang/bin/clang --sysroot=$HOST_SDK $TEST_ROOT/code/$File.c -o $File
    $EM_ROOT/emcc -g $BASE_EM_LDFLAGS $TEST_ROOT/code/$File.c -o $File.js
  done

