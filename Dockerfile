# Based on pyodide 0.25.1
# Install Amd64 Version
FROM node:20.1.0-buster-slim@sha256:34f21a675893db99e6225e3d31b83d2da48a0d95a9f379e257b7fa9ccc104299 AS node-image
FROM python:3.11.3-slim-buster@sha256:48b0146e8f85d6325b46073250a8ed9ec9d156da45d6c2821d5d0f9ad1960fb4
# Install dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends\
  automake\
  autotools-dev\
  build-essential\
  bzip2\
  ccache\
  cmake\
  dejagnu\
  f2c\
  g++\
  gfortran\
  git\
  gnupg2\
  jq\
  less\
  libdbus-glib-1-2\
  libltdl-dev\
  libtool\
  make\
  nano\
  ninja-build\
  patch\
  pkg-config\
  prelink\
  sqlite3\
  sudo\
  swig\
  texinfo\
  unzip\
  wget\
  xxd\
  xz-utils\
  && rm -rf /var/lib/apt/lists/*
RUN apt-get autoremove --purge -yq
# Install Emscripten
ENV EMSCRIPTEN_VERSION=3.1.46
WORKDIR /
RUN git clone --depth 1 https://github.com/emscripten-core/emsdk.git
RUN cd emsdk && ./emsdk install --build=Release $EMSCRIPTEN_VERSION
# Patch emscripten
WORKDIR /emsdk/upstream/emscripten
COPY ./empatches ./patches
RUN cat ./patches/*.patch | patch -p1 --verbose
# Rebuild emscripten
WORKDIR /emsdk
RUN ./emsdk install --build=Release $EMSCRIPTEN_VERSION ccache-git-emscripten-64bit
RUN ./emsdk activate --embedded --build=Release $EMSCRIPTEN_VERSION
# Unpack Python tarball
ENV PYVERSION=3.11.3
ENV PYTARBALL=/tmp/Python-${PYVERSION}.tgz
ENV PYTHON_ARCHIVE_URL=https://www.python.org/ftp/python/${PYVERSION}/Python-${PYVERSION}.tgz
ENV CPYTHONROOT=/opt/cpython
ENV PYBUILD=$CPYTHONROOT/build/Python-${PYVERSION}
ENV PYINSTALL=$CPYTHONROOT/install/Python-${PYVERSION}
WORKDIR $PYBUILD
RUN wget -q -O $PYTARBALL $PYTHON_ARCHIVE_URL
RUN tar -C $PYBUILD --strip-components=1 -xf $PYTARBALL
# Patch cpython
COPY ./cypatches ./patches
RUN cat ./patches/*.patch | patch -p1
# Generate Makefile
WORKDIR $PYBUILD
SHELL ["/bin/bash", "-c"]
RUN source /emsdk/emsdk_env.sh &&\
  embuilder build zlib bzip2
RUN source /emsdk/emsdk_env.sh &&\
  CONFIG_SITE=./Tools/wasm/config.site-wasm32-emscripten\
  READELF=true\
  emconfigure ./configure\
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
  --build=$(./config.guess)\
  --prefix=$PYINSTALL\
  --with-build-python=$(which python3.11)
# Build emscripten python
ENV LIB=libpython3.11.a
# RUN make regen-frozen
RUN source /emsdk/emsdk_env.sh &&\
  emmake make CROSS_COMPILE=yes -j$(nproc)
# At this point, you are building python without ctypes, since that is a huge pain in the ass
# where you got nowhere after over a week of trying every configuration under the sun
# So at this point, you can copy over your version of the python build to where nuitka
# can find it, and then use that python, plus emcc to compile the build, and then hopefully
# add some externs to the C to add some proper methods to call the python code.
