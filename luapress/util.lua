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


--
-- Escapes content for use as RSS text
--
-- @param content  Content to return escaped
--
local function escape_for_rss(content)
    return content
        -- Remove <script> and contents
        :gsub('<script[^>]+>.-</script>', '')
        -- Remove tags and self-closing
        :gsub('<[^>]+/?>', ' ')
        -- Remove close tags
        :gsub('</[^>]+>', ' ')
        -- Remove newlines
        :gsub('\n', '')
end


---
-- Writes a header/footer wrapped HTML file depending on the modification time
--
-- @param destination  Path and name of the output file
-- @param object  Descriptor of page or post
-- @param templates  Table with templates.
--
local function write_html(destination, object, templates)
    -- If the output file exists and is not older than the input file, skip.
    local attributes = lfs.attributes(destination)
    if config.cache and attributes and object.modification and object.modification <= attributes.modification then
    return
    end

    -- Write the file
    if config.print then print('\t' .. object.title) end
    local output = template:process(templates.header, templates[object.template], templates.footer)
    f, err = io.open(destination, 'w')
    if not f then error(err) end
    local result, err = f:write(output)
    if not result then error(err) end
    f:close()

end


-- Returns the destination file given our config
local function ensure_destination(item)
    if config.link_dirs then
        lfs.mkdir(config.root .. '/' .. config.build_dir .. '/' .. item.directory .. '/' .. item.link)
        return config.build_dir .. '/' .. item.directory .. '/' .. item.link .. '/index.html'
    end

    return config.build_dir .. '/' .. item.directory .. '/' .. item.link
end


-- Builds link list based on the currently active page
local function page_links(pages, active)
    local output = ''

    for k, page in pairs(pages) do
        if not page.hidden then
            if page.link == active then
                output = output .. '<li class="active"><a href="' .. config.url .. '/' .. config.pages_dir .. '/' .. active .. '">' .. page.title .. '</a></li>\n'
            else
                output = output .. '<li><a href="' .. config.url .. '/' .. config.pages_dir .. '/' .. page.link .. '">' .. page.title .. '</a></li>\n'
            end
        end
    end

    return output
end


---
-- Process calls to plugins: $! plugin arg, arg... !$
--
-- @param s  Content string
-- @param out  Table describing the page or post
-- @result  Processed string
--
local function _process_plugins(s, out)
    local pos = 1
    while pos < #s do
    local a, b = s:find('\n%$!.-!%$', pos)
    if not a then break end
    local s2 = s:sub(a + 3, b - 2)
    local pl, arg = s2:match('^ *(%w+) *(.*)$')
    if not pl then
        error('Empty plugin call in ' .. out.source)
    end

    -- convert args to a table
    if #arg > 0 then
        arg = loadstring("return { " .. arg .. "}")()
    else
        arg = {}
    end

    -- load the plugin either from the site directory or the install directory
    local path = 'plugins/' .. pl
    if not lfs.attributes(path .. '/init.lua', "mode") then
        path = config.base .. '/plugins/' .. pl
    end

    local plugin = loadfile(path .. '/init.lua')()

    -- execute the plugin, replace markup by result
    arg.plugin_path = path
    local res = plugin(out, arg)
    s = s:sub(1, a - 1) .. res .. s:sub(b + 1)
    pos = a + #res
    end

    return s
end


local function _process_content(s, item)
    blocks = {}

    -- First, extract any $raw$ blocks
    local counter = 0
    for block in s:gmatch('\n%$raw%$\n(.-)\n%$%/raw%$\n') do
        blocks[counter] = block
        counter = counter + 1
    end
    s = s:gsub('\n%$raw%$\n.-\n%$%/raw%$\n', '$raw$')

    -- Set $=key's
    s = s:gsub('%$=url', config.url)

    -- Get $key=value's (and remove from string)
    for k, v in s:gmatch('%$([%w]+)=(.-)\n') do
        item[k] = v
    end
    s = s:gsub('%$[%w]+=.-\n', '')

    -- Hande plugins
    s = _process_plugins(s, item)

    -- Excerpt
    local start, _ = s:find('%-%-MORE%-%-', 1)

    if start then
        -- Extract the excerpt
        item.excerpt = markdown(s:sub(0, start - 1))
        -- Replace the --MORE--
        local sep = config.more_separator or ''
        s = s:gsub('%-%-MORE%-%-', '<a id="more">' .. sep .. '</a>')
    end

    -- Now we've processed internal extras, restore $raw$ blocks
    local counter = 0
    for block in s:gmatch('%$raw%$') do
        s = s:gsub('%$raw%$', blocks[counter], counter + 1)
        counter = counter + 1
    end

    item.content = markdown(s)
end


---
-- Load all markdown files in a directory and preprocess them
-- into HTML.
--
-- @param directory  Subdirectory of config.root (pages or posts)
-- @param template  'page' or 'post'
-- @return  Table of items
--
local function load_markdowns(directory, template)
    local items = {}
    local out_directory = config[directory .. '_dir']

    for file in lfs.dir(config.root .. "/" .. directory) do
        if file:sub(-3) == '.md' then
            local fname = file:sub(0, -4)
            local file2 = config.root .. "/" .. directory .. '/' .. file
            local attributes = lfs.attributes(file2)

            -- Work out link
            local link = fname:gsub(' ', '_'):gsub('[^_aA-zZ0-9]', '')
            if not config.link_dirs then
                link = link .. '.html'
            end

            -- Get basic attributes
            local item = {
                source = directory .. '/' .. file, -- for error messages
                link = link, -- basename of output file
                name = fname, -- same as title, but is not overwritten
                title = fname, -- displayed page name
                directory = out_directory, -- relative to config.root
                content = '',
                time = attributes.modification, -- to check build requirement
                modification = attributes.modification, -- stored separately as time can be overwritten w/$time=
                template = template, -- what template will be used (type of item)
            }

            -- Now read the file
            local f = assert(io.open(file2, 'r'))
            local s = assert(f:read('*a'))

            -- Parse out internal extras and then markdown it
            _process_content(s, item)

            -- Date set?
            if item.date then
                local _, _, d, m, y = item.date:find('(%d+)%/(%d+)%/(%d+)')
                item.time = os.time({day = d, month = m, year = y})
            end

            -- Insert to items
            items[#items + 1] = item
            if config.print then print('\t' .. item.title) end
        end
    end

    return items
end


---
-- Loads all .lhtml files from a template directory
--
local function load_templates()
    local templates = {}
    local directory = config.root .. '/templates/' .. config.template

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

    return templates
end


---
-- Copies a single file
--
local function copy_file(source, destination)
    -- Open current file
    local f, err = io.open(source, 'r')
    if not f then error(err) end
    -- Read file
    local s, err = f:read('*a')
    if not s then error(err) end
    f:close()

    -- Open new file for creation
    local f, err = io.open(destination, 'w')
    assert(f, "Failed to write to " .. destination)

    -- Write contents
    local result, err = f:write(s)
    if not result then error(err) end
    f:close()

    print('\t' .. destination)
end


---
-- Recursively duplicates a directory
--
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
                    copy_file(directory .. file, destination .. file)
                end
            end
        end
    end
end


local function process_xref_1(fname, s, idx)
    local pos = 1

    while pos < #s do
    local a, b = s:find('%[=(.-)%]', pos)
    if not a then break end
    local ref = s:sub(a + 2, b - 1)
    local res = idx[ref]
    if not res then
        print(string.format("%s: Error: cross reference to %s not found.",
        fname, ref))
        res = "INVALID XREF"
    else
        res = string.format('<a href="%s/%s/%s">%s</a>',
        config.url, res.directory, res.link, res.title)
    end

    s = s:sub(1, a - 1) .. res .. s:sub(b + 1)
    pos = a + #res
    end

    return s
end

---
-- Replace all cross references by proper hyperlinks.  An xref has this format:
-- [=TYPE/NAME], where TYPE is either page or post, and NAME is the file name
-- (without the .md suffix).  The link text is the title of the target
-- page.
--
-- @param pages  Array of all pages
-- @param posts  Array of all posts
--
local function process_xref(pages, posts)

    -- create an index (name to item)
    local idx = {}
    for _, item in ipairs(pages) do
    idx['pages/' .. item.name] = item
    end
    for _, item in ipairs(posts) do
    idx['posts/' .. item.name] = item
    end

    -- check all items for xrefs
    for _, item in ipairs(pages) do
    item.content = process_xref_1(item.source, item.content, idx)
    if item.excerpt then
        item.excerpt = process_xref_1(item.source, item.excerpt, idx)
    end
    end
    for _, item in ipairs(posts) do
    item.content = process_xref_1(item.source, item.content, idx)
    end

end


-- Export
return {
    copy_file = copy_file,
    copy_dir = copy_dir,
    load_templates = load_templates,
    load_markdowns = load_markdowns,
    page_links = page_links,
    ensure_destination = ensure_destination,
    write_html = write_html,
    process_xref = process_xref,
    escape_for_rss = escape_for_rss
}
