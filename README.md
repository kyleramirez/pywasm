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
