local Groups = {}
local Loaded = false
local utils = require 'imports.utils'
local playerItems = utils.getItems()
local ox_inv = GetResourceState('ox_inventory'):find('start')

RegisterNetEvent('esx:setPlayerData', function(key, value)
    if not Loaded or GetInvokingResource() ~= 'es_extended' then return end

    if key ~= 'job' then return end

    Groups = { [value.name] = value.grade }
    TriggerEvent('sleepless_interact:updateGroups', Groups)
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Groups = {
        [xPlayer.job.name] = xPlayer.job.grade,
    }
    Loaded = true

    if ox_inv or not xPlayer.inventory then return end

    for _, v in pairs(xPlayer.inventory) do
        if v.count > 0 then
            playerItems[v.name] = v.count
        end
    end
    
    TriggerEvent('sleepless_interact:updateGroups', Groups)
    TriggerEvent('sleepless_interact:LoadDui')
    MainLoop()
end)

RegisterNetEvent('esx:addInventoryItem', function(name, count)
    playerItems[name] = count
end)

RegisterNetEvent('esx:removeInventoryItem', function(name, count)
    playerItems[name] = count
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Groups = table.wipe(Groups)
end)

return Groups
