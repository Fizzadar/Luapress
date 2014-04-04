#Luapress v1.0.2

Luapress is *yet another* static blog generator, written in Lua. This blog is it's testing ground.

**Requirements:**

+ Lua5.1/LuaJIT2.0
+ LuaFileSystem [keplerproject.github.com/luafilesystem](http://keplerproject.github.com/luafilesystem) (*luarocks install luafilesystem*)

**How-To:**

+ Download [an Luapress release](https://github.com/Fizzadar/Luapress/releases) or clone this development repo
+ Rename `config.example.lua` => `config.lua`
+ Set url to your live or staging location
+ Drop markdown (.md) files in posts/ and pages/
+ Run `./press.lua <optional url http://example.com>` from shell
+ Copy contents of build/ to web

**Options & Notes:**

+ Set `config.link_dirs = true` in `config.lua` to have posts & pages generated at `/name/index.html` rather than `/name.html`
+ The `inc/` directory will be copied to `build/inc/`, and your template inc to `build/inc/template`
+ Set `$key=value` in posts for custom data (use `<?=self:get( 'post' ).key ?>` in template)
+ Set `$time=time_in_epoch` or `$date=day/month/year` to customize post time (default file update time)
+ With pages set `$order=number` to determine page ordering in links list
+ Hide pages from the link list with `$hidden=true`

**Example:**

I'm using it for my blog, [Pointless Ramblings](http://pointlessramblings.com).