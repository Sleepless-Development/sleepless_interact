local dui = require 'imports.dui'
local store = require 'imports.store'
local updateMenu = dui.updateMenu
local Groups = {}

---@class InteractUtils
local utils = {}

RegisterNetEvent('sleepless_interact:updateGroups', function(update)
    Groups = update
end)

local globalTableMap = {
    ['vehicle'] = { interactions = store.globalVehicle, cache = store.cachedVehicles },
    ['player'] = { interactions = store.globalPlayer, cache = store.cachedPlayers },
    ['ped'] = { interactions = store.globalPed, cache = store.cachedPeds },
    ['object'] = { cache = store.cachedObjects }
}

utils.shouldHideInteractions = function()
    if IsNuiFocused() or LocalPlayer.state.interactBusy or (store.ox_lib and (lib.progressActive() or cache.vehicle)) or store.hidePerKeybind or LocalPlayer.state.invOpen then
        return true
    end
    return false
end

utils.updateGlobalInteraction = function(type, data)
    local context = globalTableMap[type]

    local interactions = context.interactions

    for i = 1, #interactions do
        if data.id == interactions[i].id then
            interactions[i] = data
        end
    end

    local cache = context.cache

    for entityKey, _ in pairs(cache) do
        if cache?[entityKey]?[data.id] then
            cache[entityKey][data.id] = nil
        end
    end
end

utils.wipeCacheForEntityKey = function(globalType, entityKey, id)
    local cache = globalTableMap[globalType]?.cache

    if not cache then return end

    if id then
        id = id:gsub(':' .. entityKey, '')
        if cache[entityKey]?[id] then
            cache[entityKey][id] = nil
        end
    else
        if cache[entityKey] then
            cache[entityKey] = {}
        end
    end
end

utils.loadInteractionDefaults = function(data, resource)
    data.id             = data.id or data.name
    data.label          = data.label or data.text or ''
    data.remove         = data.remove or data.destroy
    data.onSelect       = data.onSelect or data.action
    data.text           = nil
    data.destroy        = nil
    data.action         = nil
    data.renderDistance = data.renderDistance or 5.0
    data.activeDistance = data.activeDistance or data.distance or 1.0
    data.cooldown       = data.cooldown or 1000
    data.resource       = data.resource or resource or 'sleepless_interact'
    data.options        = nil

    local idType        = type(data.id)
    assert(idType == "string",
        string.format('unexpected type for id. string expected. got %s',
            idType))

    if type(data.bones) == 'table' then
        local entity = (data.netId and NetworkGetEntityFromNetworkId(data.netId)) or data.entity
        if DoesEntityExist(entity) then
            local foundBone = nil
            for i = 1, #data.bones do
                local bone = data.bones[i]
                if GetEntityBoneIndexByName(entity, bone) ~= -1 then
                    foundBone = bone
                    break
                end
            end
            data.bones = foundBone
        end
    end
end

local function processEntity(entity, entType)
    local isNet = NetworkGetEntityIsNetworked(entity)
    local entityKey = isNet and NetworkGetNetworkIdFromEntity(entity) or entity
    local interactions = {}
    local model = GetEntityModel(entity)

    entType = entType or 'object'

    local context = globalTableMap[entType]
    local globalTable = context.interactions
    local cache = context.cache

    if not cache[entityKey] then
        cache[entityKey] = {}
    end

    if globalTable then
        for i = 1, #globalTable do
            local data = globalTable[i]
            if not cache[entityKey][data.id] and (not data.removeWhenDead or not IsEntityDead(entity)) then
                cache[entityKey][data.id] = true
                if store.ox_inv and data.id == 'ox:Trunk' then
                    if utils.getTrunkPosition(entity) then
                        local interactionData = lib.table.clone(data)
                        interactions[#interactions + 1] = interactionData
                    end
                else
                    local interactionData = lib.table.clone(data)
                    interactions[#interactions + 1] = interactionData
                end
            end
        end
    end

    if store.globalModels[model] then
        for i = 1, #store.globalModels[model] do
            local data = store.globalModels[model][i]
            if not cache[entityKey][data.id] and (not data.removeWhenDead or not IsEntityDead(entity)) then
                cache[entityKey][data.id] = true
                local interactionData = lib.table.clone(data)
                interactions[#interactions + 1] = interactionData
            end
        end
    end

    if next(interactions) then
        for i = 1, #interactions do
            local interactionData = interactions[i]
            interactionData.id = string.format('%s:%s', interactionData.id, entityKey)
            interactionData.globalType = entType
            if isNet then
                interactionData.netId = entityKey
                interact.addEntity(interactionData)
            else
                interactionData.entity = entityKey
                interact.addLocalEntity(interactionData)
            end
        end
    end
end

utils.checkEntities = function()
    local coords = cache.coords or GetEntityCoords(cache.ped)


    local objects = lib.getNearbyObjects(coords, 15.0)
    if #objects > 0 then
        for i = 1, #objects do
            ---@diagnostic disable-next-line: undefined-field
            local entity = objects[i].object
            processEntity(entity)
        end
    end

    local vehicles = lib.getNearbyVehicles(coords, 4.0)
    if #vehicles > 0 then
        for i = 1, #vehicles do
            ---@diagnostic disable-next-line: undefined-field
            local entity = vehicles[i].vehicle
            processEntity(entity, 'vehicle')
        end
    end

    local players = lib.getNearbyPlayers(coords, 4.0, false)
    if #players > 0 then
        for i = 1, #players do
            ---@diagnostic disable-next-line: undefined-field
            local entity = players[i].ped
            processEntity(entity, 'player')
        end
    end

    local peds = lib.getNearbyPeds(coords, 4.0)
    if #peds > 0 then
        for i = 1, #peds do
            ---@diagnostic disable-next-line: undefined-field
            local entity = peds[i].ped
            processEntity(entity, 'ped')
        end
    end
end


local checkGroups = function(interactionGroups)
    if not interactionGroups then return true end

    for group, grade in pairs(Groups) do
        if type(interactionGroups) == "string" then
            if interactionGroups == group then
                return true
            end
        elseif type(interactionGroups) == "table" then
            if table.type(interactionGroups) == "array" then
                if interactionGroups[group] then
                    return true
                end
            elseif interactionGroups[group] and grade >= interactionGroups[group] then
                return true
            end
        end
    end

    return false
end

local playerItems = {}

utils.getItems = function()
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

utils.checkOptions = function(interaction)
    local shouldUpdateUI = false

    local option = interaction
    local disabled = false

    if option.canInteract then
        local success, resp = pcall(option.canInteract, interaction.getEntity and interaction:getEntity(),
            interaction.currentDistance, interaction:getCoords(), interaction.id)

        disabled = not success or not resp
    end

    if not disabled and option.groups then
        disabled = not checkGroups(option.groups)
    end

    if not disabled and option.items then
        disabled = not checkItems(option.items, option.anyItem)
    end

    if interaction.DuiOptions and disabled ~= interaction.DuiOptions.disable then
        interaction.DuiOptions.disable = disabled
        shouldUpdateUI = true
    end

    if interaction.isActive and not disabled and shouldUpdateUI then
        updateMenu('updateInteraction', {
            id = interaction.id,
            options = interaction.action and {} or { interaction.DuiOptions }
        })
    end

    return not disabled
end

if store.ox_inv then
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

return utils
