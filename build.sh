#!/usr/bin/env bash
command -v emcc >/dev/null 2>&1 || {
  echo >&2 "emsdk could not be found.  Aborting."
  exit 1
}

set -e

# Working directories
SOURCE_DIR=$PWD
TARGET=/opt/libffi-emscripten

# JS BigInt to Wasm i64 integration, disabled by default
# This needs to test false if there exists an environment variable called
# WASM_BIGINT whose contents are empty. Don't use +x.
if [ -n "${WASM_BIGINT}" ]; then
  WASM_BIGINT=true
else
  WASM_BIGINT=false
fi

# Parse arguments
while [ $# -gt 0 ]; do
  case $1 in
  --enable-wasm-bigint) WASM_BIGINT=true ;;
  --debug) DEBUG=true ;;
  *)
    echo "ERROR: Unknown parameter: $1" >&2
    exit 1
    ;;
  esac
  shift
done

# Common compiler flags
export CFLAGS="-O3 -fPIC"
if [ "$WASM_BIGINT" = "true" ]; then
  # We need to detect WASM_BIGINT support at compile time
  export CFLAGS+=" -DWASM_BIGINT"
fi
if [ "$DEBUG" = "true" ]; then
  export CFLAGS+=" -DDEBUG_F"
fi
export CXXFLAGS="$CFLAGS"

# Build paths
export CPATH="$TARGET/include"
export PKG_CONFIG_PATH="$TARGET/lib/pkgconfig"
export EM_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"

# Specific variables for cross-compilation
export CHOST="wasm32-unknown-emscripten" # wasm32-unknown-linux
emcc --clear-cache
autoreconf -fiv
emconfigure ./configure\
  --host=$CHOST\
  --prefix="$TARGET"\
  --disable-dependency-tracking\
  --disable-docs\
  --enable-static\
  --enable-shared\
  --enable-wasm-dynamic-linking\
  --enable-optimizations
make install
cp -r ./wasm32-unknown-emscripten/* $TARGET
cp ./wasm32-unknown-emscripten/fficonfig.h $TARGET/include/
cp ./include/ffi_common.h $TARGET/include/
