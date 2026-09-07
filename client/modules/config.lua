local config = {}

-- this is the maximum distance that interacts will render the indicator sprite (little cirlce)
-- recommend keeping this pretty low for optimization
config.maxInteractDistance = 5.0

-- Visual theme for the world prompt.
-- Built-in: legacy | modern | minimal | light | retro | cyber | vice | noir | industrial | fantasy
-- To add another look later, drop a file at web/themes/<id>.css
-- using [data-theme="<id>"] selectors, then set this to that id.
config.theme = 'modern'

-- Default accent per theme. Used by the HUD and the world indicator sprite.
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

--- texture dictionary and texture name for the sprite used to show non active interactions.
config.IndicatorSprite = { dict = 'shared', txt = 'emptydot_32' }

-- boolean true/false use a keybind to show and hide the interactions
config.useShowKeyBind = false

-- string default key mapping for the show interactions keybind
config.defaultShowKeyBind = 'LMENU'

-- "hold" | "toggle" sets the behavior of the show interactions key bind
config.showKeyBindBehavior = 'toggle'

return config