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
    local idType = type(data.id)
    assert(
        idType == "string" or idType == 'number',
        string.format('unexpected type for id. expected string or number. got %s', idType)
    )

    local optionsType = type(data.options)
    assert(optionsType == "table" and lib.table.type(data.options) == 'array',
        string.format('unexpected type for options. array expected. got %s',
            (optionsType == "table" and lib.table.type(data.options)) or optionsType))


    for i = 1, #data.options do --backwards compatibility
        data.options[i].label = data.options[i].label or data.options[i].text or ''
        data.options[i].remove = data.options[i].remove or data.options[i].destroy
        data.options[i].onSelect = data.options[i].onSelect or data.options[i].action
        data.options[i].text = nil
        data.options[i].destroy = nil
        data.options[i].action = nil
    end


    data.renderDistance = data.renderDistance or 5.0
    data.activeDistance = data.activeDistance or 1.0
    data.cooldown       = data.cooldown or 1000
    data.resource       = data.resource or resource or 'sleepless_interact'

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
        if interactionGroups[group] and grade >= interactionGroups[group] then
            return true
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
    print(any)
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
    local disabledOptionsCount = 0
    local optionsLength = #interaction.options
    local shouldUpdateUI = false

    for i = 1, optionsLength do
        local option = interaction.options[i]
        local disabled = false
        -- print(option.label)
        if option.canInteract then
            local success, resp = pcall(option.canInteract, interaction.getEntity and interaction:getEntity(), interaction.currentDistance, interaction.coords, interaction.id)
            disabled = not success or not resp
        end

        if not disabled and option.groups then
            disabled = not checkGroups(option.groups)
        end

        if not disabled and option.items then
            disabled = not checkItems(option.items, option.anyItem)
        end

        if interaction.DuiOptions[i] and disabled ~= interaction.DuiOptions[i].disable then
            interaction.DuiOptions[i].disable = disabled
            shouldUpdateUI = true
        end

        if disabled then
            disabledOptionsCount += 1
        end
    end

    if interaction.isActive and disabledOptionsCount < optionsLength and shouldUpdateUI then
        updateMenu('updateInteraction', {
            id = interaction.id,
            options = interaction.action and {} or interaction.DuiOptions
        })
    end

    return disabledOptionsCount < optionsLength
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
