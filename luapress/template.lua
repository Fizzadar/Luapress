-- Luapress
-- File: luapress/template.lua
-- Desc: l(ua)html -> html templates!

local ipairs = ipairs
local type = type
local tostring = tostring
local loadstring = loadstring

-- initialize mustache, but don't require the processor unless it's asked for
local mustache = nil

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

function process_lhtml (code)
    -- Prepend bits
    code = 'local self, output = require(\'luapress.template\'), ""\noutput = output .. [[' .. code
    -- Replace <?=vars?>
    code = code:gsub('<%?=([,/_\'%[%]%%%:%.%a%s%(%)]+)%s%?>', ']] .. self:toString( %1 ) .. [[')
    -- Replace <? to close output, start raw lua
    code = code:gsub('<%?%s', ']] ')
    -- Replace ?> to stop lua and start output (in table)
    code = code:gsub('%s%?>', '\noutput = output .. [[')
    -- Close final output and return concat of the table
    code = code .. ' \n]]\nreturn output'

    return loadstring(code)()
end

function process_mustache (code, data)
    -- provide some utilities
    data.format_date = function (date)
        return os.date('%a, %d %B, %Y', tonumber(date))
    end

    return mustache:render(code, data)
end

-- Turn lhtml code into an lua function which returns an output as string
function template:process(template_type, ...)
    -- use lhtml by default
    local process = process_lhtml

    -- switch to mustache depending on configuration
    if config.template_type == 'mustache' then
        -- Only require it if it hasn't been loaded yet, and if the template is
        -- asked for (to reduce unnecessary dependencies)
        if mustache == nil then
            mustache = require('lustache')
        end

        process = process_mustache
    end

    local out = ''

    for _, v in ipairs({...}) do
        out = out .. process(v, self.data)
    end

    return out
end

return template
