#!/bin/bash

# Script to compile main.c and functions.c
# gcc -o programa -I~/Desktop/Lar/src/includes ~/Desktop/Lar/main.c ~/Desktop/Lar/src/fn/functions.c
# gcc -o lar -Iincludes main.c src/*/*.c -I/usr/include/webkitgtk-4.0 -ljavascriptcoregtk-4.0

# zig run main.zig -I/usr/include/webkitgtk-4.0 -ljavascriptcoregtk-4.0 -lc

# zig build-exe index.zig -I/usr/include/webkitgtk-4.0 -ljavascriptcoregtk-4.0 -lc


# ./lar run ./index.js

zig build

cd ./zig-out/bin/ 

./lar run x.js               

cd ../../