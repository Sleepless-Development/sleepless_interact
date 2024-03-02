---@diagnostic disable: undefined-field
local CoordsInteraction = require 'classes.coordsInteraction'
local EntityInteraction = require 'classes.entityInteraction'
local LocalEntityInteraction = require 'classes.localEntityInteraction'
local utils = require 'imports.utils'
local globals = require 'imports.globals'

--STATIC COORDS INTERACTION

---static coords interaction
---@param data CoordsData
function interact.addCoords(data)
    local id, coords, options in data
    if not id or not coords or not options then
        lib.print.error('addCoords: missing parameters')
        return
    end

    local interactionData = utils.loadInteractionData(data)
    table.insert(globals.Interactions, CoordsInteraction:new(interactionData))

    return id
end

--LOCAL NON_NETWORKED ENTITY INTERACTIONS

---add interaction for local non-networked entity
---@param data LocalEntityData
function interact.addLocalEntity(data)
    local id, entity, options in data

    if not id or not entity or not options then
        lib.print.error('addLocalEntity: missing parameters')
        return
    end

    if NetworkGetEntityIsNetworked(entity) then
        lib.print.error('addLocalEntity: entity is networked, use interact.addEntity instead')
        return
    end

    local interactionData = utils.loadInteractionData(data)
    table.insert(globals.Interactions, LocalEntityInteraction:new(interactionData))

    return id
end

--NETWORKED ENTITY INTERACTIONS

---add interaction for a networked entity
---@param data EntityData
function interact.addEntity(data)
    local id, netId, options in data

    if not id or not netId or not options then
        lib.print.error('addEntity: missing parameters')
        return
    end

    if DoesEntityExist(netId) then
        lib.print.error('addEntity: should send a network id, not an entity handle')
        return
    end

    if not NetworkDoesNetworkIdExist(netId) then
        lib.print.error('addEntity: Network Id did not exist:', netId)
        return
    end

    local interactionData = utils.loadInteractionData(data)

    table.insert(globals.Interactions, EntityInteraction:new(interactionData))
    return id
end


-- GLOBAL INTERACTIONS

---@param model number
---@param data ModelData
local function insertModelData(model, data)

    if type(model) == 'string' then
        model = joaat(model)
    end

    if not globals.Models[model] then globals.Models[model] = {} end

    globals.Models[model][#globals.Models[model]+1] = data
end

---add interaction for model(s)
---@param data ModelData
function interact.addGlobalModel(data)
    local interactionData = utils.loadInteractionData(data)
    interactionData.models = nil
    for i = 1,#data.models do
        local model, offset, bone in data.models[i]
        interactionData.offset = offset
        interactionData.bone = bone
        insertModelData(model, interactionData)
    end
end

---add global interaction for player
---@param data PedInteractionData
function interact.addGlobalPlayer(data)
    local interactionData = utils.loadInteractionData(data)
    globals.playerInteractions[#globals.playerInteractions+1] = interactionData
end

---add global interaction for non-player ped
---@param data PedInteractionData
function interact.addGlobalPed(data)
    local interactionData = utils.loadInteractionData(data)
    globals.pedInteractions[#globals.pedInteractions+1] = interactionData
end

---add global interaction for networked vehicle
---@param data VehicleInteractionData
function interact.addGlobalVehicle(data)
    local interactionData = utils.loadInteractionData(data)
    globals.vehicleInteractions[#globals.vehicleInteractions+1] = interactionData
end

-- REMOVE INTERACTIONS

---@param property string
---@param value string | number
local function removeByProperty(property, value)
    for i = 1, #globals.Interactions do
        local interaction = globals.Interactions[i]
        if interaction[property] and interaction[property] == value then
            interaction:destroy()
        end
    end
end

---remove non-networked entity interaction
---@param entity number entity handle
function interact.removeLocalEntity(entity)
    removeByProperty('entity', entity)
end

---remove networked entity interaction
---@param netId number Network Id
function interact.removeEntity(netId)
    removeByProperty('netId', netId)
end

---remove an interaction by id
---@param id number | string unique id returned by add function
function interact.removeId(id)
    removeByProperty('id', id)
end


---@param model number
local function handleRemoveModel(model)
    if type(model) == "string" then
        model = joaat(model)
    end
    globals.Models[model] = nil
    removeByProperty('model', model)
end

---remove global model
---@param model number | number[]
function interact.removeModel(model)

    if type(model) == 'table' then
        local models = model
        for i = 1, #models do
            local _model = models[i]
            handleRemoveModel(_model)
        end
        return
    end

    handleRemoveModel(model)
end
