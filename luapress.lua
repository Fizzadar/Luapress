--local optimization
local require, print, error, table = require, print, error, table

--config & fix missing bits
local config = require( 'config' )
config.template = config.template or 'default'
config.title = config.title or 'Luapress blog'

--modules
local lfs = require( 'lfs' )
local markdown = require( 'lib/markdown' )
local template = require( 'lib/template' )

--data to fill
local posts = {}
local pages = {}

--get posts
for file in lfs.dir( 'posts/' ) do
    if file:sub( -3 ) == '.md' then
        file = 'posts/' .. file
        --get basic attributes
        local attributes = lfs.attributes( file )
        local post = {
            content = '',
            date = attributes.modification
        }

        --now read the file
        local f, err = io.open( file, 'r' )
        if not f then error( err ) end
        local s, err = f:read( '*a' )
        if not s then error( err ) end

        --string => markdown
        post.content = markdown( s )

        --insert to posts
        table.insert( posts, post )
    end
end

--get pages
for file in lfs.dir( 'pages/' ) do
    if file:sub( -3 ) == '.md' then
        file = 'pages/' .. file
        local page = {
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

--setup our global template opts
template:set( 'title', config.title )

--begin generation of pages