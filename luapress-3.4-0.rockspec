package = 'Luapress'
version = '3.4-0'

source = {
    url = 'git://github.com/Fizzadar/Luapress.git',
    tag = 'v3.4'
}

description = {
    summary = 'Luapress builds static sites from markdown files',
    homepage = 'https://github.com/Fizzadar/Luapress',
    license =   'MIT'
}

dependencies = {
    'lua >= 5.1',
    'luafilesystem',
    'lustache',
    'ansicolors'
}

build = {
    type = 'builtin',
    modules = {
        ['luapress'] = 'luapress/luapress.lua'
    },
    install = {
        lua = {
            ['luapress.config'] = 'luapress/config.lua',
            ['luapress.template'] = 'luapress/template.lua',
            ['luapress.util'] = 'luapress/util.lua',
            ['luapress.default_config'] = 'luapress/default_config.lua',
            ['luapress.lib.markdown'] = 'luapress/lib/markdown.lua',
            ['luapress.lib.table_to_lua'] = 'luapress/lib/table_to_lua.lua',
            ['luapress.lib.watch_directory'] = 'luapress/lib/watch_directory.lua',
            ['luapress.lib.cli'] = 'luapress/lib/cli.lua'
        },
        bin = {
            'bin/luapress'
        }
    },
    copy_directories = {
        'plugins',
        'template'
    }
}
