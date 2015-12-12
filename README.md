# Luapress v3.1

Luapress is *yet another* static site generator, written in Lua, with posts in markdown. It's simple, fast and supports both plugins and templates.


## Quick Start

Install with Luarocks:

```
luarocks install luapress
```

Create a new site in some directory (you can optionally specify `--lhtml` to use the LHTML default template over the mustache one):

```
luapress init URL [--lhtml]
```

Drop Markdown files in `posts/` & `pages/` and build with:

```
luapress
```

Now, just upload the contents of `build/` to the web.


## Next Steps

Luapress offers many other features, which are documented on [it's website](http://luapress.org):

+ [Markdown extras](http://luapress.org/#MarkdownExtras)
+ [Config options](http://luapress.org/#ConfigOptions)
+ [Environments](http://luapress.org/#Environments)
+ [Templates](http://luapress.org/#Templates)
+ [Plugins](http://luapress.org/#Plugins)


## Example

I'm using it for my blog, [Pointless Ramblings](http://pointlessramblings.com). The [Luapress website](https://github.com/Fizzadar/luapress.org) itself is also powered by Luapress :).
