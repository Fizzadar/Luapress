# Remove build
rm -rf build/

# Init Luapress site with LHTML enabled
luapress init "/tests/lhtml/build" --lhtml

# Build as normal
luapress --no-cache
