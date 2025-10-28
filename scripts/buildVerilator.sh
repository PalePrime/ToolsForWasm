#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC=$(dirname $0)
SRC_PATH=$SRC_ROOT/verilator

DST_PATH=$WASM_ROOT/verilator

mkdir -p $DST_PATH

cd $SRC_PATH

unset VERILATOR_ROOT

make clean

$EM_ROOT/tools/file_packager \
  verilator_include --embed include@/usr/local/share/verilator/include --obj-output=include.o

autoconf

_CPPFLAGS="-I/opt/homebrew/opt/flex/include"
_CXXFLAGS="-DVL_IGNORE_UNKNOWN_ARCH"
_LDFLAGS="$BASE_EM_LDFLAGS -sSTACK_SIZE=1048576 $SRC_PATH/include.o"

$EM_ROOT/emconfigure ./configure LEX=/opt/homebrew/opt/flex/bin/flex CXXFLAGS="$_CXXFLAGS" LDFLAGS="$_LDFLAGS" CPPFLAGS="$_CPPFLAGS"
make

cp bin/verilator_bin      $DST_PATH/verilator_bin.mjs
cp bin/verilator_bin.wasm $DST_PATH/verilator_bin.wasm

rm include.o include.s a.wasm
