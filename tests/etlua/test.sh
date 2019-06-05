# Remove build
rm -rf build/ templates/ inc/

# Init Luapress site with template set to etlua
luapress init "/tests/etlua/build" --template "etlua"

# Build as normal
luapress
