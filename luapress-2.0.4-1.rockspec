package = 'Luapress'
version = '2.0.4-1'

source = {
    url = 'git://github.com/Fizzadar/luapress.git',
    tag = 'v2.0.4'
}

description = {
    summary = 'Luapress builds static blogs from markdown files',
    homepage = 'https://github.com/Fizzadar/luapress',
    license =   'MIT'
}

dependencies = {
    'lua >= 5.1',
    'alt-getopt',
    'luafilesystem'
}

build = {
    type = 'builtin',
    modules = {
        ['luapress'] = 'luapress/press.lua'
    },
    install = {
        lua = {
            ['luapress.config'] = 'luapress/config.lua',
            ['luapress.template'] = 'luapress/template.lua',
            ['luapress.util'] = 'luapress/util.lua',
            ['luapress.default_template'] = 'luapress/default_template.lua',
            ['luapress.lib.markdown'] = 'luapress/lib/markdown.lua'
        },
        bin = {
            'bin/luapress'
        }
    }
}
