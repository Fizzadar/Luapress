#!/usr/bin/env lua

-- Luapress

--[[
    1. get data
        1.1 get posts
        1.2 get pages
    2. generate page & post templates
        2.1 foreach post, generate if needed
        2.2 foreach page, generate if needed
    3. generate index page and paginated pages
]]

--local optimization
local require, print, error, table = require, print, error, table

--modules
local lfs = require('lfs')
local markdown = require('lib/markdown')
local template = require('lib/template')


--config & fix missing bits
local config = require('config')
config.version = '1.1.2'
config.url = arg[#arg]:sub(1, 4) == 'http' and arg[#arg] or config.url
config.description = config.description or 'A blog'

--work out caching/cleaning, default on
config.cache = true
config.clean = false

--get last update time
local attributes = lfs.attributes('.cache')
config.cache_time = attributes and attributes.modification or 0

--open + read cache url
local f, err = io.open('.cache', 'r')
local url
if f then
    url, err = f:read('*a')
    if not url then error(err) end
    f:close()
end

--old cache w/ different url? disable cache for link changes
if url ~= config.url then
    config.cache = false
end

--write the url to cache
local f, err = io.open('.cache', 'w')
local status, err = f:write(config.url)
if not status then error(err) end
f:close()

--nocache/clean in cmd line?
for _, v in ipairs(arg) do
    if v == 'nocache' then
        config.cache = false
    end
    if v == 'clean' then
        config.clean = true
    end
end
--ensure
if config.clean then
    config.cache = false
end

--help?
if arg[1] == 'help' then
    print('#')
    print('# Luapress v' .. config.version)
    print('# Usage: ./press.lua <optional url: "http://example.com">')
    print('# Example: ./press.lua')
    print('# Example: ./press.lua http://example.com')
    print('# Example: ./press.lua nocache http://example.com')
    print('# For more details: https://github.com/Fizzadar/Luapress')
    print('#')
    return 0
end

print('#')
print('# Luapress v' .. config.version .. ' for: ' .. config.url)
print('# Using cache: ' .. tostring(config.cache))
if config.clean then
    print('# Clean enabled')

    local function iter_dir(dir)
        dir = dir .. '/'
        local out_files = {}

        for file in lfs.dir(dir) do
            if file ~= '..' and file ~= '.' and file ~= '.keepme' then
                local attributes = lfs.attributes(dir .. file)
                if attributes.mode == 'directory' then
                    local fs = iter_dir(dir .. file)
                    for _, f in pairs(fs) do
                        table.insert(out_files, f)
                    end
                else
                    table.insert(out_files, dir .. file)
                end
            end
        end

        return out_files
    end

    local files = iter_dir('build')
    for _, f in ipairs(files) do
        os.remove(f)
    end
end
print('#')

--templates
local templates = {}

--data to fill
local posts = {}
local pages = {}

--setup our global template opts
template:set('title', config.title)
template:set('url', config.url)

--get templates
print('[1] Loading templates')
for file in lfs.dir('templates/' .. config.template .. '/') do
    if file:sub(-5) == 'lhtml' then
        local tmpl_name = file:sub(0, -7)
        file = 'templates/' .. config.template .. '/' .. file
        local f, err = io.open(file, 'r')
        if not f then error(err) end
        local s, err = f:read('*a')
        if not s then error(err) end
        f:close()

        templates[tmpl_name] = {
            content = s,
            time = lfs.attributes(file).modification
        }
        print('\t' .. tmpl_name)
    end
end
--rss template
templates.rss = {
    time = 0,
    content = [[
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
    <channel>
        <description>]] .. config.description .. [[</description>
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

--get posts
print('[2] Loading ' .. 'posts')
for file in lfs.dir('posts/') do
    if file:sub(-3) == '.md' then
        local title = file:sub(0, -4)
        file = 'posts/' .. file
        local attributes = lfs.attributes(file)

        --work out title
        local link = title:gsub(' ', '_'):gsub('[^_aA-zZ0-9]', '')
        if not config.link_dirs then link = link .. '.html' end

        --get basic attributes
        local post = {
            link = link,
            title = title,
            content = '',
            time = attributes.modification
        }

        --now read the file
        local f, err = io.open(file, 'r')
        if not f then error(err) end
        local s, err = f:read('*a')
        if not s then error(err) end

        --set $=key's
        s = s:gsub('%$=url', config.url)

        --get $key=value's
        for k, v, c, d in s:gmatch('%$([%w]+)=(.-)\n') do
            post[k] = v
            s = s:gsub('%$[%w]+=.-\n', '')
        end

        --excerpt
        local start, finish = s:find('--MORE--')
        if start then
            post.excerpt = markdown(s:sub(0, start - 1))
        end
        post.content = markdown(s:gsub('--MORE--', ''))

        --date set?
        if post.date then
            local a, b, d, m, y = post.date:find('(%d+)%/(%d+)%/(%d+)')
            post.time = os.time({ day = d, month = m, year = y })
        end

        --insert to posts
        table.insert(posts, post)

        --log
        print('\t' .. post.title)
    end
end
--sort posts by time
table.sort(posts, function(a, b) return tonumber(a.time) > tonumber(b.time) end)

--get pages
print('[3] Loading ' .. 'pages')
for file in lfs.dir('pages/') do
    if file:sub(-3) == '.md' then
        local title = file:sub(0, -4)
        file = 'pages/' .. file
        local attributes = lfs.attributes(file)

        --work out title
        local link = title:gsub(' ', '_'):gsub('[^_aA-zZ0-9]', '')
        if not config.link_dirs then link = link .. '.html' end

        --attributes
        local page = {
            link = link,
            title = title,
            content = '',
            time = attributes.modification
        }

        --now read the file
        local f, err = io.open(file, 'r')
        if not f then error(err) end
        local s, err = f:read('*a')
        if not s then error(err) end

        --get $key=value's
        for k, v, c, d in s:gmatch('%$([%w]+)=(.-)\n') do
            page[k] = v
            s = s:gsub('%$[%w]+=.-\n', '')
        end

        --set $=key's
        s = s:gsub('%$=url', config.url)

        --string => markdown
        page.content = markdown(s)

        --insert to pages
        if page.order then
            table.insert(pages, page.order, page)
        else
            table.insert(pages, page)
        end

        --log
        print('\t' .. page.title)
    end
end

if #posts > 0 then
    --archive page/index
    template:set('posts', posts)
    template:set('page', { title = Archive })
    local link = 'Archive'
    if not config.link_dirs then link = link .. '.html' end
    table.insert(pages, { link = link, title = 'Archive', time = os.time(), content = template:process(templates.archive.content) })
end


--make sure we have our directories
if not lfs.attributes('build/posts') and not lfs.mkdir('build/posts') then error('Cant make build/posts') end
if not lfs.attributes('build/pages') and not lfs.mkdir('build/pages') then error('Cant make build/pages') end
if not lfs.attributes('build/inc') and not lfs.mkdir('build/inc') then error('Cant make build/inc') end
if not lfs.attributes('build/inc/template') and not lfs.mkdir('build/inc/template') then error('Cant make build/inc/template') end



--function to be used below to display list of <li> for pages
function luapress_page_links(active)
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
template:set('page_links', luapress_page_links())


--begin generation of post pages
print('[4] Building ' .. (config.cache and 'new ' or '') .. 'posts')
template:set('single', true)
for k, post in pairs(posts) do
    local dest_file
    if config.link_dirs then
        lfs.mkdir('build/posts/' .. post.link)
        dest_file = 'build/posts/' .. post.link .. '/index.html'
    else
        dest_file = 'build/posts/' .. post.link
    end
    --check modification time on post & destination files
    local attributes = lfs.attributes(dest_file)
    if not config.cache or not attributes or post.time > attributes.modification then
        --set post
        template:set('post', post)
        --build html
        local output = template:process(templates.header.content, templates.post.content, templates.footer.content)

        f, err = io.open(dest_file, 'w')
        if not f then error(err) end
        local result, err = f:write(output)
        if not result then error(err) end

        f:close()
        print('\t' .. post.title)
    end
end
template:set('single', false)

--begin generation of page pages
print('[5] Building ' .. (config.cache and 'new ' or '') .. 'pages')
for k, page in pairs(pages) do
    local dest_file
    if config.link_dirs then
        lfs.mkdir('build/pages/' .. page.link)
        dest_file = 'build/pages/' .. page.link .. '/index.html'
    else
        dest_file = 'build/pages/' .. page.link
    end
    --check modification time on post & destination files
    local attributes = lfs.attributes(dest_file)
    if not config.cache or not attributes or page.time > attributes.modification then
        --we're a page, so change up page_links
        template:set('page_links', luapress_page_links(page.link))
        --set page
        template:set('page', page)
        --build html
        local output = template:process(templates.header.content, templates.page.content, templates.footer.content)

        f, err = io.open(dest_file, 'w')
        if not f then error(err) end
        local result, err = f:write(output)
        if not result then error(err) end

        f:close()
        print('\t' .. page.title)
    end
end
template:set('page', false)



--reset page_links for indexes
template:set('page_links', luapress_page_links())
print('[6] Building index pages')
--iterate to generate indexes
local index = 1
local count = 0
local output = ''
for k, post in pairs(posts) do
    --add post to output, increase count
    template:set('post', post)
    output = output .. template:process(templates.post.content)
    count = count + 1

    --if we have n posts or are on last post, create current index, reset
    if count == config.posts_per_page or k == #posts then
        --pick index file, open
        local f, err
        if index == 1 then
            f, err = io.open('build/index.html', 'w')
        else
            f, err = io.open('build/index' .. index .. '.html', 'w')
        end
        if not f then error(err) end

        --work out previous page
        if index > 1 then
            if index == 2 then
                template:set('previous_page', 'index.html')
            else
                template:set('previous_page', 'index' .. index - 1 .. '.html')
            end
            --ensure this is false
            template:set('home', false)
        else
            --we are page 1!
            template:set('previous_page', false)
            --useful!
            template:set('home', true)
        end
        --work out next page
        if #posts > k then
            template:set('next_page', 'index' .. index + 1 .. '.html')
        else
            template:set('next_page', false)
        end

        --create and write output
        output = template:process(templates.header.content) .. output .. template:process(templates.footer.content)
        local result, err = f:write(output)
        if not result then error(err) end

        --reset & close f
        count = 0
        output = ''
        f:close()
        print('\tindex ' .. index)
        index = index + 1
    end
end

--build rss of last 10 posts
print('[7] Building RSS')
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
    local f, err = io.open('build/index.xml', 'w')
    if not f then error(err) end
    local result, err = f:write(rss)
    if not result then error(err) end
end

--finally, copy over inc to build inc
print('[8] Copying inc files')
function copy_dir(dir, dest)
    for file in lfs.dir(dir) do
        if file ~= '.' and file ~= '..' then
            local attributes = lfs.attributes(dir .. file) or {}
            --directory?
            if attributes.mode and attributes.mode == 'directory' then
                --copy directory?
                if not io.open(dest .. file, 'r') then
                    lfs.mkdir(dest .. file)
                end
                copy_dir(dir .. file .. '/', dest .. file .. '/')
            end

            --file?
            if attributes.mode and attributes.mode == 'file' then
                local dest_attributes = lfs.attributes(dest .. file)
                if not dest_attributes or attributes.modification > dest_attributes.modification then
                    --open current file
                    local f, err = io.open(dir .. file, 'r')
                    if not f then error(err) end
                    --read file
                    local s, err = f:read('*a')
                    if not s then error(err) end
                    f:close()

                    --open new file for creation
                    local f, err = io.open(dest .. file, 'w')
                    local result, err = f:write(s)
                    if not result then error(err) end
                    f:close()

                    print('\t' .. dest .. file)
                end
            end
        end
    end
end
copy_dir('inc/', 'build/inc/')
copy_dir('templates/' .. config.template .. '/inc/', 'build/inc/template/')

print('#')
print('Luapress Complete! Upload ./build to your website')
print('#')
