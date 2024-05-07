FROM emscripten/emsdk:3.1.59-arm64
# Install dependencies
RUN apt-get update && apt-get install -yq build-essential libffi-dev autoconf automake libtool pkg-config less nano
RUN apt-get autoremove --purge -yq
# install emcc ports so configure is able to detect the dependencies
RUN embuilder build zlib bzip2
# Install libffi-emscripten
ENV BUILDDIR=/tmp/libffi-emscripten
RUN git clone --depth=1 https://github.com/hoodmane/libffi-emscripten.git /tmp/libffi-emscripten
WORKDIR /tmp/libffi-emscripten
COPY ./build.sh /tmp/libffi-emscripten
RUN ./build.sh
RUN rm -rf /tmp/libffi-emscripten
####################################################################################################
# Install Node via NVM
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN source /root/.bashrc && nvm install 20
SHELL ["/bin/bash", "--login", "-c"]
####################################################################################################
# Checkout Python 3.11.9
RUN git clone --depth 1 --branch v3.11.9 https://github.com/python/cpython.git /opt/cpython
RUN echo '*shared*\n_ctypes _ctypes/_ctypes.c _ctypes/callbacks.c _ctypes/callproc.c _ctypes/stgdict.c _ctypes/cfield.c -lffi' >> /opt/cpython/Modules/Setup.local
# Build the "build" python, which will be used to build the cross-compiled python
RUN mkdir -p /opt/cpython/builddir/build
WORKDIR /opt/cpython/builddir/build
RUN ../../configure -C --enable-optimizations
RUN make -j$(nproc)
####################################################################################################
# Build emscripten python
# RUN emcc --clear-cache
RUN mkdir -p /opt/cpython/builddir/emscripten-node
RUN cp /opt/libffi-emscripten/lib/libffi.a /emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
RUN cp /opt/libffi-emscripten/lib/libffi.la /emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
RUN cp /opt/libffi-emscripten/lib/pkgconfig/libffi.pc /emsdk/upstream/emscripten/cache/sysroot/lib/pkgconfig
RUN cp /opt/libffi-emscripten/include/ffi* /emsdk/upstream/emscripten/cache/sysroot/include/
WORKDIR /opt/cpython/builddir/emscripten-node
# ENV LIBFFI_INCLUDEDIR="/opt/libffi-emscripten/include"
# ENV LIBFFI_CFLAGS="-I/opt/libffi-emscripten/include"
# ENV LIBFFI_LIBS="-L/opt/libffi-emscripten/lib -lffi"
ENV CONFIGURE_CPPFLAGS="-I/opt/libffi-emscripten/include"
ENV CONFIGURE_LDFLAGS="-L/opt/libffi-emscripten/lib"
ENV PKG_CONFIG_PATH="/opt/libffi-emscripten"
RUN CONFIG_SITE=../../Tools/wasm/config.site-wasm32-emscripten\
  emconfigure ../../configure -C\
  --host=wasm32-unknown-emscripten\
  # LIBFFI_INCLUDEDIR="/opt/libffi-emscripten/include"\
  # LIBFFI_CFLAGS="-I/opt/libffi-emscripten/include"\
  # LIBFFI_LIBS="-L/opt/libffi-emscripten/lib -lffi"\
  CONFIGURE_CPPFLAGS="-I/opt/libffi-emscripten/include"\
  CONFIGURE_LDFLAGS="-L/opt/libffi-emscripten/lib"\
  PKG_CONFIG_PATH="/opt/libffi-emscripten"\
  --build=$(../../config.guess)\
  --with-emscripten-target=node\
  --with-build-python=$(pwd)/../build/python\
  --enable-wasm-dynamic-linking\
  --enable-optimizations\
  "$@"
RUN emmake make -j$(nproc)
