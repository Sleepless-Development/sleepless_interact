---@class InteractConfig
---@field color vector4 RGBA (R: 0-255, G: 0-255, B: 0-255, A: 0-255)
---@field defaultIndicatorSprite {dict: string, txt: string} non-active sprite dictionary/texture
---@field useShowKeyBind boolean true/false use a keybind to show and hide the interactions
---@field defaultShowKeyBind string default key mapping for the show interactions keybind
---@field showKeyBindBehavior "hold" | "toggle" sets the behavior of the show interactions key bind
local config = {}

config.color = vec4(28, 126, 214, 200)

config.defaultIndicatorSprite = { dict = 'shared', txt = 'emptydot_32' }

config.useShowKeyBind = false

config.defaultShowKeyBind = 'LMENU'

config.showKeyBindBehavior = 'hold'


return config
