#Luapress

Luapress is *yet another* static blog generator, written in Lua. This blog is it's testing ground.

**Github link:** [github.com/Fizzadar/Luapress](http://github.com/Fizzadar/Luapress)

**Requirements:**

+ Lua5.1/LuaJIT2.0
+ LuaFileSystem ([keplerproject.github.com/luafilesystem](http://keplerproject.github.com/luafilesystem)) (*luarocks install luafilesystem*)

**How-To:**

+ Edit rename `config.example.lua` => `config.lua`
+ Drop markdown (.md) files in posts/ and pages/
+ Run `lua luapress.lua` from shell
+ Copy contents of build/ to web

**Options & Notes:**

+ Add "all" to the end of the shell command to re-build all pages
+ Set `config.link_dirs = true` in `config.lua` to have posts & pages generated at `/name/index.html` rather than `/name.html`
+ The `inc/` directory will be copied to `build/inc/`, and your template inc to `build/inc/template`
+ Set `$key=value` in posts for custom data (use `<?=self:get( 'post' ).key ?>` in template)
+ Set `$time=time_in_epoch` or `$date=day/month/year` to customize post time (default file update time)