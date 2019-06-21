# Don't overwrite config.lua and remove two env build dirs
rm -rf build/ another_build/ templates/ inc/

# Init Luapress site
luapress init "/tests/envs/build"

# Build with each env
luapress default
luapress dev
