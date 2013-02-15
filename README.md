#Luapress

Luapress is *yet another* static blog generator, written in Lua. This blog is it's testing ground.

**Github link:** [github.com/Fizzadar/Luapress](http://github.com/Fizzadar/Luapress)

**Requirements:**

+ Lua5.1/LuaJIT2.0
+ LuaFileSystem ([keplerproject.github.com/luafilesystem](http://keplerproject.github.com/luafilesystem)) (*luarocks install luafilesystem*)

**How-To:**

+ Edit config.lua
+ Drop markdown (.md) files in posts/ and pages/
+ Run "lua luapress.lua" from shell
+ Copy contents of build/ to web

**Options & Notes:**

+ Add "all" to the end of the shell command to re-build all pages
+ The inc/ directory will be copied to build/inc/, and your template inc to build/inc/template/

**To-Do:**

+ RSS Generation
+ Excerpt for index pages?