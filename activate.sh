#THIS_SCRIPT=$(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" )

TOOL_ROOT=$(dirname $(realpath "${BASH_SOURCE[0]:-"$(command -v -- "$0")"}" ))

echo "Root of ToolsForWasm is at $TOOL_ROOT"

EM_ROOT=$TOOL_ROOT/emscripten
SRC_ROOT=$TOOL_ROOT
PATCH_ROOT=$TOOL_ROOT/patch
NATIVE_ROOT=$TOOL_ROOT/native
WASM_ROOT=$TOOL_ROOT/wasm
BUILD_ROOT=$TOOL_ROOT/build
TEST_ROOT=$TOOL_ROOT/test
VER_ROOT=$NATIVE_ROOT/verilator
CLANG_ROOT=$NATIVE_ROOT/clang

VERILATOR_ROOT=$VER_ROOT/share/verilator

BASE_EM_LDFLAGS="\
  -sEXPORT_ES6 \
  -sEXPORTED_RUNTIME_METHODS=FS,PROXYFS,callMain,noExitRuntime,exitJS \
  -sEXIT_RUNTIME=1 \
  -sALLOW_MEMORY_GROWTH \
  -sFORCE_FILESYSTEM \
  -lproxyfs.js"

HOST_SDK=`xcrun --show-sdk-path`

