
SCRIPT_ROOT=$(dirname $0)
TOOL_ROOT=$(realpath "$SCRIPT_ROOT/../")
SDK_ROOT=$TOOL_ROOT/sdks
SRC_ROOT=$TOOL_ROOT
NATIVE_ROOT=$TOOL_ROOT/native
WASM_ROOT=$TOOL_ROOT/wasm
BUILD_ROOT=$TOOL_ROOT/build

BASE_EM_LDFLAGS="\
  -sEXPORT_ES6 \
  -sEXPORTED_RUNTIME_METHODS=FS,PROXYFS,callMain,noExitRuntime,exitJS \
  -sFORCE_FILESYSTEM \
  -lproxyfs.js"

HOST_SDK=`xcrun --show-sdk-path`

EMSDK_QUIET=1
source $SDK_ROOT/emsdk/emsdk_env.sh
