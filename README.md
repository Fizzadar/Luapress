#Luapress

Luapress is *yet another* static blog generator, written in Lua.

**Requirements:**

+ Lua5.1/LuaJIT2.0
+ LuaFileSystem ([http://keplerproject.github.com/luafilesystem](http://keplerproject.github.com/luafilesystem))

**How-To:**

+ Drop markdown (.md) files in posts/ and pages/
+ Run "lua luapress.lua" from shell
+ Copy contents of build/ to web

**Options & Notes:**

+ Add "all" to the end of the shell command to re-build all pages
+ The inc/ directory will be copied to build/inc/. Put poss content & template images/css here

**To-Do:**

+ RSS Generation