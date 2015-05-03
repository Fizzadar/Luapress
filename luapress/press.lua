-- Luapress
-- File: luapress/press.lua
-- Desc: public API for Luapress

local os = os
local io = io
local print = print
local pairs = pairs
local tonumber = tonumber
local table = table

local lfs = require('lfs')

local util = require('luapress.util')
local template = require('luapress.template')


local function build(directory, config)
    -- Setup our global template values
    template:set('title', config.title)
    template:set('url', config.url)

    -- Load the relevant template files
    if config.print then print('[1] Loading templates') end
    local templates = util.load_templates(directory .. '/templates/' .. config.template)

    -- Load the posts
    if config.print then print('[2] Loading posts') end
    local posts = util.load_markdowns(directory .. '/posts', config)
    -- Sort by time
    table.sort(posts, function(a, b)
        return tonumber(a.time) > tonumber(b.time)
    end)

    -- Load the pages
    if config.print then print('[3] Loading pages') end
    local pages = util.load_markdowns(directory .. '/pages', config)
    -- Sort by order
    table.sort(pages, function(a, b)
        return (tonumber(a.order) or 0) < (tonumber(b.order) or 0)
    end)

    -- Build the archive page (all posts)
    if #posts > 0 then
        template:set('posts', posts)
        template:set('page', {title = 'Archive'})
        table.insert(pages, {
            link = 'Archive' .. (config.link_dirs and '' or '.html'),
            title = 'Archive',
            time = os.time(),
            content = template:process(templates.archive)
        })
    end

    -- Build the posts
    if config.print then print('[4] Building ' .. (config.cache and 'new ' or '') .. 'posts') end
    template:set('single', true)
    -- Page links shared between all posts
    template:set('page_links', util.page_links(pages, nil, config))

    for _, post in pairs(posts) do
        local dest_file = util.ensure_destination(directory, 'posts', post.link, config)

        -- Attach the post & output the file
        template:set('post', post)
        util.write_html(dest_file, post, 'post', templates, config)
    end

    -- Build the pages
    if config.print then print('[5] Building ' .. (config.cache and 'new ' or '') .. 'pages') end
    template:set('single', false)

    for _, page in pairs(pages) do
        local dest_file = util.ensure_destination(directory, 'pages', page.link, config)

        -- We're a page, so change up page_links
        template:set('page_links', util.page_links(pages, page.link, config))
        template:set('page', page)

        -- Output the file
        util.write_html(dest_file, page, 'page', templates, config)
    end
    template:set('page', false)

    -- Build the indexes
    if config.print then print('[6] Building index pages') end
    -- Page links shared between all indexes
    template:set('page_links', util.page_links(pages, nil, config))

    -- Iterate to generate indexes
    local index = 1
    local count = 0
    local output = ''
    for k, post in pairs(posts) do
        -- Add post to output, increase count
        template:set('post', post)
        output = output .. template:process(templates.post)
        count = count + 1

        -- If we have n posts or are on last post, create current index, reset
        if count == config.posts_per_page or k == #posts then
            -- Pick index file, open
            local f, err
            if index == 1 then
                f, err = io.open(directory .. '/build/index.html', 'w')
            else
                f, err = io.open(directory .. '/build/index' .. index .. '.html', 'w')
            end
            if not f then error(err) end

            -- Work out previous page
            if index > 1 then
                if index == 2 then
                    template:set('previous_page', 'index.html')
                else
                    template:set('previous_page', 'index' .. index - 1 .. '.html')
                end
                -- Ensure this is false
                template:set('home', false)
            else
                -- We are page 1!
                template:set('previous_page', false)
                -- Useful!
                template:set('home', true)
            end
            -- Work out next page
            if #posts > k then
                template:set('next_page', 'index' .. index + 1 .. '.html')
            else
                template:set('next_page', false)
            end

            -- Create and write output
            output = template:process(templates.header) .. output .. template:process(templates.footer)
            local result, err = f:write(output)
            if not result then error(err) end
            f:close()

            -- Reset & close f
            count = 0
            output = ''
            if config.print then print('\tindex ' .. index) end
            index = index + 1
        end
    end

    -- Build the RSS of last 10 posts
    if config.print then print('[7] Building RSS') end
    local rssposts = {}
    for k, post in pairs(posts) do
        if k <= 10 then
            if post.excerpt then post.excerpt = post.excerpt:gsub('<[^>]+/?>', ' '):gsub('</[^>]+>', ' '):gsub('\n', '') end
            post.title = post.title:gsub('%p', '')
            table.insert(rssposts, post)
        else
            break
        end
    end
    if #rssposts > 0 then
        template:set('posts', rssposts)
        local rss = template:process(templates.rss.content)
        local f, err = io.open(directory .. '/build/index.xml', 'w')
        if not f then error(err) end
        local result, err = f:write(rss)
        if not result then error(err) end
    end

    -- Copy inc directories
    if config.print then print('[8] Copying inc files') end
    util.copy_dir(directory .. '/inc/', directory .. '/build/inc/')
    util.copy_dir(
        directory .. '/templates/' .. config.template .. '/inc/',
        directory .. '/build/inc/template/'
    )

    return true
end


local function make_skeleton(root, url)
    -- Make directories
    for _, directory in ipairs({
        'posts', 'pages', 'inc',
        'build', 'build/posts', 'build/pages', 'build/inc', 'build/inc/template',
        'templates', 'templates/default', 'templates/default/inc'
    }) do
        lfs.mkdir(root .. '/' .. directory)
    end

    -- Copy/write the default template
    local templates = require('luapress.default_template')
    for file, contents in pairs(templates) do
        local f, err = io.open(root .. '/templates/default/' .. file, 'w')
        if err then return false, err end
        local status, err = f:write(contents)
        if err then return false, err end
        f:close()
    end

    -- Basic config template
    local config_code = [[
-- Autogenerated by Luapress
local config = {
    -- Blog base url
    url = ']] .. url .. [[',
    -- Blog title
    title = 'A Lone Ship',
    -- Template name
    template = 'default',
    -- Posts per page
    posts_per_page = 2,
    -- Link directories not files
    link_dirs = true
}

return config
]]

    -- Write the config file
    local f, err = io.open(root .. '/config.lua', 'w')
    if err then return false, err end
    local status, err = f:write(config_code)
    if err then return false, err end
    f:close()
end


-- Export
return {
    build = build,
    make_skeleton = make_skeleton
}
