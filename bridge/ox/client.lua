local file = ('imports/%s.lua'):format('client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))

chunk()

local Groups = {}

RegisterNetEvent('ox:setGroup', function(name, grade)
    Groups[name] = grade
    TriggerEvent('demi_interact:updateGroups', Groups)
end)

AddEventHandler('ox:playerLoaded', function()
    Groups = Ox.GetPlayerData().groups
    TriggerEvent('demi_interact:updateGroups', Groups)
    TriggerEvent('demi_interact:LoadDui')
    MainLoop()
end)

AddEventHandler('ox:playerLogout', function()
    table.wipe(Groups)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(500)
        Groups = Ox.GetPlayerData().groups
        TriggerEvent('demi_interact:updateGroups', Groups)
        MainLoop()
    end
end)

return Groups
