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


local function build(config)
    -- Setup our global template values
    template:set('title', config.title)
    template:set('url', config.url)

    -- Load the relevant template files
    if config.print then print('[1] Loading templates') end
    local templates = util.load_templates(config.root
    	.. '/templates/' .. config.template)

    -- Load the posts
    if config.print then print('[2] Loading posts') end
    local posts = util.load_markdowns('posts', config)
    -- Sort by time
    table.sort(posts, function(a, b)
        return tonumber(a.time) > tonumber(b.time)
    end)

    -- Load the pages
    if config.print then print('[3] Loading pages') end
    local pages = util.load_markdowns('pages', config)
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
        local dest_file = util.ensure_destination('posts', post.link, config)

        -- Attach the post & output the file
        template:set('post', post)
        util.write_html(dest_file, post, 'post', templates, config)
    end

    -- Build the pages
    if config.print then print('[5] Building ' .. (config.cache and 'new ' or '') .. 'pages') end
    template:set('single', false)
    template:set('have_posts', #posts > 0)

    for _, page in pairs(pages) do
        local dest_file = util.ensure_destination('pages', page.link, config)

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
                f, err = io.open(config.root .. '/' .. config.build_dir .. '/index.html', 'w')
            else
                f, err = io.open(config.root .. '/' .. config.build_dir .. '/index' .. index .. '.html', 'w')
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

    -- No posts at all, but at least one page?  Have an index.html anyway.
    if index == 1 and next(pages) then
	local idxpage
	if config.index then
	    -- use specified page
	    for _, page in pairs(pages) do
		if page.name == config.index then
		    idxpage = page
		    break
		end
	    end
	else
	    -- use first page
	    idxpage = pages[next(pages)]
	end

	-- The "copy file" part of util.copy_dir could be refactored into
	-- a separate function and used here.
	if idxpage then
	    local bdir = config.root .. '/' .. config.build_dir .. '/'
	    local f, err = io.open(bdir .. "pages/" .. idxpage.name .. ".html")
	    if not f then error(err) end
	    local s, err = f:read('*a')
	    if not s then error(err) end
	    f:close()

	    f, err = io.open(bdir .. "index.html", "w")
	    if not f then error(err) end
	    f:write(s)
	    f:close()
	end
    end

    -- Build the RSS of last 10 posts
    if index > 1 then
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
	    local rss = template:process(templates.rss)
	    local f, err = io.open(config.root .. '/' .. config.build_dir .. '/index.xml', 'w')
	    if not f then error(err) end
	    local result, err = f:write(rss)
	    if not result then error(err) end
	end
    end

    -- Copy inc directories
    if config.print then print('[8] Copying inc files') end
    util.copy_dir(config.root .. '/inc/', config.root .. '/' .. config.build_dir .. '/inc/')
    util.copy_dir(
        config.root .. '/templates/' .. config.template .. '/inc/',
        config.root .. '/' .. config.build_dir .. '/inc/template/'
    )

    return true
end


local function make_build(config)
    -- Make main directory
    lfs.mkdir(config.root .. '/' .. config.build_dir)

    -- Make sub directories
    for _, sub_directory in ipairs({
        'posts', 'pages', 'inc', 'inc/template'
    }) do
        lfs.mkdir(config.root .. '/' .. config.build_dir
		.. '/' .. sub_directory)
    end
end


---
-- Create a new site
--
-- @param root  directory where to set up the files
-- @param url  relative URL of the site, i.e. https://host.com/URL
--
local function make_skeleton(root, url)
    -- Make directories
    for _, directory in ipairs({
        '', 'posts', 'pages', 'inc',
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
    link_dirs = true,
    -- Separator to put inside <a id="more"></a> link
    more_separator = '',
    -- Select a page as the landing page (optional, no path or suffix)
    index = nil,
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
    make_skeleton = make_skeleton,
    make_build = make_build
}
