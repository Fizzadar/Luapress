# Don't overwrite config.lua and remove two env build dirs
rm -rf build/ another_build/

# Build with each env
luapress default --no-cache
luapress dev --no-cache
