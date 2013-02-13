--bits taken from my luawa (https://github.com/Fizzadar/luawa)
local template = {
    data = {}
}

--add to data
function template:set( key, value )
    self.data[key] = value
end

--turn lhtml code into an lua function which returns an output as string
function template:process( code )
    --prepend bits
    code = 'local self, output = luawa.template, "" output = output .. [[' .. code
    --replace <?=vars?>
    code = code:gsub( '<%?=([,/_\'%[%]%:%.%a%s%(%)]+)%s%?>', ']] .. self:toString( %1 ) .. [[' )
    --replace <? to close output, start raw lua
    code = code:gsub( '<%?', ']] ' )
    --replace ?> to stop lua and start output (in table)
    code = code:gsub( '%?>', ' output = output .. [[' )
    --close final output and return concat of the table
    code = code .. ' ]] return output'

    return code
end

return template