local config = {}

-- this is the maximum distance that interacts will render the indicator sprite (little cirlce)
-- recommend keeping this pretty low for optimization
config.maxInteractDistance = 5.0

-- If true, the prompt only opens when the target is inside lookRadius of the reticle.
config.requireLookAt = true

-- Screen-space radius from the reticle (fraction of screen height). Raise it to aim looser.
config.lookRadius = 0.05

-- If true, entity options without offset, offsetAbsolute, or bones are placed
-- at the model bounding-box center instead of the entity origin.
config.autoCenter = true

-- If true, interacts are hidden when the player has no clear line of sight.
-- Entity targets test LOS to the entity. Coord targets test LOS to the point.
config.requireLos = true

-- Shape-test flags for requireLos. 1 world, 2 vehicles, 4 peds, 16 objects.
-- 17 (world + objects) blocks walls and props without peds/vehicles eating LOS.
config.losFlags = 17

-- Hide the distant marker when this interact type currently has no valid options
-- (canInteract, distance, groups, items, in-vehicle).
-- true  = hide the sprite
-- false = keep the sprite as a point of interest
-- An option's hideWhenEmpty field overrides the type default.
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

-- World size of the prompt sprite.
config.duiScale = 0.7

-- Visual theme for the world prompt.
-- Built-in: legacy | modern | minimal | light | retro | cyber | vice | noir | industrial | fantasy
-- To add another look later, drop a file at web/themes/<id>.css
-- using [data-theme="<id>"] selectors, then set this to that id.
config.theme = 'modern'

-- Default accent per theme. Used by the HUD highlight.
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

-- Optional override for every theme. Set to { r, g, b, a } to force one accent
-- across all looks. Leave nil to use the theme's own color above.
config.themeColor = nil

function config.getThemeColor()
	if config.themeColor then
		return config.themeColor
	end
	local colors = config.themeColors
	return (colors and colors[config.theme]) or { 49, 164, 252, 255 }
end

-- If true, targets with more than one option show "Interact" until E is pressed.
-- The list expands, then collapses after a selection or a short idle.
-- If false, every option is shown immediately.
config.compactOptions = true

-- Milliseconds of no menu activity before a compact list collapses.
config.compactIdleMs = 2500

-- Default key for the interact action. Players can rebind this in GTA Settings > Key Bindings > FiveM.
-- The prompt reads the live mapping, so the HUD shows whatever they bind.
config.defaultInteractKey = 'E'

-- Distant / inactive marker. `file` loads a PNG from this resource as a runtime texture.
-- color tints the texture; white on a white PNG stays white.
config.IndicatorSprite = {
	dict = 'slp_ind',
	txt = 'radio',
	file = 'web/indicator.png',
	rotation = 0.0,
	color = { 255, 255, 255, 200 },
	scale = 0.011,
}

-- Screen-center pip while in range of a usable interact.
config.CenterDot = {
	enabled = true,
	dict = 'mpcarhud',
	txt = 'leaderboard_car_colour_icon_singlecolour',
	color = { 255, 255, 255, 255 },
	scale = 0.004,
	x = 0.5,
	y = 0.5,
}

-- boolean true/false use a keybind to show and hide the interactions
config.useShowKeyBind = false

-- string default key mapping for the show interactions keybind
config.defaultShowKeyBind = 'LMENU'

-- "hold" | "toggle" sets the behavior of the show interactions key bind
config.showKeyBindBehavior = 'toggle'

return config
