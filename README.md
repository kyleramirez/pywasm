docker build -t pywasm .
docker run -it --rm pywasm /bin/bash
<!-- docker run --rm -v $(pwd):/src -u $(id -u):$(id -g) emscripten/emsdk emcc helloworld.cpp -o helloworld.js
docker run --rm -ti -v $(pwd):/python-wasm/cpython -w /python-wasm/cpython quay.io/tiran/cpythonbuild:emsdk3 bash -->

docker build -t pywasm .
docker run -it pywasm /bin/bash

docker run --rm -v $(pwd):/src -u $(id -u):$(id -g) pywasm main.py -o main.wasm



- how much per utility per month for 2023
- 2022 tax return
- amazon supplies receipts
- repairs
- Investment account tax form
  - Fundrise tax form
  - Robinhood tax form


- download nuitka
- apply all changes from py2wasm
  - this will show you everything the guy changed
- figure out how to incorporate your python and your emcc
- make it so that it compiles from python within your directory and places a wasm file in the same directory

# # Install pthreads
# ENV PTHREADBUILD=/opt/pthreads
# ENV PTHREADREPO=https://git.savannah.gnu.org/git/hurd/libpthread.git/
# ENV PTHREADBRANCH=2.26
# WORKDIR $PTHREADBUILD
# COPY ./install-pthread.sh .
# RUN ./install-pthread.sh --wasm-bigint
# Copy local setup

--with-libs="-L/opt/cpython/install/python-3.11.3/lib -lffi -lstdc++"\



export LDFLAGS_BASE=\


  
export MAIN_MODULE_LDFLAGS=
  -s MAIN_MODULE=1
  -s MODULARIZE=1
  -s DEMANGLE_SUPPORT=1
	-s FORCE_FILESYSTEM=1 \
	-s TOTAL_MEMORY=20971520 \
	-s EXPORT_ALL=1 \
	-s STACK_SIZE=5MB \
	-s EXPORT_NAME="'_createPyodideModule'" \
	-s EXPORT_EXCEPTION_HANDLING_HELPERS \
	-s EXCEPTION_CATCHING_ALLOWED=['we only want to allow exception handling in side modules'] \
	-sEXPORTED_RUNTIME_METHODS='wasmTable,ERRNO_CODES' \
	-s AUTO_JS_LIBRARIES=0 \
	-s AUTO_NATIVE_LIBRARIES=0 \
	-s NODEJS_CATCH_EXIT=0 \
	-s NODEJS_CATCH_REJECTION=0 \
	\
	-lidbfs.js \
	-lnodefs.js \
	-lproxyfs.js \
	-lworkerfs.js \
	-lwebsocket.js \
	-leventloop.js \
	-lhiwire \
	\
	-lGL \
	-legl.js \
	-lwebgl.js \
	-lhtml5_webgl.js \
	-sGL_WORKAROUND_SAFARI_GETCONTEXT_BUG=0
#  -v $(pwd):/src