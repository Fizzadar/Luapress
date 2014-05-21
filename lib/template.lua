-- Luapress
-- File: lib/template.lua

local type, tostring, loadstring = type, tostring, loadstring

--bits taken from my luawa (https://github.com/Fizzadar/luawa)
local template = {
    data = {}
}

--add to data
function template:set(key, value)
    self.data[key] = value
end

--get data
function template:get(key)
    return self.data[key]
end

--function to work before tostring
function template:toString(string)
    --nil returns blank
    if string == nil then return '' end
    --string as string
    if type(string) == 'string' then return string end
    --otherwise as best
    return tostring(string)
end

--turn lhtml code into an lua function which returns an output as string
function template:process(...)
    local function process(code)
        --prepend bits
        code = 'local self, output = template, "" output = output .. [[' .. code
        --replace <?=vars?>
        code = code:gsub('<%?=([,/_\'%[%]%%%:%.%a%s%(%)]+)%s%?>', ']] .. self:toString( %1 ) .. [[')
        --replace <? to close output, start raw lua
        code = code:gsub('<%?%s', ']] ')
        --replace ?> to stop lua and start output (in table)
        code = code:gsub('%s%?>', ' output = output .. [[')
        --close final output and return concat of the table
        code = code .. ' \n]] return output'

        --allow self = template to work
        local func, env = loadstring(code), _G
        env.template = self
        setfenv(func, env)

        return func()
    end

    local out = ''
    for _, v in ipairs(arg) do
        out = out .. process(v)
    end

    return out
end

return template