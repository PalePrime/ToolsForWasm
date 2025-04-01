#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../../activate.sh

cd $BUILD_ROOT/test

$NATIVE_ROOT/clang/bin/clang -isysroot $HOST_SDK $TEST_ROOT/code/random_pi.c -o random_pi

$EM_ROOT/emcc $TEST_ROOT/code/random_pi.c -o random_pi.js
