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

local discount = require('discount')
local lfs = require('lfs')

local template = require('luapress.template')
local cli = require('luapress.lib.cli')


-- Get the Luapress install directory (where being executed from)
local function get_install_dir()
    return arg[0]:gsub('/[^/]-/[^/]-$', '')
end


-- Get the Luapress install directory (where being executed from)
function split(str, sSeparator, nMax, bRegexp)
   assert(sSeparator ~= '')
   assert(nMax == nil or nMax >= 1)

   local aRecord = {}

   if str:len() > 0 then
      local bPlain = not bRegexp
      nMax = nMax or -1

      local nField, nStart = 1, 1
      local nFirst,nLast = str:find(sSeparator, nStart, bPlain)
      while nFirst and nMax ~= 0 do
         aRecord[nField] = str:sub(nStart, nFirst-1)
         nField = nField+1
         nStart = nLast+1
         nFirst,nLast = str:find(sSeparator, nStart, bPlain)
         nMax = nMax-1
      end
      aRecord[nField] = str:sub(nStart)
   end

   return aRecord
end


-- Turns a string into markdown using discount
local function markdown(s)
    local unpack_func = unpack or table.unpack
    local data = discount.compile(s, unpack_func(config.discount_options))
    return data.body, data.index  -- return both body + TOC
end


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
    print('\t' .. object.title)
    local output = template:process(templates.header, templates[object.template], templates.footer)
    f, err = io.open(destination, 'w')
    if not f then cli.error(err) end
    local result, err = f:write(output)
    if not result then cli.error(err) end
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


local plugins = {}

---
-- Process calls to plugins: $! plugin arg, arg... !$
--
-- @param s  Content string
-- @param out  Table describing the page or post
-- @result  Processed string
--
local function _process_plugins(s, out)
    while true do
        local a, b = s:find('\n%$!.-!%$')
        if not a then break end
        local s2 = s:sub(a + 3, b - 2)
        local pl, arg = s2:match('^ *(%w+) *(.*)$')
        if not pl then
            cli.error('Empty plugin call in ' .. out.source)
        end

        -- Support for Lua 5.3+
        local load_func = loadstring or load

        -- convert args to a table
        if #arg > 0 then
            arg = load_func("return { " .. arg .. "}")()
        else
            arg = {}
        end

        if not plugins[pl] then
            -- load the plugin either from the site directory or the install directory
            local path = 'plugins/' .. pl
            if not lfs.attributes(path .. '/init.lua', "mode") then
                path = config.base .. '/plugins/' .. pl
            end

            print(path)
            local plugin = loadfile(path .. '/init.lua')()
            plugins[pl] = {path, plugin}
        end
        local path, plugin = unpack(plugins[pl])

        -- execute the plugin, replace markup by result
        arg.plugin_path = path
        local res = plugin(out, arg)
        s = s:sub(1, a - 1) .. res .. s:sub(b + 1)
    end

    return s
end


local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
local function _quote_string(str)
    return str:gsub(quotepattern, "%%%1")
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

    -- Get $key=value's (at the top of the file) and remove from string
    lines = split(s, '\n')
    for i, line in ipairs(lines) do
        k, v = line:match('%$([%w_]+)=(.+)')
        if not k then  -- break on the first non-matching line (variables at top!)
            break
        end
        item[k] = v
        s = s:gsub(_quote_string(line) .. '\n', '')
    end

    -- Swap out XREFs
    s = s:gsub('%[=(.-)%]', '[XREF=%1]')

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

    -- Swap in any $=toc - we *ignore* the HTML at this stage
    _, toc = markdown(s)
    toc = toc or ''
    s = s:gsub('%$=toc', toc)

    -- Now we've processed internal extras, restore $raw$ blocks
    local counter = 0
    for block in s:gmatch('%$raw%$') do
        s = s:gsub('%$raw%$', blocks[counter], counter + 1)
        counter = counter + 1
    end

    -- Now we've done the internal extras, actually markdown it!
    s, _ = markdown(s)

    item.content = s
    item.toc = toc
end


---
-- Load all markdown files in a directory and preprocess them
-- into HTML.
--
-- @param directory  Subdirectory of config.root (pages or posts)
-- @param template  'page' or 'post'
-- @return  Table of items
--
local function load_markdowns(directory, template, get_item_permalink)
    local items = {}
    local out_directory = config[directory .. '_dir']

    for file in lfs.dir(config.root .. "/" .. directory) do
        local supported_file = false
        local fname = nil

        if file:sub(-3) == '.md' then
          supported_file = true
          fname = file:sub(0, -4)
        end

        if file:sub(-9) == '.markdown' then
          supported_file = true
          fname = file:sub(0, -10)
        end

        if supported_file then
            local file2 = config.root .. "/" .. directory .. '/' .. file
            local attributes = lfs.attributes(file2)

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

            -- Use item to generate it's link
            local link = get_item_permalink(item)
            if not config.link_dirs then
                link = link .. '.html'
            end
            item.link = link

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
            print('\t' .. item.title)
        end
    end

    return items
end


---
-- Loads all .mustache, .etlua & .lhtml files from a template directory
--
local function load_templates()
    local templates = {}
    local directory = config.root .. '/templates/' .. config.template

    for file in lfs.dir(directory) do
        -- Mustache templates take prioritry
        for _, extension in pairs({'mustache', 'lhtml', 'etlua'}) do
            if file:sub(-#extension) == extension then
                local tmpl_name = file:sub(0, -(#extension + 2))

                -- Fail if two templates with the same name exist
                -- (ie header.[mustache|lhtml])
                if templates[tmpl_name] then
                    cli.error('Duplicate template: ' .. tmpl_name)
                end

                local filename = directory .. '/' .. file

                -- Open & read the file
                local f, err = io.open(filename, 'r')
                if not f then cli.error(err) end
                local s, err = f:read('*a')
                if not s then cli.error(err) end
                f:close()

                -- Set the template
                templates[tmpl_name] = {
                    content = s,
                    format = extension
                }
            end
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
    if not f then cli.error(err) end
    -- Read file
    local s, err = f:read('*a')
    if not s then cli.error(err) end
    f:close()

    -- Open new file for creation
    local f, err = io.open(destination, 'w')
    assert(f, "Failed to write to " .. destination)

    -- Write contents
    local result, err = f:write(s)
    if not result then cli.error(err) end
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
        local a, b = s:find('%[XREF=.-%]', pos)
        if not a then break end

        local ref = s:sub(a + 6, b - 1)
        local res = idx[ref]

        if not res then
            print(string.format(
                '%s: Error: cross reference to %s not found.',
                fname, ref
            ))

            res = 'INVALID XREF'
        else
            res = string.format(
                '<a href="%s/%s/%s">%s</a>',
                config.url, res.directory, res.link, res.title
            )
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
    escape_for_rss = escape_for_rss,
    get_install_dir = get_install_dir,
}
