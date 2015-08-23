# v2.0.4

+ Add `--build` option to change the directory to build the blog in
+ Fix handling of modification times on posts with manual time defined ($time=)

# v2.0.3

+ Customise the contents of the link `--MORE--` generates

# v2.0.2

+ Fix escaping on `--MORE--`
+ Fix RSS output

# v2.0.1

+ Fix bug with markdown & code blocks

# v2.0.0

+ Lua 5.2 support
+ Rockspec/Luarocks
+ Bin executable
+ `luapress init <url>` functionality
+ Rewritten, broken up into utils

# v1.1.2

+ Add $=url support to posts

# v1.1.1

+ Fix bug in cache: empty archive and/or missing page links
    * fixed by always loading pages/posts, cache still prevents writing them if no change

# v1.1.0

+ Start log
