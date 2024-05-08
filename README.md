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


- Illinois $120
- Investment account tax form
- Fundrise tax form
- Robinhood tax form