-- Luapress
-- File: luapress/template.lua
-- Desc: process .mustache and .lhtml templates

local ipairs = ipairs
local type = type
local tostring = tostring
local loadstring = loadstring or load

local mustache = require('lustache')


-- Template data
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
function template.tostring(string)
    -- nil returns blank
    if string == nil then return '' end
    -- String as string
    if type(string) == 'string' then return string end
    -- Otherwise as best
    return tostring(string)
end


-- Format date with respect to config.date_format
function template.format_date(date)
    local formatter = '%a, %d %B, %Y'

    if config and config.date_format then
        formatter = config.date_format
    end

    return os.date(formatter, date)
end


-- Process a .mustache template with Lustache
function process_mustache(code, data)
    -- Wrapper around template.format_date
    data.format_date = function(date, render)
        return template.format_date(render(date))
    end

    return mustache:render(code, data)
end


-- Process a .lhtml template with gsub hacks(!)
function process_lhtml(code)
    -- Prepend bits
    code = 'local self, output = require(\'luapress.template\'), ""\noutput = output .. [[' .. code

    -- Replace <?=vars?>
    code = code:gsub(
        '<%?=(.-)%?>',
        ']] .. self.tostring( %1 ) .. [['
    )
    
    -- Replace ?>  <? spaces and lines between lua codes
    code = code:gsub('%?>[ \n]*<%?', '\n')

    -- Replace <? to close output, start raw lua
    code = code:gsub('<%?%s', ']] ')

    -- Replace ?> to stop lua and start output (in table)
    code = code:gsub('%s%?>', '\noutput = output .. [[')

    -- Close final output and return concat of the table
    code = code .. ' \n]]\nreturn output'

    local f, err = loadstring(code)
    if not f then
        print(err, code)
        return ''
    else
        return f()
    end
end


-- Turn a template into HTML output
function template:process(...)
    local out = ''

    for _, tmpl in ipairs({...}) do
        if tmpl.format == 'mustache' then
            process = process_mustache
        else
            process = process_lhtml
        end

        out = out .. process(tmpl.content, self.data)
    end

    return out
end

return template
