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
                output = output .. '<li class="active"><a href="' .. config.url .. '/pages/' .. active .. '">' .. page.title .. '</a></li>\n'
            else
                output = output .. '<li><a href="' .. config.url .. '/pages/' .. page.link .. '">' .. page.title .. '</a></li>\n'
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
-- @param file  Name and path of the input file
-- @result  Processed string
--
local function process_plugins(s, out, file)
    local pos = 1
    while pos < #s do
	local a, b = s:find('%$!.-!%$', pos)
	if not a then break end
	local s2 = s:sub(a + 2, b - 2)
	local pl, arg = s2:match('^ *(%w+) *(.*)$')
	if not pl then
	    error('Empty plugin call in ' .. file)
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

---
-- Load all markdown files in a directory and preprocess them
-- into HTML.
--
-- @param directory  Subdirectory of config.root (pages or posts)
-- @param template  'page' or 'post'
-- @return  Table of items
--
local function load_markdowns(directory, template)
    local outs = {}

    for file in lfs.dir(config.root .. "/" .. directory) do
        if file:sub(-3) == '.md' then
            local title = file:sub(0, -4)
            file = config.root .. "/" .. directory .. '/' .. file
            local attributes = lfs.attributes(file)

            -- Work out title
            local link = title:gsub(' ', '_'):gsub('[^_aA-zZ0-9]', '')
            if not config.link_dirs then link = link .. '.html' end

            -- Get basic attributes
            local out = {
                link = link,
                title = title,
		directory = directory,	-- relative to config.root
		name = title,	-- same as title, but is not overwritten
                content = '',
                time = attributes.modification,
                modification = attributes.modification, -- stored separately as time can be overwritten w/$time=
		template = template,
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

	    s = process_plugins(s, out, file)

            -- Excerpt
            local start, _ = s:find('--MORE--')
            if start then
                -- Extract the excerpt
                out.excerpt = markdown(s:sub(0, start - 1))
                -- Replace the --MORE--
                local sep = config.more_separator or ''
                s = s:gsub('%-%-MORE%-%-', '<a id="more">' .. sep .. '</a>')
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
		    assert(f, "Failed to write to " .. destination .. file)
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
