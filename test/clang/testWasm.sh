#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../../activate.sh

WASM_ROOT=$WASM_ROOT TEST_ROOT=$TEST_ROOT EM_ROOT=$EM_ROOT BUILD_ROOT=$BUILD_ROOT node $THIS_PATH/testWasm.js

