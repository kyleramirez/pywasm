FROM emscripten/emsdk:3.1.58-arm64
# Install dependencies
RUN apt-get update && apt-get install -yq build-essential libffi-dev autoconf automake libtool pkg-config less nano python3.11-dev
RUN apt-get autoremove --purge -yq
# Patch emscripten
ENV EMSCRIPTEN_VERSION=3.1.58
WORKDIR /emsdk/upstream/emscripten
COPY ./empatches ./patches
RUN cat ./patches/*.patch | patch -p1 --verbose
WORKDIR /emsdk
RUN ./emsdk install --build=Release $EMSCRIPTEN_VERSION ccache-git-emscripten-64bit
RUN ./emsdk activate --embedded --build=Release $EMSCRIPTEN_VERSION
# Download cpython
ENV PYVERSION=3.11.9
ENV PYTARBALL=/tmp/Python-${PYVERSION}.tgz
ENV PYTHON_ARCHIVE_URL=https://www.python.org/ftp/python/${PYVERSION}/Python-${PYVERSION}.tgz
RUN wget -q -O $PYTARBALL $PYTHON_ARCHIVE_URL
# Patch cpython
ENV CPYTHONROOT=/opt/cpython
ENV PYBUILD=$CPYTHONROOT/Python-${PYVERSION}
RUN mkdir -p $CPYTHONROOT; tar -C $CPYTHONROOT -xf $PYTARBALL
WORKDIR $PYBUILD
COPY ./cypatches ./patches
RUN cat ./patches/*.patch | patch -p1
# Generate Makefile
ENV PYINSTALL=$CPYTHONROOT/install/Python-${PYVERSION}
# PYTHON_CFLAGS="-O2 -g0 -fPIC -DPY_CALL_TRAMPOLINE"
RUN CONFIG_SITE=./Tools/wasm/config.site-wasm32-emscripten\
  READELF=true\
  emconfigure \
  ./configure \
  CFLAGS="-O2 -g0 -fPIC -DPY_CALL_TRAMPOLINE"\
  CPPFLAGS="-sUSE_BZIP2=1 -sUSE_ZLIB=1" \
  PLATFORM_TRIPLET="wasm32-emscripten"\
  --without-pymalloc\
  --disable-shared\
  --disable-ipv6\
  --enable-big-digits=30\
  --enable-optimizations\
  --host=wasm32-unknown-emscripten\
  --with-emscripten-target=node\
  --enable-wasm-dynamic-linking\
  --build=$(./config.guess)\
  --prefix=$PYINSTALL\
  --with-build-python=$(which python3.11)
# Copy local setup
COPY ./Setup.local $PYBUILD/Modules/
# Install libffi
ENV FFIBUILD=/opt/libffi
ENV LIBFFIREPO=https://github.com/libffi/libffi
ENV LIBFFI_COMMIT=f08493d249d2067c8b3207ba46693dd858f95db3
RUN mkdir $FFIBUILD
WORKDIR $FFIBUILD
RUN git init\
  && git fetch --depth 1 $LIBFFIREPO $LIBFFI_COMMIT\
  && git checkout FETCH_HEAD\
  && ./testsuite/emscripten/build.sh --wasm-bigint\
  && make install
RUN cp $FFIBUILD/target/include/*.h $PYBUILD/Include/
RUN mkdir -p $PYINSTALL/lib
RUN cp $FFIBUILD/target/lib/libffi.a $PYINSTALL/lib/
# Build emscripten python
WORKDIR $PYBUILD
COPY ./Setup.local $PYBUILD/Modules/
RUN make regen-frozen
RUN emmake make CROSS_COMPILE=yes -j$(nproc)
# Install Node via NVM
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN source /root/.bashrc && nvm install 20
SHELL ["/bin/bash", "--login", "-c"]


# # Build python
# WORKDIR $PYBUILD

# RUN CONFIG_SITE=./Tools/wasm/config.site-wasm32-emscripten\
#     READELF=true\
#     emconfigure ./configure\
#     CFLAGS="${PYTHON_CFLAGS}"\
#     CPPFLAGS="-sUSE_BZIP2=1 -sUSE_ZLIB=1"\
#     PLATFORM_TRIPLET="wasm32-emscripten"\
#     --without-pymalloc\
#     --disable-shared\
#     --disable-ipv6\
#     --enable-big-digits=30\
#     --enable-optimizations\
#     --host=wasm32-unknown-emscripten\
#     --build=$(../../config.guess)\
#     --prefix=$PYINSTALL \
#     --with-build-python=$(which python3.11)

# install emcc ports so configure is able to detect the dependencies
# RUN embuilder build zlib bzip2
# # Install libffi-emscripten
# ENV BUILDDIR=/tmp/libffi-emscripten
# RUN git clone --depth=1 https://github.com/hoodmane/libffi-emscripten.git /tmp/libffi-emscripten
# WORKDIR /tmp/libffi-emscripten
# COPY ./build.sh /tmp/libffi-emscripten
# RUN ./build.sh
# RUN rm -rf /tmp/libffi-emscripten
# ####################################################################################################
# # Install Node via NVM
# SHELL ["/bin/bash", "--login", "-i", "-c"]
# RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# RUN source /root/.bashrc && nvm install 20
# SHELL ["/bin/bash", "--login", "-c"]
# ####################################################################################################
# # Checkout Python 3.11.9
# RUN git clone --depth 1 --branch v3.11.9 https://github.com/python/cpython.git /opt/cpython
# RUN echo '*shared*\n_ctypes _ctypes/_ctypes.c _ctypes/callbacks.c _ctypes/callproc.c _ctypes/stgdict.c _ctypes/cfield.c -lffi' >> /opt/cpython/Modules/Setup.local
# # Build the "build" python, which will be used to build the cross-compiled python
# RUN mkdir -p /opt/cpython/builddir/build
# WORKDIR /opt/cpython/builddir/build
# RUN ../../configure -C --enable-optimizations
# RUN make -j$(nproc)
# ####################################################################################################
# # Build emscripten python
# # RUN emcc --clear-cache
# RUN mkdir -p /opt/cpython/builddir/emscripten-node
# RUN cp /opt/libffi-emscripten/lib/libffi.a /emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
# RUN cp /opt/libffi-emscripten/lib/libffi.la /emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
# RUN cp /opt/libffi-emscripten/lib/pkgconfig/libffi.pc /emsdk/upstream/emscripten/cache/sysroot/lib/pkgconfig
# RUN cp /opt/libffi-emscripten/include/ffi* /emsdk/upstream/emscripten/cache/sysroot/include/
# WORKDIR /opt/cpython/builddir/emscripten-node
# # ENV LIBFFI_INCLUDEDIR="/opt/libffi-emscripten/include"
# # ENV LIBFFI_CFLAGS="-I/opt/libffi-emscripten/include"
# # ENV LIBFFI_LIBS="-L/opt/libffi-emscripten/lib -lffi"
# ENV CONFIGURE_CPPFLAGS="-I/opt/libffi-emscripten/include"
# ENV CONFIGURE_LDFLAGS="-L/opt/libffi-emscripten/lib"
# ENV PKG_CONFIG_PATH="/opt/libffi-emscripten"
# RUN CONFIG_SITE=../../Tools/wasm/config.site-wasm32-emscripten\
#   emconfigure ../../configure -C\
#   --host=wasm32-unknown-emscripten\
#   # LIBFFI_INCLUDEDIR="/opt/libffi-emscripten/include"\
#   # LIBFFI_CFLAGS="-I/opt/libffi-emscripten/include"\
#   # LIBFFI_LIBS="-L/opt/libffi-emscripten/lib -lffi"\
#   CONFIGURE_CPPFLAGS="-I/opt/libffi-emscripten/include"\
#   CONFIGURE_LDFLAGS="-L/opt/libffi-emscripten/lib"\
#   PKG_CONFIG_PATH="/opt/libffi-emscripten"\
#   --build=$(../../config.guess)\
#   --with-emscripten-target=node\
#   --with-build-python=$(pwd)/../build/python\
#   --enable-wasm-dynamic-linking\
#   --enable-optimizations\
#   "$@"
# RUN emmake make -j$(nproc)
