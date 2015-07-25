-- Luapress
-- File: luapress/util.lua
-- Desc: internal Luapress utilities!

local os = os
local io = io
local print = print
local pairs = pairs
local error = error
local table = table
local string = string

local lfs = require('lfs')

local markdown = require('luapress.lib.markdown')
local template = require('luapress.template')


-- Writes a header/footer wrapped HTML file depending on the modification time
local function write_html(destination, object, object_type, templates, config)
    -- Check modification time on post & destination files
    local attributes = lfs.attributes(destination)
    if not config.cache or not attributes or object.time > attributes.modification then
        local output = template:process(templates.header, templates[object_type], templates.footer)

        -- Write the file
        f, err = io.open(destination, 'w')
        if not f then error(err) end
        local result, err = f:write(output)
        if not result then error(err) end
        f:close()

        if config.print then print('\t' .. object.title) end
    end
end


-- Returns the destination file given our config
local function ensure_destination(directory, object_type, link, config)
    if config.link_dirs then
        lfs.mkdir(directory .. '/build/' .. object_type .. '/' .. link)
        return 'build/' .. object_type .. '/' .. link .. '/index.html'
    end

    return 'build/' .. object_type .. '/' .. link
end


-- Builds link list based on the currently active page
local function page_links(pages, active, config)
    local output = ''

    for k, page in pairs(pages) do
        if not page.hidden then
            if page.link == active then
                output = output .. '<li class="active"><a href="' .. config.url .. '/pages/' .. active .. '">' .. page.title .. '</a></li>\n'
            else
                output = output .. '<li><a href="' .. config.url .. '/pages/' .. page.link .. '">' .. page.title .. '</a></li>\n'
            end
        end
    end

    return output
end


-- Load markdown files in a directory
local function load_markdowns(directory, config)
    local outs = {}

    for file in lfs.dir(directory) do
        if file:sub(-3) == '.md' then
            local title = file:sub(0, -4)
            file = directory .. '/' .. file
            local attributes = lfs.attributes(file)

            -- Work out title
            local link = title:gsub(' ', '_'):gsub('[^_aA-zZ0-9]', '')
            if not config.link_dirs then link = link .. '.html' end

            -- Get basic attributes
            local out = {
                link = link,
                title = title,
                content = '',
                time = attributes.modification
            }

            -- Now read the file
            local f, err = io.open(file, 'r')
            if not f then error(err) end
            local s, err = f:read('*a')
            if not s then error(err) end

            -- Set $=key's
            s = s:gsub('%$=url', config.url)

            -- Get $key=value's
            for k, v, c, d in s:gmatch('%$([%w]+)=(.-)\n') do
                out[k] = v
                s = s:gsub('%$[%w]+=.-\n', '')
            end

            -- Excerpt
            local start, _ = s:find('--MORE--')
            if start then
                -- Extract the excerpt
                out.excerpt = markdown(s:sub(0, start - 1))
                -- Replace the --MORE--
                s = s:gsub('%-%-MORE%-%-', '<a id="more">&nbsp;</a>')
            end

            out.content = markdown(s)

            -- Date set?
            if out.date then
                local _, _, d, m, y = out.date:find('(%d+)%/(%d+)%/(%d+)')
                out.time = os.time({day = d, month = m, year = y})
            end

            -- Insert to outs
            table.insert(outs, out)
            if config.print then print('\t' .. out.title) end
        end
    end

    return outs
end


-- Loads lhtml templates in a directory
local function load_templates(directory)
    local templates = {}

    for file in lfs.dir(directory) do
        if file:sub(-5) == 'lhtml' then
            local tmpl_name = file:sub(0, -7)
            file = directory .. '/' .. file
            local f, err = io.open(file, 'r')
            if not f then error(err) end
            local s, err = f:read('*a')
            if not s then error(err) end
            f:close()

            templates[tmpl_name] = s
        end
    end

    -- RSS template
    templates.rss = {
        time = 0,
        content = [[
    <?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0">
        <channel>
            <title><?=self:get('title') ?></title>
            <link><?=self:get('url') ?></link>
    <? for k, post in pairs(self:get('posts')) do ?>
            <item>
                <title><?=post.title ?></title>
                <description><?=post.excerpt ?></description>
                <link><?=self:get('url') ?>/posts/<?=post.link ?></link>
                <guid><?=self:get('url') ?>/posts/<?=post.link ?></guid>
            </item>
    <? end ?>
        </channel>
    </rss>
    ]]}

    return templates
end


-- Recursively duplicates a directory
local function copy_dir(directory, destination)
    for file in lfs.dir(directory) do
        if file ~= '.' and file ~= '..' then
            local attributes = lfs.attributes(directory .. file) or {}

            -- Directory?
            if attributes.mode and attributes.mode == 'directory' then
                -- Ensure destination directory
                if not io.open(destination .. file, 'r') then
                    lfs.mkdir(destination .. file)
                end
                copy_dir(directory .. file .. '/', destination .. file .. '/')
            end

            -- File?
            if attributes.mode and attributes.mode == 'file' then
                local dest_attributes = lfs.attributes(destination .. file)
                if not dest_attributes or attributes.modification > dest_attributes.modification then
                    -- Open current file
                    local f, err = io.open(directory .. file, 'r')
                    if not f then error(err) end
                    -- Read file
                    local s, err = f:read('*a')
                    if not s then error(err) end
                    f:close()

                    -- Open new file for creation
                    local f, err = io.open(destination .. file, 'w')
                    -- Write contents
                    local result, err = f:write(s)
                    if not result then error(err) end
                    f:close()

                    print('\t' .. destination .. file)
                end
            end
        end
    end
end


-- Export
return {
    copy_dir = copy_dir,
    load_templates = load_templates,
    load_markdowns = load_markdowns,
    page_links = page_links,
    ensure_destination = ensure_destination,
    write_html = write_html
}
