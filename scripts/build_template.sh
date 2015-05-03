#!/bin/sh

OUT='local templates = {'

Makefile() {
    # Read the file, wrapped in a Lua table
    contents="['$1'] = [[`cat template/$1`]],"

    # Append to output
    OUT="$OUT$contents"
}

Makefile 'inc/style.css'
Makefile 'archive.lhtml'
Makefile 'footer.lhtml'
Makefile 'header.lhtml'
Makefile 'page.lhtml'
Makefile 'post.lhtml'

OUT="$OUT} return templates"

echo "$OUT" > luapress/default_template.lua
echo 'Template built @ luapress/default_template.lua'
