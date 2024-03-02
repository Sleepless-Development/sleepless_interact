---@todo: this shit is probably useless

local sprites = {}

sprites.spriteDictName = 'sleepless_interact_sprites'
local txd = CreateRuntimeTxd(sprites.spriteDictName)
sprites.sprites = {
    indicator = 'indicator',
    interact = 'interact',
}

for _, texture in pairs(sprites.sprites) do
    CreateRuntimeTextureFromImage(txd, texture, string.format('imgs/%s.png', texture))
end

RegisterNetEvent('onResourceStop', function(resourceName)
    if not resourceName == GetCurrentResourceName() then return end
    SetStreamedTextureDictAsNoLongerNeeded('sleepless_interact_sprites')
end)

return sprites
