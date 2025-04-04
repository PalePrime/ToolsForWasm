#!/bin/bash -x

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

NAME=yosys

SRC_PATH=$SRC_ROOT/$NAME
DST_PATH=$NATIVE_ROOT/$NAME
BUILD_PATH=$BUILD_ROOT/native$NAME

if [ ! -d $BUILD_PATH ]; then
  mkdir $BUILD_PATH
fi
cd $BUILD_PATH

# $EM_ROOT/tools/file_packager \
#   $NAME --embed  $EM_ROOT/cache/sysroot@/em_sysroot --obj-output=include.o

YOSYS_FLAGS="$BASE_EM_LDFLAGS -sASSERTIONS -sSTACK_SIZE=8388608 -g"

cat - > Makefile.conf <<EOF
PREFIX := $DST_PATH

EOF

make -f $SRC_PATH/Makefile
