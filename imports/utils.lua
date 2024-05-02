local globals = require 'imports.globals'
local dui = require 'imports.dui'
local DuiObject, updateMenu in dui
local ox_inv = GetResourceState('ox_inventory'):find('start')
local Groups = {}

---@class InteractUtils
local utils = {}

utils.sendReactMessage = function(action, data)
    while not DuiObject do Wait(1) end
    SendDuiMessage(DuiObject, json.encode({
        action = action,
        data = data
    }))
end

RegisterNetEvent('sleepless_interact:updateGroups', function(update)
    Groups = update
end)

utils.getActionData = function (interaction)
    local response = {}
    
    response.id = interaction.id
    response.entity = interaction.entity
    response.coords = interaction:getCoords()
    response.distance = interaction.currentDistance
    
    return response
end

utils.loadInteractionData = function(data, resource)
    data.resource = data.resource or resource or 'sleepless_interact'
    data.renderDistance = data.renderDistance or 5.0
    data.activeDistance = data.activeDistance or 1.0
    data.cooldown = data.cooldown or 1000

    if type(data.bone) == 'table' then
        local entity = (data.netId and NetworkGetEntityFromNetworkId(data.netId)) or data.entity
        if DoesEntityExist(entity) then
            local foundBone = nil
            for i = 1, #data.bone do
                local bone = data.bone[i]
                if GetEntityBoneIndexByName(entity, bone) ~= -1 then
                    foundBone = bone
                    break
                end
            end
            data.bone = foundBone
        end
    end
    return data
end

local function processEntity(entity, entType)

    local isNet = NetworkGetEntityIsNetworked(entity)
    local key = isNet and NetworkGetNetworkIdFromEntity(entity) or entity

    if entType == 'player' then
        if next(globals.playerInteractions) then
            local player = NetworkGetPlayerIndex(entity)
            local serverid = GetPlayerServerId(player)
            if globals.cachedPlayers[serverid] then return end

            globals.cachedPlayers[serverid] = true
            for i = 1, #globals.playerInteractions do
                local interaction = lib.table.clone(globals.playerInteractions[i])
                interaction.id = string.format('%s:%s', interaction.id, serverid)
                interaction.netId = NetworkGetNetworkIdFromEntity(entity)
                interact.addEntity(interaction)
            end
        end
    end

    if entType == 'ped' then
        if next(globals.pedInteractions) then
            if globals.cachedPeds[key] then return end

            globals.cachedPeds[key] = true
            for i = 1, #globals.pedInteractions do
                local interaction = lib.table.clone(globals.pedInteractions[i])
                interaction.id = string.format('%s:%s', interaction.id, key)
                if isNet then
                    interaction.netId = key
                    interact.addEntity(interaction)
                else
                    interaction.entity = entity
                    interact.addLocalEntity(interaction)
                end
            end
        end
    end

    if entType == 'vehicle' then
        local isVehicle = IsEntityAVehicle(entity)
        if isVehicle and next(globals.vehicleInteractions) then
            if globals.cachedVehicles[key] then return end

            globals.cachedVehicles[key] = true
            for i = 1, #globals.vehicleInteractions do
                local interaction = lib.table.clone(globals.vehicleInteractions[i])
                interaction.id = string.format('%s:%s', interaction.id, key)
                if ox_inv and interaction.bone == 'boot' and utils.getTrunkPosition(entity) then
                    if isNet then
                        interaction.netId = key
                        interact.addEntity(interaction)
                    else
                        interaction.entity = key
                        interact.addLocalEntity(interaction)
                    end
                else
                    if isNet then
                        interaction.netId = key
                        interact.addEntity(interaction)
                    else
                        interaction.entity = key
                        interact.addLocalEntity(interaction)
                    end
                end
            end
        end
    end

    local model = GetEntityModel(entity)
    if globals.Models[model] then
        if not globals.cachedModelEntities[model] then
            globals.cachedModelEntities[model] = {}
        end
        if globals.cachedModelEntities[model][key] then return end

        globals.cachedModelEntities[model][key] = true

        for i = 1, #globals.Models[model] do
            local modelInteraction = lib.table.clone(globals.Models[model][i])
            modelInteraction.model = model
            modelInteraction.id = string.format('%s:%s:%s', modelInteraction.id, model, key)
            if isNet then
                modelInteraction.netId = key
                interact.addEntity(modelInteraction)
            else
                modelInteraction.entity = key
                interact.addLocalEntity(modelInteraction)
            end
        end
    end
end

utils.checkEntities = function ()
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


local checkGroups = function(interactionGroups)
    if not interactionGroups then return true end

    for group, grade in pairs(Groups) do
        if interactionGroups[group] and grade >= interactionGroups[group] then
            return true
        end
    end

    return false
end

local playerItems = {}

utils.getItems = function ()
    return playerItems
end

---Thanks linden https://github.com/overextended
local checkItems = function(items, any)
    if not playerItems then return true end

    local _type = type(items)

    if _type == 'string' then
        return (playerItems[items] or 0) > 0
    elseif _type == 'table' then
        local tabletype = table.type(items)

        if tabletype == 'hash' then
            for name, amount in pairs(items) do
                local hasItem = (playerItems[name] or 0) >= amount

                if any then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #items do
                local hasItem = (playerItems[items[i]] or 0) > 0

                if items then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        end
    end

    return not any
end

utils.checkOptions = function (interaction)
    local disabledOptionsCount = 0
    local optionsLength = #interaction.options
    local shouldUpdateUI = false

    for i = 1, optionsLength do
        local option = interaction.options[i]
        local disabled = false
        
        if option.canInteract then
            local success, response = pcall(option.canInteract, interaction.getEntity and interaction:getEntity(), interaction.currentDistance, interaction.coords, interaction.id)
            disabled = not success or not response
        end

        if not disabled and option.groups then
            disabled = not checkGroups(option.groups)
        end

        if not disabled and option.items then
            disabled = not checkItems(option.items, option.anyitem)
        end

        if disabled ~= interaction.textOptions[i].disable then
            interaction.textOptions[i].disable = disabled
            shouldUpdateUI = true
        end
        
        if disabled then
            disabledOptionsCount += 1
        end
    end

    if interaction.isActive and disabledOptionsCount < optionsLength and shouldUpdateUI then
        updateMenu('updateInteraction', {
            id = interaction.id,
            options = interaction.action and {} or interaction.textOptions
        })
    end

    return disabledOptionsCount < optionsLength
end

if ox_inv then
    setmetatable(playerItems, {
        __index = function(self, index)
            self[index] = exports.ox_inventory:Search('count', index) or 0
            return self[index]
        end
    })

    AddEventHandler('ox_inventory:itemCount', function(name, count)
        playerItems[name] = count
    end)
    local Vehicles = require '@ox_inventory.data.vehicles'
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
end

utils.clearCacheForInteractionEntity = function (interaction)
    if interaction.getEntity then
        local key = interaction.netId or interaction:getEntity()
        
        if interaction.model and globals.cachedModelEntities[interaction.model] then
            globals.cachedModelEntities[interaction.model][key] = nil
        end
        globals.cachedPeds[key] = nil
        globals.cachedPlayers[key] = nil
        globals.cachedVehicles[key] = nil
    end
end

return utils
