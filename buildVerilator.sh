#!/bin/bash

SRC=$(dirname $0)
SRC_PATH=$(realpath $SRC)/verilator

DST_PATH=$(realpath $SRC)/dist

cd $SRC_PATH

unset VERILATOR_ROOT

$EMSDK/upstream/emscripten/tools/file_packager \
  verilator_include --embed include@/usr/local/share/verilator/include --obj-output=include.o

autoconf
./configure CC="emcc" CXX="em++"

CPPFLAGS="-I/opt/homebrew/include" \
CXXFLAGS="\
  -DVL_IGNORE_UNKNOWN_ARCH" \
LDFLAGS="\
  -sEXPORT_ES6 \
  -sEXPORTED_RUNTIME_METHODS=FS,PROXYFS,callMain,noExitRuntime,exitJS \
  -sSTACK_SIZE=1048576 \
  -sFORCE_FILESYSTEM \
  -lproxyfs.js \
  $SRC_PATH/include.o \
" emmake make

cp bin/verilator_bin $DST_PATH/verilator_bin.mjs
cp bin/verilator_bin.wasm $DST_PATH/verilator_bin.wasm
