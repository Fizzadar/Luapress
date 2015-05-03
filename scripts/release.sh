#!/bin/sh

VERSION=`cat press.lua | grep config.version | grep -oEi "[0-9]+\.[0-9]+\.[0-9]+"`

echo "# Luapress"
echo "# Releasing: v$VERSION"

git tag -a "v$VERSION" -m "v$VERSION"
git push --tags

echo "# Done!"
