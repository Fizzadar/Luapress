#!/bin/sh

TESTS=("blog" "gallery" "index")

for TEST in ${TESTS[*]}; do
    echo "#"
    echo "# Running test: $TEST"
    echo "#"
    cd "tests/$TEST"
    rm -rf build/
    luapress init "/tests/$TEST/index"
    luapress
    cd ../..
    echo
done
