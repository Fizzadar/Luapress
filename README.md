# Luapress v2.1

Luapress is *yet another* static ~~blog~~ site generator, written in Lua, with posts in markdown. Now with single page and plugin support.

## Install

`luarocks install luapress`

## How-To

```
Luapress v2

Usage:
    luapress [<url>]
    luapress [--build <dir>] [--nocache] [<url>]
    luapress init <url>
    luapress --help
```

+ Create an empty directory, cd into it
+ Run `luapress init` to create the base config/directories
+ Drop markdown files in `posts/` and `pages/`
+ Run `luapress`
+ Copy the contents of `build/` to web

## Post/page markdown extras

+ Set `$key=value` in posts for custom data (use `<?=self:get('post').key ?>` in template)
+ Set `$time=time_in_epoch_seconds` or `$date=day/month/year` to customize post time (default file update time)
+ Use `--MORE--` to generate a excerpt/read-more link in posts
+ Use `[=pages|posts/NAME]` to generate crosslinks between posts/pages
+ Use `$! NAME arg, arg, arg !$` to use plugins in posts/pages
+ In pages set `$order=number` to determine page ordering in links list
+ Hide pages from the link list with `$hidden=true`

## Options & notes

+ Set `config.link_dirs = false` in `config.lua` to have posts & pages generated at `/name.html` rather than `/name/index.html`
+ The `inc/` directory will be copied to `build/inc/`, and your template inc to `build/inc/template`
+ Add `--nocache` before the URL to ignore caching (for template dev)

## Example

I'm using it for my blog, [Pointless Ramblings](http://pointlessramblings.com).
