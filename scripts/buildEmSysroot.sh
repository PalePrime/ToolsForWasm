#!/bin/bash -x

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

NAME=em_sysroot
DST_PATH=$WASM_ROOT/$NAME
BUILD_PATH=$BUILD_ROOT/$NAME

if [ ! -d $BUILD_PATH ]; then
  mkdir $BUILD_PATH
fi
cd $BUILD_PATH

$EM_ROOT/tools/file_packager \
  $NAME --embed  $EM_ROOT/cache/sysroot@/em_sysroot --obj-output=include.o

cat - > $NAME.c <<EOF
int main(int argc, char* argv[]) {
  return argc;
}
EOF

$EM_ROOT/emcc -Os $BASE_EM_LDFLAGS -o $NAME.js $NAME.c include.o

if [ ! -d $DST_PATH ]; then
  mkdir $DST_PATH
fi

cp $NAME.js $NAME.wasm $DST_PATH

