#!bash

THIS_PATH=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))
source $THIS_PATH/../activate.sh

SRC_PATH=$SRC_ROOT/llvm-project/llvm
DST_PATH=$WASM_ROOT/clang

echo "Verilator root: $VERILATOR_ROOT"

VERILATOR_INCLUDES="\
 -I.\
 -I$VERILATOR_ROOT/include\
 -I$VERILATOR_ROOT/include/vltstd"

VERILATOR_FLAGS="\
 -fPIC\
 -faligned-new\
 -fbracket-depth=4096\
 -fcf-protection=none\
 -Qunused-arguments\
 -Wno-c++11-narrowing\
 -Wno-constant-logical-operand\
 -Wno-non-pod-varargs\
 -Wno-parentheses-equality\
 -Wno-shadow\
 -Wno-sign-compare\
 -Wno-tautological-compare\
 -Wno-uninitialized\
 -Wno-unused-but-set-parameter\
 -Wno-unused-but-set-variable\
 -Wno-unused-parameter\
 -Wno-unused-variable\
 -std=gnu++20"

VERILATOR_DEFINES="\
 -DVL_IGNORE_UNKNOWN_ARCH\
 -DVM_COVERAGE=0\
 -DVM_SC=0\
 -DVM_TIMING=1\
 -DVM_TRACE=1\
 -DVM_TRACE_FST=0\
 -DVM_TRACE_VCD=1\
 -DVL_TIME_CONTEXT"

cd $TEST_ROOT/code

rm $BUILD_ROOT/simulator/top*.*
rm $BUILD_ROOT/simulator_model/top*.*

$VER_ROOT/bin/verilator --cc --Mdir $BUILD_ROOT/simulator       --prefix top --main --timing --assert --trace extra.cc dummy.sv
$VER_ROOT/bin/verilator --cc --Mdir $BUILD_ROOT/simulator_model --prefix top --main --timing --assert --trace extra.cc TestMooreMachine.sv

cd $BUILD_ROOT/simulator

EMXX="$EM_ROOT/em++"

$EMXX -Os -MMD $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -c -o extra.o $TEST_ROOT/code/extra.cc

$EMXX -Os -MMD $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -c -o verilated.o $VERILATOR_ROOT/include/verilated.cpp

$EMXX -Os -MMD $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -c -o verilated_vcd_c.o $VERILATOR_ROOT/include/verilated_vcd_c.cpp

$EMXX -Os -MMD $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -c -o verilated_threads.o $VERILATOR_ROOT/include/verilated_threads.cpp

$EMXX -Os -MMD $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -c -o verilated_timing.o $VERILATOR_ROOT/include/verilated_timing.cpp

$EMXX -Os -MMD $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -c -o verilated_random.o $VERILATOR_ROOT/include/verilated_random.cpp

$EMXX -Os -MMD $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -c -o verilated_dpi.o $VERILATOR_ROOT/include/verilated_dpi.cpp

$EMXX -Os -sSIDE_MODULE -sERROR_ON_UNDEFINED_SYMBOLS=0 -I.  -MMD\
 $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 -o top.wasm top*.cpp

$EMXX -Os -sMAIN_MODULE -sERROR_ON_UNDEFINED_SYMBOLS=0 -I.  -MMD\
 $BASE_EM_LDFLAGS\
 -o simulator.js extra.o verilated.o verilated_vcd_c.o\
 verilated_threads.o verilated_timing.o verilated_random.o verilated_dpi.o top.wasm

cd $BUILD_ROOT/simulator_model

# em++ -Os -sSIDE_MODULE -sERROR_ON_UNDEFINED_SYMBOLS=0 -I.  -MMD\
#  $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
#  -o top.wasm top*.cpp

awk 'FNR==1{print ""}1' *.cpp > all.cpp

$CLANG_ROOT/bin/clang++\
 -target wasm32-unknown-emscripten\
 -fignore-exceptions\
 -fvisibility=default\
 -mllvm -combiner-global-alias-analysis=false\
 -mllvm -enable-emscripten-sjlj\
 -mllvm -disable-lsr\
 --sysroot=$EM_ROOT/cache/sysroot\
 -DEMSCRIPTEN\
 -Xclang -iwithsysroot/include/fakesdl\
 -Xclang -iwithsysroot/include/compat\
 -c -Os -MMD\
 $VERILATOR_INCLUDES $VERILATOR_DEFINES $VERILATOR_FLAGS\
 all.cpp

$CLANG_ROOT/bin/wasm-ld\
 -o top.wasm\
 --whole-archive\
 all.o\
 --no-whole-archive\
 -mllvm -combiner-global-alias-analysis=false\
 -mllvm -enable-emscripten-sjlj\
 -mllvm -disable-lsr\
 --import-undefined\
 --import-memory\
 --strip-debug\
 --export-dynamic\
 --export-if-defined=__wasm_call_ctors\
 --export-if-defined=__start_em_asm\
 --export-if-defined=__stop_em_asm\
 --export-if-defined=__start_em_lib_deps\
 --export-if-defined=__stop_em_lib_deps\
 --export-if-defined=__start_em_js\
 --export-if-defined=__stop_em_js\
 --export-if-defined=main\
 --export-if-defined=__main_argc_argv\
 --export-if-defined=__wasm_apply_data_relocs\
 --experimental-pic\
 --unresolved-symbols=import-dynamic -shared

 # -L$EM_ROOT/cache/sysroot/lib/wasm32-emscripten/pic\
