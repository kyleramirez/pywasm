#!/usr/bin/env bash
. /emsdk/emsdk_env.sh
# emcc --clear-cache
git init
git fetch --depth 1 $LIBFFIREPO $LIBFFI_COMMIT
git checkout FETCH_HEAD
./testsuite/emscripten/build.sh --wasm-bigint
make install
