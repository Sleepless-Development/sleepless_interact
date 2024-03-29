local Groups = {}
local Loaded = false
local utils = require 'resources.[dev].sleepless_squads.moduless.utils'
local playerItems = utils.getItems()
local ox_inv = GetResourceState('ox_inventory'):find('start')
local ESX = exports.es_extended:getSharedObject()

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

    if not ox_inv and xPlayer.inventory then
        for _, v in pairs(xPlayer.inventory) do
            if v.count > 0 then
                playerItems[v.name] = v.count
            end
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

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local xPlayer = ESX.GetPlayerData()
        Wait(500)
        Groups = {
            [xPlayer.job.name] = xPlayer.job.grade,
        }
        TriggerEvent('sleepless_interact:updateGroups', Groups)
        MainLoop()
    end
end)

return Groups
