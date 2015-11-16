-- Luapress
-- File: luapress/lib/cli.lua
-- Desc: CLI related helpers

local os = os
local print = print

local colors = require('ansicolors')


local function log(message, format)
    if format then
        print('--> ' .. colors('%{' .. format .. '}' .. message))
    else
        print('--> ' .. message)
    end
end


local function error(message)
    print('--> ' .. colors('%{red bright}' .. message))
    os.exit(1)
end


local function exit(message)
    print('--> ' .. colors('%{green}' .. message))
    os.exit()
end


-- Export
return {
    log = log,
    error = error,
    exit = exit
}
