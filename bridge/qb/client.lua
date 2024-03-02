local QBCore = exports['qb-core']:GetCoreObject()
local Groups = {}
local Player = {}

-- Group Updaters --
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not Player.Group then return end

    Groups[Player.job] = nil
    Groups[job.name] = job.grade.level
    Player.job = job.name
    TriggerEvent('sleepless_interact:updateGroups', Groups)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    if not Player.Group then return end

    Groups[Player.gang] = nil
    Groups[gang.name] = gang.grade.level
    Player.gang = gang.name
    TriggerEvent('sleepless_interact:updateGroups', Groups)
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
    TriggerEvent('sleepless_interact:updateGroups', Groups)
    TriggerEvent('sleepless_interact:LoadDui')
    MainLoop()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Groups = table.wipe(Groups)
    Player = table.wipe(Player)
end)

return Groups
