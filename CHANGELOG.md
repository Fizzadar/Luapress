# v4.0 (WIP)

Breaking:

+ Only parse `$key=value` lines at the top of markdown files

The rest:

+ Add `toc` support (`$=toc` in post or `page.toc` in template)


# v3.5.2

+ Fix for Lua 5.1 (`unpack` not `table.unpack`)

# v3.5.1

+ @yuigoto fix `package.path` on Windows 10

# v3.5

+ Replace `markdown.lua` with `lua-discount`
+ Add `discount_options` configuration setting
+ Remove caching/`--no-cache` over-optimisation
+ Lua 5.3 support
+ @paragasu Support for `.markdown` files
+ @exelotl fixes for copying template directory on Windows
+ @exelotl fix link to docs
+ @hrsantiago fix break in `lhtml`

# v3.4

+ Support for newer Lua versions
+ Support for non English languages

# v3.3.1

+ Fix images and emails in markdown
+ Make cache work with multiple envs

# v3.3

+ Add `previous_post` and `next_post` template variables for posts
+ Fix `config.link_dirs` when set to `false`

# v3.2

+ `--watch` now looks for template changes
+ Add consistent `format_date` function for both mustache/lhtml templates:
+ Add `config.date_format`

# v3.1

+ Add support for `.mustache` templates
+ Default new sites to use `.mustache` build in template
+ Add `--lhtml` flag to init to create sites with the old `.lhtml` template
+ Fix `.lhtml` templates which print '-'

# v3.0

Breaking:

+ Rename `config.index` -> `config.index_page`
+ Change CLI arg `--nocache` -> `--no-cache`

The rest:

+ Add support for multiple (url, build_dir) environments
+ Add `config.force_index_page` to create index form page even when posts exist
+ Add `config.sticky_page` to have a page appear at the top of index
+ Add `config.archive_title` to change the title of the archive page
+ Add `--watch` command line to rebuild on changes to posts/ & pages/ (no Windows support :()
+ Add ID attribute to `<hX>` tags in markdown lib
+ Add $raw$...$/raw$ syntax to disable Markdown extras
+ Add default config, so local config can be sparse
+ Fix escaping for post & gallery RSS content
+ Rename `press.lua` -> `luapress.lua`
+ Remove `alt_getopt` and handle args manually
+ Nicer (colored, where possible) terminal output


# v2.1.1

+ Add `config.posts_dir` and `config.pages_dir`

# v2.1.0

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
