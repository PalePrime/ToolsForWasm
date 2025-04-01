#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/activate.sh

cd emscripten

cat - > .emscripten <<EOF
LLVM_ROOT='$NATIVE_ROOT/clang/bin'
BINARYEN_ROOT='$NATIVE_ROOT/binaryen'
NODE_JS='/opt/homebrew/opt/node/bin/node'
EOF

./bootstrap

