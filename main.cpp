#include <Python.h>
#include <emscripten.h>

extern "C" {
    extern EMSCRIPTEN_KEEPALIVE int menards() {
        Py_Initialize();
        const char *code = 
            "from ctypes import POINTER"
            "def main():"
            "    print(type(POINTER))";
        PyRun_SimpleString(code);
        Py_Finalize();
        return 0;
    }
}
