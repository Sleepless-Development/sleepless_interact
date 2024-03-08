fx_version "cerulean"
use_experimental_fxv2_oal 'yes'
game 'gta5'
lua54 'yes'

version '0.1.4'

shared_script "@ox_lib/init.lua"

files {
	'web/build/index.html',
	'web/build/**/*',
	'imgs/*',
	'@ox_inventory/data/vehicles.lua',
	'imports/*.lua',
	'classes/*.lua',
	'bridge/**/client.lua'
}

server_scripts {
	'server/*.lua'
}

client_script {
	'bridge/init.lua',
	"init.lua",
	'exports/*.lua',
	'client/*.lua',
}