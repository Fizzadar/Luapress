# WIP (v3.0)

Breaking:

+ Rename `config.index` -> `config.index_page`
+ Change default `config.pages_dir` -> `page`
+ Change default `config.posts_dir` -> `post`

The rest:

+ Add `config.force_index_page` to create index form page even when posts exist
+ Add `config.sticky_page` to have a page appear at the top of index
+ Add `config.archive_title` to change the title of the archive page
+ Add support for multiple (url, build_dir) environments
+ Add default config, so local config can be sparse
+ Add ID attribute to `<hX>` tags in markdown lib
+ Fix escaping for post & gallery RSS content
+ Rename `press.lua` -> `luapress.lua`
+ Remove `alt_getopt` and handle args manually

# 2.1.1

+ Add `config.posts_dir` and `config.pages_dir`

# 2.1.0

Many thanks to GitHub user w-oertl for contributing most of this release.

+ Add crosslink capability [posts|pages/NAME]
+ If no posts and pages, use first post as index, or link.index
+ Plugin support(!) & gallery plugin
+ Move default template into install path and copy on init
+ Add tests

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
