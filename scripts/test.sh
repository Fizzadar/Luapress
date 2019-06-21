#!/bin/bash

TESTS=("blog" "gallery" "index" "directories" "envs" "sticky" "lhtml" "etlua")


# Exit on error
set -e

# Update local version
luarocks make

# Loop the tests
for TEST in ${TESTS[*]}; do
    # Filter by first arg if provided
    if [[ "$1" = "" ]] || [[ "$1" = "$TEST" ]]; then
        echo "### Running Luapress test: $TEST"
        echo

        # Go into test dir
        cd "tests/$TEST"

        # A local test.sh in the test dir overrides the "default" test
        if [ -f "test.sh" ]; then
            sh test.sh
        else
            if [ -f "cleanup_test.sh" ]; then
                sh cleanup_test.sh
            else
                # Remove build/
                rm -rf build/ templates/ inc/
            fi

            # Autogenerate config.lua & build site
            luapress init "/tests/$TEST/build"
            luapress
        fi

        # Back up to Luapress root
        cd ../..
        echo
    fi
done

echo "--> Tests complete!"
exit 0
