---@diagnostic disable: undefined-field
local CoordsInteraction = require 'classes.coordsInteraction'
local NetEntityInteraction = require 'classes.netEntityInteraction'
local LocalEntityInteraction = require 'classes.localEntityInteraction'
local utils = require 'imports.utils'
local store = require 'imports.store'

--STATIC COORDS INTERACTION

---static coords interaction
function interact.addCoords(data)
    local coordsType = type(data.coords)
    assert(
        coordsType == 'vector3' or coordsType == "table" and lib.table.type(data.coords) == 'array',
        string.format('unexpected type for coords. expected vector3 or vector3 array. got %s',
            (coordsType == "table" and lib.table.type(data.coords)) or coordsType)
    )

    local optionsType = type(data.options)
    assert(optionsType == "table" and lib.table.type(data.options) == 'array',
        string.format('unexpected type for options. array expected. got %s',
            (optionsType == "table" and lib.table.type(data.options)) or optionsType))


    local toReturn = {}

    for _, option in ipairs(data.options) do
        local clone = lib.table.clone(data)
        local merge = lib.table.merge(clone, option, false)

        utils.loadInteractionDefaults(merge, GetInvokingResource())

        if coordsType == 'table' then
            for i = 1, #data.coords do
                local interactionData = lib.table.clone(merge)
                interactionData.coords = data.coords[i]
                interactionData.id = string.format("%s:%s", merge.id, i)

                local newInteraction = CoordsInteraction:new(interactionData)

                if newInteraction.id then
                    table.insert(store.Interactions, newInteraction)
                    toReturn[#toReturn + 1] = newInteraction.id
                end
            end
        else
            local newInteraction = CoordsInteraction:new(merge)
            if newInteraction.id then
                table.insert(store.Interactions, newInteraction)
                toReturn[#toReturn + 1] = newInteraction.id
            end
        end
    end

    return toReturn
end

--LOCAL NON_NETWORKED ENTITY INTERACTIONS

---add interaction for local non-networked entity
function interact.addLocalEntity(data)
    local entityType = type(data.entity)
    assert(
        entityType == 'number',
        string.format('unexpected type for entity. expected number. got %s', entityType)
    )
    assert(
        DoesEntityExist(data.entity),
        string.format('Entity: %s Did Not Exist For addLocalEntity', data.entity)
    )
    assert(
        not NetworkGetEntityIsNetworked(data.entity),
        'Net Entity Passed to addLocalEntity, use addEntity instead'
    )


    local toReturn = {}

    if data.options then
        local optionsType = type(data.options)
        assert(optionsType == "table",
            string.format('unexpected type for options. table expected. got %s',
                optionsType))

        for _, option in ipairs(data.options) do
            local clone = lib.table.clone(data)
            local merge = lib.table.merge(clone, option, false)

            utils.loadInteractionDefaults(merge, GetInvokingResource())

            local newInteraction = LocalEntityInteraction:new(merge)
            if newInteraction.id then
                table.insert(store.Interactions, newInteraction)
                toReturn[#toReturn + 1] = newInteraction.id
            end
        end
    else
        local merge = lib.table.clone(data)

        utils.loadInteractionDefaults(merge, GetInvokingResource())

        local newInteraction = LocalEntityInteraction:new(merge)
        if newInteraction.id then
            table.insert(store.Interactions, newInteraction)
            toReturn[#toReturn + 1] = newInteraction.id
        end
    end

    return toReturn
end

--NETWORKED ENTITY INTERACTIONS

---add interaction for a networked entity
function interact.addEntity(data)
    local netIdType = type(data.netId)
    assert(
        netIdType == 'number',
        string.format('unexpected type for netId. expected number. got %s', netIdType)
    )

    assert(
        NetworkDoesEntityExistWithNetworkId(data.netId),
        string.format('Entity with netid: %s Did Not Exist For addEntity', data.netId)
    )

    local toReturn = {}

    if data.options then
        local optionsType = type(data.options)
        assert(optionsType == "table",
            string.format('unexpected type for options. table expected. got %s',
                optionsType))

        for _, option in ipairs(data.options) do
            local clone = lib.table.clone(data)
            local merge = lib.table.merge(clone, option, false)

            utils.loadInteractionDefaults(merge, GetInvokingResource())

            local newInteraction = NetEntityInteraction:new(merge)
            if newInteraction.id then
                table.insert(store.Interactions, newInteraction)
                toReturn[#toReturn + 1] = newInteraction.id
            end
        end
    else
        local merge = lib.table.clone(data)

        utils.loadInteractionDefaults(merge, GetInvokingResource())

        local newInteraction = NetEntityInteraction:new(merge)
        if newInteraction.id then
            table.insert(store.Interactions, newInteraction)
            toReturn[#toReturn + 1] = newInteraction.id
        end
    end

    return toReturn
end

-- GLOBAL INTERACTIONS

---add global interaction for vehicles
function interact.addGlobalVehicle(data)
    local optionsType = type(data.options)
    assert(optionsType == "table" and lib.table.type(data.options) == 'array',
        string.format('unexpected type for options. array expected. got %s',
            (optionsType == "table" and lib.table.type(data.options)) or optionsType))

    local toReturn = {}

    for _, option in ipairs(data.options) do
        local clone = lib.table.clone(data)
        local merge = lib.table.merge(clone, option, false)

        utils.loadInteractionDefaults(merge, GetInvokingResource())

        if store.globalIds[merge.id] then
            utils.updateGlobalInteraction('vehicle', merge)
            return
        end

        store.globalIds[merge.id] = true

        table.insert(store.globalVehicle, merge)

        toReturn[#toReturn + 1] = merge.id
    end

    return toReturn
end

---add global interaction for player
function interact.addGlobalPlayer(data)
    local optionsType = type(data.options)
    assert(optionsType == "table" and lib.table.type(data.options) == 'array',
        string.format('unexpected type for options. array expected. got %s',
            (optionsType == "table" and lib.table.type(data.options)) or optionsType))


    local toReturn = {}

    for _, option in ipairs(data.options) do
        local clone = lib.table.clone(data)
        local merge = lib.table.merge(clone, option, false)

        utils.loadInteractionDefaults(merge, GetInvokingResource())

        if store.globalIds[merge.id] then
            utils.updateGlobalInteraction('player', merge)
            return
        end

        store.globalIds[merge.id] = true

        table.insert(store.globalPlayer, merge)

        toReturn[#toReturn + 1] = merge.id
    end

    return toReturn
end

---add global interaction for non-player ped
function interact.addGlobalPed(data)
    local optionsType = type(data.options)
    assert(optionsType == "table" and lib.table.type(data.options) == 'array',
        string.format('unexpected type for options. array expected. got %s',
            (optionsType == "table" and lib.table.type(data.options)) or optionsType))

    local toReturn = {}

    for _, option in ipairs(data.options) do
        local clone = lib.table.clone(data)
        local merge = lib.table.merge(clone, option, false)

        utils.loadInteractionDefaults(merge, GetInvokingResource())

        if store.globalIds[merge.id] then
            utils.updateGlobalInteraction('ped', merge)
            return
        end

        store.globalIds[merge.id] = true

        table.insert(store.globalPed, merge)

        toReturn[#toReturn + 1] = merge.id
    end

    return toReturn
end

---add interaction for model(s)
function interact.addGlobalModel(data)
    local optionsType = type(data.options)
    assert(optionsType == "table" and lib.table.type(data.options) == 'array',
        string.format('unexpected type for options. array expected. got %s',
            (optionsType == "table" and lib.table.type(data.options)) or optionsType))

    local toReturn = {}

    for _, option in ipairs(data.options) do
        local clone = lib.table.clone(data)
        local merge = lib.table.merge(clone, option, false)

        utils.loadInteractionDefaults(merge, GetInvokingResource())

        if store.globalIds[merge.id] then
            interact.removeGlobalModel(merge.id)
            interact.addGlobalModel(merge)
            return
        end

        store.globalIds[merge.id] = true

        toReturn[#toReturn + 1] = merge.id

        local modelsType = type(merge.models)
        assert(modelsType == "string" or modelsType == "number" or modelsType == "table",
            'unexpected value for models. expected string or number or string[] or number[] {model: string | number, bone: string, offset: vec3}[]. got ' ..
            modelsType)

        if modelsType == "string" or modelsType == "number" then
            merge.models = { merge.models }
        end

        for i = 1, #merge.models do
            local interactionData = lib.table.clone(merge)
            local modelData = merge.models[i]
            if type(modelData) == 'table' then
                interactionData.offset = modelData.offset or interactionData.offset
                interactionData.bone = modelData.bone
                interactionData.model = type(modelData.model) == 'string' and joaat(modelData.model) or modelData.model
            else
                interactionData.model = type(modelData) == 'string' and joaat(modelData) or modelData
            end

            if not store.globalModels[interactionData.model] then
                store.globalModels[interactionData.model] = {}
            end

            table.insert(store.globalModels[interactionData.model], interactionData)

            toReturn[#toReturn + 1] = interactionData.id
        end
    end

    return toReturn
end

-- REMOVE INTERACTIONS

---@param property string
---@param value string | number
local function removeByProperty(property, value, similar, optionName)
    for i = #store.Interactions, 1, -1 do
        local interaction = store.Interactions[i]

        if type(value) == "array" then
            for _, id in ipairs(value) do
                if property == 'id' and similar then
                    if interaction[property] and tostring(interaction[property]):find(tostring(id)) then
                        interaction:destroy()
                        table.remove(store.Interactions, i)
                    end
                else
                    if interaction[property] and ((optionName and interaction[property] == optionName) or (interaction[property] == id)) then
                        interaction:destroy()
                        table.remove(store.Interactions, i)
                    end
                end
            end
        else
            if property == 'id' and similar then
                if interaction[property] and tostring(interaction[property]):find(tostring(value)) then
                    interaction:destroy()
                    table.remove(store.Interactions, i)
                end
            else
                if interaction[property] and ((optionName and interaction[property] == optionName) or (interaction[property] == value)) then
                    interaction:destroy()
                    table.remove(store.Interactions, i)
                end
            end
        end
    end
end

---remove non-networked entity interaction
function interact.removeLocalEntity(entity, optionName)
    removeByProperty('entity', entity, false, optionName)
end

---remove networked entity interaction
function interact.removeEntity(netId, optionName)
    removeByProperty('netId', netId, optionName)
end

---remove an interaction by id
function interact.removeById(id, similar)
    removeByProperty('id', id, similar)
end

---remove global model interactions with id
function interact.removeGlobalModel(id)
    for model, _ in pairs(store.globalModels) do
        for i = #store.globalModels[model], 1, -1 do
            local data = store.globalModels[model][i]
            if data.id == id then
                table.remove(store.globalModels[model], i)
                interact.removeById(id, true)
            end
        end
    end
    store.globalIds[id] = nil
end

---remove global player interactions with id
function interact.removeGlobalPlayer(id)
    for i = #store.globalPlayer, 1, -1 do
        local data = store.globalPlayer[i]
        if data.id == id then
            store.globalIds[id] = nil
            table.remove(store.globalPlayer, i)
            interact.removeById(id, true)
        end
    end
end

---remove global ped interactions with id
function interact.removeGlobalPed(id)
    for i = #store.globalPed, 1, -1 do
        local data = store.globalPed[i]
        if data.id == id then
            store.globalIds[id] = nil
            table.remove(store.globalPed, i)
            interact.removeById(id, true)
        end
    end
end

---remove global vehicle interactions with id
function interact.removeGlobalVehicle(id)
    for i = #store.globalVehicle, 1, -1 do
        local data = store.globalVehicle[i]
        if data.id == id then
            store.globalIds[id] = nil
            table.remove(store.globalVehicle, i)
            interact.removeById(id, true)
        end
    end
end

-- disable interactions
function interact.disable(disable)
    LocalPlayer.state.interactBusy = disable
end
