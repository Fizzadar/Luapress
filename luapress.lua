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
config.url = config.url or ''
config.template = config.template or 'default'
config.title = config.title or 'Luapress blog'

--modules
local lfs = require( 'lfs' )
local markdown = require( 'lib/markdown' )
template = require( 'lib/template' )

--templates
local templates = {}

--data to fill
local posts = {}
local pages = {}

--get templates
for file in lfs.dir( 'templates/' .. config.template .. '/' ) do
    if file:sub( -5 ) == 'lhtml' then
        local f, err = io.open( 'templates/' .. config.template .. '/' .. file, 'r' )
        if not f then error( err ) end
        local s, err = f:read( '*a' )
        if not s then error( err ) end

        templates[file:sub( 0, -7 )] = s
    end
end

--setup our global template opts
template:set( 'title', config.title )
template:set( 'url', config.url )
template:set( 'pages', pages )

--get posts
for file in lfs.dir( 'posts/' ) do
    if file:sub( -3 ) == '.md' then
        --work out title
        local title = file:sub( 0, -4 ):gsub( '%s', '_' )
        local link = title:gsub( '%s', '_' ) .. '.html'
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
        post.content = markdown( s )
        --set template data, get template output
        template:set( 'post', post )
        post.output = template:process( templates.post )

        --insert to posts
        table.insert( posts, post )
    end
end

--get pages
for file in lfs.dir( 'pages/' ) do
    if file:sub( -3 ) == '.md' then
        --work out title
        local title = file:sub( 0, -4 )
        local link = title:gsub( '%s', '_' ) .. '.html'
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
        --set template data, get template output
        template:set( 'page', page )
        page.output = template:process( templates.page )

        --insert to pages
        table.insert( pages, page )
    end
end

--begin generation of posts
for k, post in pairs( posts ) do
    --is there a file already there?!
    local f = io.open( 'build/posts/' .. post.link, 'r' )

    if not f or ( arg[1] and arg[1] == 'all' ) then
        template:set( 'post', post )

        local output = template:process( templates.header ) .. post.output .. template:process( templates.footer )

        f, err = io.open( 'build/posts/' .. post.link, 'w' )
        if not f then error( err ) end
        local result, err = f:write( output )
        if not result then error( err ) end
    end
end

--begin generation of pages
for k, page in pairs( pages ) do
    --is there a file already there?!
    local f = io.open( 'build/pages/' .. page.link, 'r' )

    if not f or ( arg[1] and arg[1] == 'all' ) then
        template:set( 'page', page )

        local output = template:process( templates.header ) .. page.output .. template:process( templates.footer )

        f, err = io.open( 'build/pages/' .. page.link, 'w' )
        if not f then error( err ) end
        local result, err = f:write( output )
        if not result then error( err ) end
    end
end


--generate index
local f, err = io.open( 'build/index.html', 'w' )
if not f then error( err ) end
--add header, posts, footer
local output = template:process( templates.header )
for k, v in pairs( posts ) do
    output = output .. v.output
end
output = output .. template:process( templates.footer )
--write to file
local result, err = f:write( output )
if not result then error( err ) end
