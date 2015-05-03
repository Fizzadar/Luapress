-- Luapress
-- File: luapress/template.lua
-- Desc: l(ua)html -> html templates!

local ipairs = ipairs
local type = type
local tostring = tostring
local loadstring = loadstring


-- Bits taken from my luawa (https://github.com/Fizzadar/luawa)
local template = {
    data = {}
}

-- Add to data
function template:set(key, value)
    self.data[key] = value
end

-- Get data
function template:get(key)
    return self.data[key]
end

-- Function to work before tostring
function template:toString(string)
    -- nil returns blank
    if string == nil then return '' end
    -- String as string
    if type(string) == 'string' then return string end
    -- Otherwise as best
    return tostring(string)
end

-- Turn lhtml code into an lua function which returns an output as string
function template:process(...)
    local function process(code)
        -- Prepend bits
        code = 'local self, output = require(\'luapress.template\'), "" output = output .. [[' .. code
        -- Replace <?=vars?>
        code = code:gsub('<%?=([,/_\'%[%]%%%:%.%a%s%(%)]+)%s%?>', ']] .. self:toString( %1 ) .. [[')
        -- Replace <? to close output, start raw lua
        code = code:gsub('<%?%s', ']] ')
        -- Replace ?> to stop lua and start output (in table)
        code = code:gsub('%s%?>', ' output = output .. [[')
        -- Close final output and return concat of the table
        code = code .. ' \n]] return output'

        return loadstring(code)()
    end

    local out = ''
    for _, v in ipairs({...}) do
        out = out .. process(v)
    end

    return out
end

return template
