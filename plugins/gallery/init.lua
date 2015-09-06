-- vim:sw=4:sts=4

-- Gallery plugin.
-- Requires: ImageMagick (the convert command)

local lfs = require 'lfs'

---
-- Make sure all the directories leading to the given file exist.
-- The file itself might not exist yet.
--
-- @param path  Path and filename.
--
local function _mkdir(path)
    local s = ""
    for w in string.gmatch(path, "[^/]+/") do
	s = s .. w
	lfs.mkdir(s)
    end
end


---
-- Copy a file.  All the directories leading to the destination file are
-- automatically created.
--
-- @param from   Source file
-- @param to  Destination file
--
local function _file_copy(from, to)
    local f_from, f_to, buf

    f_from = lfs.attributes(from)
    f_to = lfs.attributes(to)

    -- Skip unchanged files.
    if f_from and f_to and f_from.size == f_to.size and f_from.modification
	<= f_to.modification then
	return
    end

    print("Copying " .. from)

    f_from = io.open(from, "rb")
    assert(f_from)
    _mkdir(to)

    -- try to hardlink.
    local rc = lfs.link(from, to)
    if rc == 0 then
	return
    end

    f_to = io.open(to, "wb")
    assert(f_to)

    while true do
	buf = f_from:read("*a", 2048)
	if not buf or #buf == 0 then break end
	f_to:write(buf)
    end

    f_from:close()
    f_to:close()
end



local function process(page, config, arg)

    -- determine the image directory, verify that it exists
    local dir = arg.dir or page.name
    local dir2 = 'gallery/' .. dir

    local s = lfs.attributes(dir2, "mode")
    if s ~= 'directory' then
	error("Gallery: not a directory: " .. dir2)
	return
    end

    -- create output paths
    lfs.mkdir(config.build_dir .. "/gallery")
    lfs.mkdir(config.build_dir .. "/" .. dir2)
    lfs.mkdir(config.build_dir .. "/" .. dir2 .. "/thumbs")
    lfs.mkdir(config.build_dir .. "/" .. dir2 .. "/images")

    -- enumerate all the images.  They may be returned in any order.
    local images = {}
    for f in lfs.dir(dir2) do
	if f ~= '.' and f ~= '..' then
	    -- print("Image", dir2 .. '/' .. f)
	    -- XXX verify that it is a JPG file (maybe others are OK)

	    -- remove extension
	    local base = f:gsub("%..*$", "")

	    local img = {
		-- img0001.jpg
		imgname = f,
		-- subdir
		subdir = dir,
		-- gallery/subdir/img0001.jpg
		source = dir2 .. '/' .. f,
		-- build/gallery/subdir/images/img0001.jpg
		dest = config.build_dir .. '/' .. dir2 .. '/images/' .. f,
		-- build/gallery/subdir/thumbs/img0001.jpg
		thumb = config.build_dir .. '/' .. dir2 .. '/thumbs/' .. f,
		-- img0001.html
		htmlbase = base .. '.html',
		-- build/gallery/subdir/img0001.html
		html = config.build_dir .. '/' .. dir2 .. '/' .. base .. '.html',
	    }
	    images[#images + 1] = img

	    -- make thumbnails using ImageMagick.  XXX check mtime of source
	    -- and dest if both exist
	    local target = lfs.attributes(img.thumb)
	    if not target then
		os.execute("convert '" ..  img.source .. "' -thumbnail 150x150 '"
		    .. img.thumb .. "'")
	    end
	end
    end

    -- sort images by name
    table.sort(images, function(a, b) return a.imgname < b.imgname end)

    -- generate HTMLs
    for i, img in ipairs(images) do
	local html = io.open(img.html, "w")
	local f = assert(io.open('plugins/gallery/gallery.lhtml'))
	local template = f:read("*a")
	f:close()

	local vars = {
	    prev = i == 1 and "" or string.format("<a class=\"lr left\" href=\"%s\">&lt;</a>",
		images[i-1].htmlbase),
	    ["next"] = i == #images and "" or string.format("<a class=\"lr right\" href=\"%s\">&gt;</a>", images[i+1].htmlbase),
	    top = string.format("<a href=\"%s/%s/%s.html\">%s</a>",
		config.url, page.directory, page.name, page.title),
	    img = "images/" .. img.imgname,
	    url = config.url,
	    title = page.title .. " - Image " .. i .. "/" .. #images,
	}
	local s = template:gsub("%$(%w+)", vars)
	html:write(s)
	html:close()
    end

    -- copy source images (if changed or missing)
    for i, img in ipairs(images) do
	_file_copy(img.source, img.dest)
    end

    -- copy style.css
    _file_copy('plugins/gallery/gallery.css',
	config.build_dir .. '/inc/gallery.css')

    -- build index (HTML code that replaces the plugin call)
    local tbl = {}
    for i, img in ipairs(images) do
	tbl[#tbl + 1] = string.format("<a href=\"%s\"><img src=\"%s\"></a>\n",
	    config.url .. "/gallery/" .. img.subdir .. "/" .. img.htmlbase,
	    config.url .. "/gallery/" .. img.subdir .. "/thumbs/" .. img.imgname)
    end

    -- protect from markdown
    return "<div>" .. table.concat(tbl) .. "</div>"
end

return process

