-- FX Information
fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

version '2.0.2'

shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
	'init.lua',
	'client/*.lua',
}

files {
	'web/**',
	'client/modules/*.lua',
	'client/framework/*.lua',
}

provides {
    'ox_target'
}
