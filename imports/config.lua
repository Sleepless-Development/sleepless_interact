---@class InteractConfig
---@field color vector4 RGBA (R: 0-255, G: 0-255, B: 0-255, A: 0-255)
---@field indicatorSprite {dict: string, txt: string} non-active sprite dictionary/texture
local config = {}

config.color = vec4(28, 126, 214, 200)

config.indicatorSprite = { dict = 'shared', txt = 'emptydot_32' }

return config
