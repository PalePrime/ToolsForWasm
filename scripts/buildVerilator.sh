#!/bin/bash

source ./activate.sh

SRC=$(dirname $0)
SRC_PATH=$SRC_ROOT/verilator

DST_PATH=$WASM_ROOT/verilator

cd $SRC_PATH

unset VERILATOR_ROOT

$EMSDK/upstream/emscripten/tools/file_packager \
  verilator_include --embed include@/usr/local/share/verilator/include --obj-output=include.o

autoconf

_CPPFLAGS=-I/opt/homebrew/include
_CXXFLAGS="-DVL_IGNORE_UNKNOWN_ARCH"
_LDFLAGS=$BASE_EM_LDFLAGS -sSTACK_SIZE=1048576 $SRC_PATH/include.o

emconfigure ./configure CXXFLAGS=$_CXXFLAGS LDFLAGS=$_LDFLAGS CPPFLAGS=$_CPPFLAGS
make

cp bin/verilator_bin $DST_PATH/verilator_bin.mjs
cp bin/verilator_bin.wasm $DST_PATH/verilator_bin.wasm

rm include.o include.s a.wasm
