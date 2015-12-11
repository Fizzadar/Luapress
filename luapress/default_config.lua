-- Luapress
-- File: luapress/default_config.lua
-- Desc: the default config we use to generate local config.lua's

local config = {
    -- Url
    url = nil,
    -- Build to this directory
    build_dir = 'build',

    -- Environments
    envs = {
        -- Eg:
        -- dev = {
        --     -- Both optional:
        --     url = 'http://localhost',
        --     build_dir = 'build'
        -- }
    },

    -- Blog title
    title = 'A Lone Ship',

    -- Template name
    template = 'default',

    -- Posts per page
    posts_per_page = 5,

    -- Separator to replace --MORE-- instances with
    more_separator = '',

    -- Link directories not files
    -- (ie /posts/<name>/index.html over /posts/<name>.html)
    link_dirs = true,

    -- Generate pages at /pages/<name>
    pages_dir = 'pages',
    -- Generate posts at /posts/<name>
    posts_dir = 'posts',

    -- Select a page as the landing page (optional, no path or suffix)
    -- this will only come into effect if there are no posts (see force_index below).
    index_page = nil,
    -- Force the above even when there are posts, this disables blog index creation but
    -- the archive will still be generated as an index of posts.
    force_index_page = false,

    -- Change the title of the archive page
    archive_title = 'Archive',

    -- Select a page to appear on index.html before any posts (optional, no path or suffix)
    sticky_page = nil,

    -- Use lhtml parser by default (other options: 'mustache')
    template_type = 'lhtml',
}

return config
