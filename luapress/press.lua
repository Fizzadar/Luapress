-- Luapress
-- File: luapress/press.lua
-- Desc: public API for Luapress

local os = os
local io = io
local print = print
local ipairs = ipairs
local tonumber = tonumber
local table = table

local lfs = require('lfs')

local util = require('luapress.util')
local template = require('luapress.template')


---
-- Generate one or more index files for all posts, or use
-- one of the pages if no posts are available.
--
local function build_index(pages, posts, templates)

    local index = 1
    local count = 0
    local output = ''

    for k, post in ipairs(posts) do
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
    if #posts == 0 and #pages > 0 then
	local idxpage
	if config.index then
	    -- use specified page
	    for _, page in ipairs(pages) do
		if page.name == config.index then
		    idxpage = page
		    break
		end
	    end
	else
	    -- use first page
	    idxpage = pages[1]
	end

	-- The "copy file" part of util.copy_dir could be refactored into
	-- a separate function and used here.
	if idxpage then
        -- Work out built file location
	    local bdir = config.root .. '/' .. config.build_dir .. '/'
        local filename = bdir .. "pages/" .. idxpage.link
        if config.link_dirs then
            filename = filename .. '/index.html'
        end

	    local f, err = io.open(filename)
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
end


---
-- If any posts are available, build a RSS file
--
local function build_rss(posts, templates)
    if #posts == 0 then return end

    if config.print then print('[7] Building RSS') end
    local rssposts = {}

    for k, post in ipairs(posts) do
    	if k > 10 then
    	    break
    	end

    	if post.excerpt then
    	    post.excerpt = post.excerpt:gsub('<[^>]+/?>', ' '):gsub('</[^>]+>', ' '):gsub('\n', '')
    	end

    	post.title = post.title:gsub('%p', '')
    	rssposts[#rssposts + 1] = post
    end

    template:set('posts', rssposts)
    local rss = template:process(templates.rss)
    local f, err = io.open(config.root .. '/' .. config.build_dir .. '/index.xml', 'w')
    if not f then error(err) end
    local result, err = f:write(rss)
    if not result then error(err) end
    f:close()
end


---
-- This is the main function to generate the static website.
--
local function build()

    -- Setup our global template values
    template:set('title', config.title)
    template:set('url', config.url)

    -- Load template files
    if config.print then print('[1] Loading templates') end
    local templates = util.load_templates()

    -- Load the posts and sort by timestamp
    if config.print then print('[2] Loading posts') end
    local posts = util.load_markdowns('posts', 'post')
    table.sort(posts, function(a, b)
        return tonumber(a.time) > tonumber(b.time)
    end)

    -- Load the pages and sort by order
    if config.print then print('[3] Loading pages') end
    local pages = util.load_markdowns('pages', 'page')
    table.sort(pages, function(a, b)
        return (tonumber(a.order) or 0) < (tonumber(b.order) or 0)
    end)

    -- Build the archive page (all posts) if at least one post exists
    if #posts > 0 then
        template:set('posts', posts)
        template:set('page', {title = 'Archive'})
        table.insert(pages, {
            link = 'Archive' .. (config.link_dirs and '' or '.html'),
            title = 'Archive',
            time = os.time(),
            content = template:process(templates.archive),
	    template = 'page',
	    directory = 'pages',
	    name = 'archive',
        })
    end

    -- Process cross references
    util.process_xref(pages, posts)

    -- Build the posts
    if config.print then print('[4] Building ' .. (config.cache and 'new ' or '') .. 'posts') end
    template:set('single', true)
    -- Page links shared between all posts
    template:set('page_links', util.page_links(pages, nil))

    for _, post in ipairs(posts) do
        local dest_file = util.ensure_destination(post)

        -- Attach the post & output the file
        template:set('post', post)
        util.write_html(dest_file, post, templates)
    end

    -- Build the pages
    if config.print then print('[5] Building ' .. (config.cache and 'new ' or '') .. 'pages') end
    template:set('single', false)
    template:set('have_posts', #posts > 0)

    for _, page in ipairs(pages) do
        local dest_file = util.ensure_destination(page)

        -- We're a page, so change up page_links
        template:set('page_links', util.page_links(pages, page.link))
        template:set('page', page)

        -- Output the file
        util.write_html(dest_file, page, templates)
    end
    template:set('page', false)

    -- Build the indexes
    if config.print then print('[6] Building index pages') end
    -- Page links shared between all indexes
    template:set('page_links', util.page_links(pages, nil))

    -- Iterate to generate indexes
    build_index(pages, posts, templates)

    -- Build the RSS of last 10 posts
    build_rss(posts, templates)

    -- Copy inc directories
    if config.print then print('[8] Copying inc files') end
    util.copy_dir(config.root .. '/inc/', config.root .. '/' .. config.build_dir .. '/inc/')
    util.copy_dir(
        config.root .. '/templates/' .. config.template .. '/inc/',
        config.root .. '/' .. config.build_dir .. '/inc/template/'
    )

    return true
end


---
-- Prepare the build directory with required subdirectories
--
local function make_build()
    for _, sub_directory in ipairs({
        '', 'posts', 'pages', 'inc', 'inc/template'
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
        '', 'posts', 'pages', 'inc', 'templates', 'templates/default',
    }) do
        lfs.mkdir(root .. '/' .. directory)
    end

    -- Copy the default template
    local base = string.gsub(arg[0], "/[^/]-/[^/]-$", "")
    util.copy_dir(base .. '/template/', root .. '/templates/default/')

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
