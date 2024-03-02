local globals = require 'imports.globals'
local dui = require 'imports.dui'
local Vehicles = require '@ox_inventory.data.vehicles'
local ox = GetResourceState('ox_inventory'):find('start')
local Groups

local utils = {}
---@param action string
---@param data any
utils.sendReactMessage = function(action, data)
    while not dui.DuiObject do Wait(1) end
    SendDuiMessage(dui.DuiObject, json.encode({
        action = action,
        data = data
    }))
end

RegisterNetEvent('demi_interact:updateGroups', function(update)
    Groups = update
end)

utils.checkGroups = function(interactionGroups)
    if not interactionGroups then return true end

    for group, grade in pairs(Groups) do
        if interactionGroups[group] and grade >= interactionGroups[group] then
            return true
        end
    end

    return false
end

utils.loadInteractionData = function(data)
    local newData = {
        renderDistance = 5.0,
        activeDistance = 1.0,
        cooldown = 1000,
    }

    for i, v in pairs(data) do
        newData[i] = v
    end

    return newData
end

local function processEntity(entity, entType)
    if entType == 'player' then
        local playerInteractions = lib.table.deepclone(globals.playerInteractions)
        if next(playerInteractions) then
            local player = NetworkGetPlayerIndex(entity)
            local serverid = GetPlayerServerId(player)
            if globals.cachedPlayers[serverid] then return end

            globals.cachedPlayers[serverid] = true
            for i = 1, #playerInteractions do
                local interaction = playerInteractions[i]
                interaction.id = interaction.id .. serverid
                interaction.netId = NetworkGetNetworkIdFromEntity(entity)
                interact.addEntity(interaction)
            end
            return
        end
    end

    if entType == 'ped' then
        local pedInteractions = lib.table.deepclone(globals.pedInteractions)
        if next(pedInteractions) then
            local isNet = NetworkGetEntityIsNetworked(entity)
            local key = isNet and PedToNet(entity) or entity
            if globals.cachedPeds[key] then return end

            globals.cachedPeds[key] = true
            for i = 1, #pedInteractions do
                local interaction = pedInteractions[i]
                interaction.id = interaction.id .. key
                print(interaction.id)
                if isNet then
                    interaction.netId = key
                    interact.addEntity(interaction)
                else
                    interaction.entity = entity
                    interact.addLocalEntity(interaction)
                end
            end
            return
        end
    end

    if entType == 'vehicle' then
        local isVehicle = IsEntityAVehicle(entity)
        local vehicleInteractions = lib.table.deepclone(globals.vehicleInteractions)
        if isVehicle and next(vehicleInteractions) then
            local netId = NetworkGetNetworkIdFromEntity(entity)
            if globals.cachedVehicles[netId] then return end

            globals.cachedVehicles[netId] = true
            for i = 1, #vehicleInteractions do
                local interaction = vehicleInteractions[i]
                if ox and interaction.bone == 'boot' then
                    if utils.getTrunkPosition(NetworkGetEntityFromNetworkId(netId)) then
                        interaction.netId = netId
                        interaction.id = interaction.id .. netId
                        interact.addEntity(interaction)
                    end
                else
                    interaction.netId = netId
                    interaction.id = interaction.id .. netId
                    interact.addEntity(interaction)
                end
            end
            return
        end
    end

    local model = GetEntityModel(entity)
    local modelInteractions = globals.Models[model]
    if modelInteractions then
        local modelInteractions = lib.table.deepclone(modelInteractions)
        local isNet = NetworkGetEntityIsNetworked(entity)
        local key = isNet and NetworkGetNetworkIdFromEntity(entity) or entity
        if globals.cachedModelEntities[key] then return end

        globals.cachedModelEntities[key] = true
        for i = 1, #modelInteractions do
            local modelInteraction = modelInteractions[i]
            modelInteraction.model = model
            modelInteraction.id = modelInteraction.id .. key
            if isNet then
                modelInteraction.netId = key
                interact.addEntity(modelInteraction)
            else
                interact.addLocalEntity(modelInteraction)
            end
        end
    end
end

function utils.checkEntities() --0.01-0.02ms overhead. not sure how to do it better.
    local coords = cache.coords or GetEntityCoords(cache.ped)

    CreateThread(function()
        local objects = lib.getNearbyObjects(coords, 15.0)
        if #objects > 0 then
            for i = 1, #objects do
                ---@diagnostic disable-next-line: undefined-field
                local entity = objects[i].object
                processEntity(entity)
            end
        end
    end)

    CreateThread(function()
        local vehicles = lib.getNearbyVehicles(coords, 4.0)
        if #vehicles > 0 then
            for i = 1, #vehicles do
                ---@diagnostic disable-next-line: undefined-field
                local entity = vehicles[i].vehicle
                processEntity(entity, 'vehicle')
            end
        end
    end)

    CreateThread(function()
        local players = lib.getNearbyPlayers(coords, 4.0, false)
        if #players > 0 then
            for i = 1, #players do
                ---@diagnostic disable-next-line: undefined-field
                local entity = players[i].ped
                processEntity(entity, 'player')
            end
        end
    end)

    CreateThread(function()
        local peds = lib.getNearbyPeds(coords, 4.0)
        if #peds > 0 then
            for i = 1, #peds do
                ---@diagnostic disable-next-line: undefined-field
                local entity = peds[i].ped
                processEntity(entity, 'ped')
            end
        end
    end)
end

utils.checkOptions = function(interaction)
    local disabledCount = 0
    local optionsLength = #interaction.options
    local shouldUpdateUI
    for i = 1, optionsLength do
        local option = interaction.options[i]
        if option.canInteract then
            local disabled = option.canInteract(interaction.getEntity and interaction:getEntity(),
                interaction.currentDistance, interaction.coords, interaction.id) == false
            if disabled ~= interaction.textOptions[i].disable then
                shouldUpdateUI = disabled ~= interaction.textOptions[i].disable
            end
            interaction.textOptions[i].disable = disabled
            if disabled then disabledCount += 1 end
        end
    end

    if shouldUpdateUI then
        dui.updateMenu('updateInteraction', {
            id = interaction.id,
            options = (interaction.action and {}) or interaction.textOptions
        })
    end

    return disabledCount < optionsLength
end


local backDoorIds = { 2, 3 }
utils.getTrunkPosition = function(entity)
    local vehicleHash = GetEntityModel(entity)
    local vehicleClass = GetVehicleClass(entity)
    local checkVehicle = Vehicles.Storage[vehicleHash]

    if (checkVehicle == 0 or checkVehicle == 1) or (not Vehicles.trunk[vehicleClass] and not Vehicles.trunk.models[vehicleHash]) then return end

    ---@type number | number[]
    local doorId = checkVehicle and 4 or 5

    if not Vehicles.trunk.boneIndex?[vehicleHash] and not GetIsDoorValid(entity, doorId --[[@as number]]) then
        if vehicleClass ~= 11 and (doorId ~= 5 or GetEntityBoneIndexByName(entity, 'boot') ~= -1 or not GetIsDoorValid(entity, 2)) then
            return
        end

        if vehicleClass ~= 11 then
            doorId = backDoorIds
        end
    end

    local min, max = GetModelDimensions(vehicleHash)
    local offset = (max - min) * (not checkVehicle and vec3(0.5, 0, 0.5) or vec3(0.5, 1, 0.5)) + min
    return GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
end

return utils
