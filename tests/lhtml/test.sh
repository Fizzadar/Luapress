# Remove build
rm -rf build/ templates/ inc/

# Init Luapress site with LHTML enabled
luapress init "/tests/lhtml/build" --template "lhtml"

# Build as normal
luapress
