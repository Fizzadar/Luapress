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
+ The inc/ directory will be copied to build/inc/, and your template inc to build/inc/template

## License

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
                       Version 2, December 2004 
    
    Copyright (C) 2013 Nick Barrett <nick@oxygem.com>
    
    Everyone is permitted to copy and distribute verbatim or modified 
    copies of this license document, and changing it is allowed as long 
    as the name is changed. 
    
               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
    
     0. You just DO WHAT THE FUCK YOU WANT TO.