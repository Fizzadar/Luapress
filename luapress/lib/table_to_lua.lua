-- Luapress
-- File: lib/table_to_lua.lua
-- Desc: helper to convert a table object into a Lua string
-- Originally from: https://github.com/Fizzadar/Lua-Bits/blob/master/tableToLuaFile.lua


-- Takes a Lua table object and outputs a Lua string
local function table_to_lua(table, indent)
    indent = indent or 1
    local out = ''

    for k, v in pairs(table) do
        out = out .. '\n'
        for i = 1, indent * 4 do
            out = out .. ' '
        end
        if type(v) == 'table' then
            if type(k) == 'string' and k:find('%.') then
                out = out .. '[\'' .. k .. '\'] = ' .. table_to_lua(v, indent + 1)
            else
                out = out .. k .. ' = ' .. table_to_lua(v, indent + 1)
            end
            out = out .. ','
        else
            if type(v) == 'string' then v = "'" .. v .. "'" end
            if type(v) == 'boolean' then v = tostring(v) end
            if type(k) == 'number' then k = '' else k = k .. ' = ' end
            out = out .. k .. v .. ','
        end
    end

    -- Strip final commas (optional, ofc!)
    out = out:sub(0, out:len() - 1)

    -- Ensure the final } lines up with any indent
    out = '{' .. out .. '\n'
    if indent > 1 then
        for i = 1, (indent - 1) * 4 do
            out = out .. ' '
        end
    end

    return out .. '}'
end


-- Export
return table_to_lua
