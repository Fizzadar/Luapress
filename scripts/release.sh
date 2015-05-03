#!/bin/sh

VERSION=`cat luapress/config.lua | grep version | grep -oEi "[0-9]+\.[0-9]+\.[0-9]+"`

echo "# Luapress"
echo "# Releasing: v$VERSION"

git tag -a "v$VERSION" -m "v$VERSION"
git push --tags

echo "# Done!"
