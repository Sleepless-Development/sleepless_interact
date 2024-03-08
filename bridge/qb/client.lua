local QBCore = exports['qb-core']:GetCoreObject()
local Groups = {}
local Player = {}
local utils = require 'imports.utils'
local playerItems = utils.getItems()
local ox_inv = GetResourceState('ox_inventory'):find('start')

local function setPlayerItems(data)
    if not data or not data.items then return end

    table.wipe(playerItems)

    for _, item in pairs(data.items) do
        playerItems[item.name] = (playerItems[item.name] or 0) + (item.amount or 0)
    end
end

local function updateJob(job)
    if not Player.Group then return end

    Groups[Player.job] = nil
    Groups[job.name] = job.grade.level
    Player.job = job.name
    TriggerEvent('sleepless_interact:updateGroups', Groups)
end

local function updateGang(gang)
    if not Player.Group then return end

    Groups[Player.gang] = nil
    Groups[gang.name] = gang.grade.level
    Player.gang = gang.name
    TriggerEvent('sleepless_interact:updateGroups', Groups)
end

RegisterNetEvent('QBCore:Player:SetPlayerData', function(playerData)
    if source == '' then return end
    updateJob(playerData.job)
    updateGang(playerData.gang)
    if not ox_inv then setPlayerItems(playerData) end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()

    Groups = {
        [PlayerData.job.name] = PlayerData.job.grade.level,
        [PlayerData.gang.name] = PlayerData.gang.grade.level
    }
    Player = {
        job = PlayerData.job.name,
        gang = PlayerData.gang.name,
    }

    if not ox_inv then setPlayerItems(PlayerData) end

    TriggerEvent('sleepless_interact:updateGroups', Groups)
    TriggerEvent('sleepless_interact:LoadDui')
    MainLoop()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Groups = table.wipe(Groups)
    Player = table.wipe(Player)
end)


AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local PlayerData = QBCore.Functions.GetPlayerData()

        Groups = {
            [PlayerData.job.name] = PlayerData.job.grade.level,
            [PlayerData.gang.name] = PlayerData.gang.grade.level
        }
        Player = {
            job = PlayerData.job.name,
            gang = PlayerData.gang.name,
        }

        if not ox_inv then setPlayerItems(PlayerData) end
        
        TriggerEvent('sleepless_interact:updateGroups', Groups)
        MainLoop()
    end
end)

return Groups
