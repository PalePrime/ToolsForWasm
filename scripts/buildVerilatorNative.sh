#!/bin/bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC=$(dirname $0)
SRC_PATH=$SRC_ROOT/verilator

DST_PATH=$NATIVE_ROOT/verilator

cd $SRC_PATH

unset VERILATOR_ROOT

autoconf

_CPPFLAGS=-I/opt/homebrew/include

./configure --prefix $DST_PATH CPPFLAGS=$_CPPFLAGS #CXXFLAGS=$_CXXFLAGS LDFLAGS=$_LDFLAGS 
make

