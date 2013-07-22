#!/usr/bin/env lua

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

--config & fix missing bits
local config = require( 'config' )
config.url = arg[2] or config.url

--modules
local lfs = require( 'lfs' )
local markdown = require( 'lib/markdown' )
template = require( 'lib/template' )

--templates
local templates = {}

--data to fill
local posts = {}
local pages = {}

--setup our global template opts
template:set( 'title', config.title )
template:set( 'url', config.url )

--get templates
for file in lfs.dir( 'templates/' .. config.template .. '/' ) do
    if file:sub( -5 ) == 'lhtml' then
        local f, err = io.open( 'templates/' .. config.template .. '/' .. file, 'r' )
        if not f then error( err ) end
        local s, err = f:read( '*a' )
        if not s then error( err ) end
        f:close()

        templates[file:sub( 0, -7 )] = s
    end
end
--rss template
templates.rss = [[
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
<channel>
<title><?=self:get( 'title' ) ?></title>
<link><?=self:get( 'url' ) ?></link>

<? for k, post in pairs( self:get( 'posts' ) ) do ?>
    <item>
    <title><?=post.title ?></title>
    <description><?=post.excerpt ?></description>
    <link><?=self:get( 'url' ) ?>/posts/<?=post.link ?></link>
    <guid><?=self:get( 'url' ) ?>/posts/<?=post.link ?></guid>
    </item>
<? end ?>

</channel>
</rss>
]]

--get posts
for file in lfs.dir( 'posts/' ) do
    if file:sub( -3 ) == '.md' then
        --work out title
        local title = file:sub( 0, -4 )
        local link = title:gsub( ' ', '_' ):gsub( '[^_aA-zZ0-9]', '' ) .. '.html'
        file = 'posts/' .. file

        --get basic attributes
        local attributes = lfs.attributes( file )
        local post = {
            link = link,
            title = title,
            content = '',
            time = attributes.modification
        }

        --now read the file
        local f, err = io.open( file, 'r' )
        if not f then error( err ) end
        local s, err = f:read( '*a' )
        if not s then error( err ) end

        --string => markdown
        local start, finish = s:find( '--MORE--' )
        if start then
            post.excerpt = markdown( s:sub( 0, start - 1 ) )
        end

        post.content = markdown( s:gsub( '--MORE--', '' ) )

        --insert to posts
        table.insert( posts, post )
    end
end

--get pages
for file in lfs.dir( 'pages/' ) do
    if file:sub( -3 ) == '.md' then
        --work out title
        local title = file:sub( 0, -4 )
        local link = title:gsub( ' ', '_' ):gsub( '[^_aA-zZ0-9]', '' ) .. '.html'
        file = 'pages/' .. file

        --attributes
        local page = {
            link = link,
            title = title,
            content = ''
        }

        --now read the file
        local f, err = io.open( file, 'r' )
        if not f then error( err ) end
        local s, err = f:read( '*a' )
        if not s then error( err ) end

        --string => markdown
        page.content = markdown( s )

        --insert to pages
        table.insert( pages, page )
    end
end
--archive page/index
template:set( 'posts', posts )
table.insert( pages, { link = 'Archive.html', title = 'Archive', content = template:process( templates.archive ) } )



--make sure we have our directories
if not io.open( 'build/posts' ) and not lfs.mkdir( 'build/posts' ) then error( 'Cant make build/posts' ) end
if not io.open( 'build/pages' ) and not lfs.mkdir( 'build/pages' ) then error( 'Cant make build/pages' ) end
if not io.open( 'build/inc' ) and not lfs.mkdir( 'build/inc' ) then error( 'Cant make build/inc' ) end
if not io.open( 'build/inc/template' ) and not lfs.mkdir( 'build/inc/template' ) then error( 'Cant make build/inc/template' ) end



--function to be used below to display list of <li> for pages
function luapress_page_links( active )
    local output = ''
    for k, page in pairs( pages ) do
        if page.link == active then
            output = output .. '<li class="active"><a href="' .. config.url .. '/pages/' .. active .. '">' .. page.title .. '</a></li>\n'
        else
            output = output .. '<li><a href="' .. config.url .. '/pages/' .. page.link .. '">' .. page.title .. '</a></li>\n'
        end
    end
    return output
end
template:set( 'page_links', luapress_page_links() )


--begin generation of post pages
template:set( 'single', true )
for k, post in pairs( posts ) do
    --is there a file already there?!
    local f = io.open( 'build/posts/' .. post.link, 'r' )

    if not f or ( arg[1] and arg[1] == 'all' ) then
        --set post
        template:set( 'post', post )

        local output = template:process( templates.header ) .. template:process( templates.post ) .. template:process( templates.footer )

        f, err = io.open( 'build/posts/' .. post.link, 'w' )
        if not f then error( err ) end
        local result, err = f:write( output )
        if not result then error( err ) end

        f:close()
    end
end
template:set( 'single', false )

--begin generation of page pages
for k, page in pairs( pages ) do
    --is there a file already there?!
    local f = io.open( 'build/pages/' .. page.link, 'r' )

    if not f or ( arg[1] and arg[1] == 'all' ) then
        --we're a page, so change up page_links
        template:set( 'page_links', luapress_page_links( page.link ) )
        --set page
        template:set( 'page', page )

        local output = template:process( templates.header ) .. template:process( templates.page ) .. template:process( templates.footer )

        f, err = io.open( 'build/pages/' .. page.link, 'w' )
        if not f then error( err ) end
        local result, err = f:write( output )
        if not result then error( err ) end

        f:close()
    end
end
template:set( 'page', false )



--reset page_links for indexes
template:set( 'page_links', luapress_page_links() )

--iterate to generate indexes
local index = 1
local count = 0
local output = ''
for k, post in pairs( posts ) do
    --add post to output, increase count
    template:set( 'post', post )
    output = output .. template:process( templates.post )
    count = count + 1

    --if we have n posts or are on last post, create current index, reset
    if count == config.posts_per_page or k == #posts then
        --pick index file, open
        local f, err
        if index == 1 then
            f, err = io.open( 'build/index.html', 'w' )
        else
            f, err = io.open( 'build/index' .. index .. '.html', 'w' )
        end
        if not f then error( err ) end

        --work out previous page
        if index > 1 then
            if index == 2 then template:set( 'previous_page', 'index.html' ) else template:set( 'previous_page', 'index' .. index - 1 .. '.html' ) end
        else
            --we are page 1!
            template:set( 'previous_page', false )
        end
        --work out next page
        if #posts > k then
            template:set( 'next_page', 'index' .. index + 1 .. '.html' )
        else
            template:set( 'next_page', false )
        end

        --create and write output
        output = template:process( templates.header ) .. output .. template:process( templates.footer )
        local result, err = f:write( output )
        if not result then error( err ) end

        --reset & close f
        count = 0
        index = index + 1
        output = ''
        f:close()
    end
end

--build rss of last 10 posts
local rssposts = {}
for k, post in pairs( posts ) do
    if k <= 10 then
        if post.excerpt then post.excerpt = post.excerpt:gsub( '<[aA-zZ%s]+/?>', '' ):gsub( '</[aA-zZ%s]+>', '' ):gsub( '\n', '' ) end
        table.insert( rssposts, post )
    else
        break
    end
end
template:set( 'posts', rssposts )
local rss = template:process( templates.rss )
local f, err = io.open( 'build/index.xml', 'w' )
if not f then error( err ) end
local result, err = f:write( rss )
if not result then error( err ) end

--finally, copy over inc to build inc
function copy_dir( dir, dest )
    for file in lfs.dir( dir ) do
        if file ~= '.' and file ~= '..' then
            local attributes = lfs.attributes( dir .. file ) or {}
            --directory?
            if attributes.mode and attributes.mode == 'directory' then
                --copy directory?
                if not io.open( dest .. file, 'r' ) then
                    lfs.mkdir( dest .. file )
                end
                copy_dir( dir .. file .. '/', dest .. file .. '/' )
            end

            --file?
            if attributes.mode and attributes.mode == 'file' then
                --do we have the file?
                if not io.open( dest .. file, 'r' ) or arg[1] == 'all' then
                    --open current file
                    local f, err = io.open( dir .. file, 'r' )
                    if not f then error( err ) end
                    --read file
                    local s, err = f:read( '*a' )
                    if not s then error( err ) end
                    f:close()

                    --open new file for creation
                    local f, err = io.open( dest .. file, 'w' )
                    local result, err = f:write( s )
                    if not result then error( err ) end
                    f:close()
                end
            end
        end
    end
end
copy_dir( 'inc/', 'build/inc/' )
copy_dir( 'templates/' .. config.template .. '/inc/', 'build/inc/template/' )