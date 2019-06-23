-- Luapress
-- File: luapress/default_config.lua
-- Desc: the default config we use to generate local config.lua's


local function get_permalink(item)
    return item.name:gsub(' ', '_')
end


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

    -- Format functions for permalinks (dir names or html filenames)
    get_page_permalink = get_permalink,
    get_post_permalink = get_permalink,

    -- Link directories not files
    -- (ie /posts/<permalink>/index.html over /posts/<permalink>.html)
    link_dirs = true,

    -- Generate pages at /pages/<permalink>
    pages_dir = 'pages',
    -- Generate posts at /posts/<permalink>
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

    -- Lua date format for template.format_date
    date_format = '%a, %d %B, %Y',

    -- lua-discount options (https://gitlab.com/craigbarnes/lua-discount#options)
    discount_options = {'toc', 'extrafootnote', 'fencedcode'},
}

return config
