-- Luapress
-- File: luapress/lib/watch_directory.lua
-- Desc: helper to watch directories and trigger a callback - only works on POSIX systems

local lfs = require('lfs')


local function _get_file_times(directories)
    local files = {}

    for _, dir in ipairs(directories) do
        for file in lfs.dir(dir) do
            local filename = dir .. '/' .. file
            local attributes = lfs.attributes(filename) or {}
            if attributes.mode and attributes.mode == 'file' then
                files[filename] = attributes.modification
            end
        end
    end

    return files
end


local function watch_directory(directories, callback, interval)
    interval = interval or 1

    -- Get files as they are currently
    local current_files = nil

    while true do
        -- Get file state right now
        files = _get_file_times(directories)

        -- We have files, let's compare!
        if current_files then
            local changed = false

            for filename, time in pairs(files) do
                if not current_files[filename] then
                    changed = true
                    print('File added: ' .. filename)
                elseif current_files[filename] < time then
                    changed = true
                    print('File changed: ' .. filename)
                end
            end

            if changed then
                callback()
            end

        -- If no current files, first run
        else
            callback()
        end

        -- Assign current files
        current_files = files

        -- Lua has no native sleep functionality, so we use os.execute
        -- this will fail on windows(!) (bin file handles this)
        local status = os.execute('sleep ' .. interval)
        -- Capture ctrl+c's
        if not status then
            break
        end
    end
end


-- Export
return watch_directory
