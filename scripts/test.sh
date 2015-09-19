#!/bin/sh

TESTS=("blog" "gallery" "index" "directories")

for TEST in ${TESTS[*]}; do
    if [[ "$1" = "" ]] || [[ "$1" = "$TEST" ]]; then
        echo "#"
        echo "# Running test: $TEST"
        echo "#"
        cd "tests/$TEST"
        rm -rf build/
        luapress init "/tests/$TEST/index"
        luapress
        cd ../..
        echo
    fi
done
