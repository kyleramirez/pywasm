from ctypes import POINTER

def main():
    print(type(POINTER))
    print("Hello, World!")
    return 0

# emcc libpython3.11.a main.py -o main.js
