local config = {}

-- Maximum distance the indicator sprite renders.
config.maxInteractDistance = 5.0

-- Maximum indicator sprites drawn at once.
config.maxIndicators = 8

-- Only open the prompt when looking at the target.
config.requireLookAt = true

-- How close to the reticle the target must be.
config.lookRadius = 0.05

-- Place unoffset entity options at the model center.
config.autoCenter = true

-- Hide interacts the player cannot see.
config.requireLos = true

-- What blocks line of sight. 1 world, 2 vehicles, 4 peds, 16 objects.
config.losFlags = 17

-- How far collision in front of an ATM can be and still count as visible.
config.losShellDepth = 2.0

-- Draw line-of-sight debug.
config.debug = false

-- Hide the indicator when an interact type has no valid options.
config.hideWhenEmpty = {
	globalPeds = true,
	globalVehicles = true,
	globalObjects = true,
	globalPlayers = true,
	models = false,
	entities = false,
	localEntities = false,
	coords = false,
}

-- Size of the world prompt.
config.duiScale = 0.2

-- Maximum size of the prompt texture.
config.duiResolution = 2048

-- Prompt theme.
config.theme = 'modern'

-- Accent color for each theme.
config.themeColors = {
	legacy = { 28, 100, 184, 200 },
	modern = { 49, 164, 252, 255 },
	minimal = { 168, 186, 204, 255 },
	light = { 37, 99, 235, 255 },
	retro = { 255, 176, 32, 255 },
	cyber = { 0, 229, 255, 255 },
	vice = { 255, 64, 180, 255 },
	noir = { 240, 240, 236, 255 },
	industrial = { 212, 168, 48, 255 },
	fantasy = { 212, 175, 110, 255 },
}

-- Accent color used for every theme. Nil uses the theme color.
config.themeColor = nil

function config.getThemeColor()
	if config.themeColor then
		return config.themeColor
	end
	local colors = config.themeColors
	return (colors and colors[config.theme]) or { 49, 164, 252, 255 }
end

-- Show one Interact row until the menu is opened.
config.compactOptions = true

-- How long before a compact menu closes.
config.compactIdleMs = 2500

-- Default interact key.
config.defaultInteractKey = 'E'

-- Distant indicator sprite.
config.IndicatorSprite = {
	dict = 'slp_ind',
	txt = 'radio',
	file = 'web/indicator.png',
	rotation = 0.0,
	color = { 255, 255, 255, 220 },
	scale = 0.0085,
}

-- Dot drawn at the center of the screen.
config.CenterDot = {
	enabled = true,
	dict = 'mpcarhud',
	txt = 'leaderboard_car_colour_icon_singlecolour',
	color = { 255, 255, 255, 255 },
	scale = 0.004,
	x = 0.5,
	y = 0.5,
}

-- Use a key to show and hide interacts.
config.useShowKeyBind = false

-- Default key for showing interacts.
config.defaultShowKeyBind = 'LMENU'

-- Hold or toggle the show key.
config.showKeyBindBehavior = 'toggle'

return config
