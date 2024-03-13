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

    if type(coords) == 'table' then
        for i = 1, #coords do
            data = utils.loadInteractionData(data, GetInvokingResource())
            data.id = string.format("%s:%s", id, i)
            data.coords = coords[i]
            table.insert(globals.Interactions, CoordsInteraction:new(data))
        end
    else
        data = utils.loadInteractionData(data, GetInvokingResource())
        table.insert(globals.Interactions, CoordsInteraction:new(data))
    end

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
        lib.print.error('addLocalEntity: entity is networked, use addEntity instead')
        return
    end

    data = utils.loadInteractionData(data, GetInvokingResource())
    table.insert(globals.Interactions, LocalEntityInteraction:new(data))

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

    data = utils.loadInteractionData(data, GetInvokingResource())
    
    table.insert(globals.Interactions, EntityInteraction:new(data))
    return id
end


-- GLOBAL INTERACTIONS

local function doesInteractionExist(table, interaction)
    for i = 1, #table do
        if lib.table.matches(table[i], interaction) then
            return true
        end
    end
    return false
end


---@param model number
---@param data ModelData
local function insertModelData(model, data)

    if type(model) == 'string' then
        model = joaat(model)
    end

    if not globals.Models[model] then globals.Models[model] = {} end

    if doesInteractionExist(globals.Models[model], data) then return end

    globals.Models[model][#globals.Models[model]+1] = data
    
    if globals.cachedModelEntities[model] then
        table.wipe(globals.cachedModelEntities[model])
    end
end

---add interaction for model(s)
---@param data ModelData
function interact.addGlobalModel(data)
    local id, models, options in data

    if not id or not models or not options then
        lib.print.error('addGlobalModel: missing parameters')
        return
    end

    data = utils.loadInteractionData(data, GetInvokingResource())
    local models = data.models
    data.models = nil
    for i = 1,#models do
        local model, offset, bone in models[i]
        data.offset = offset
        data.bone = bone
        insertModelData(model, data)
    end

    return id
end

---add global interaction for player
---@param data PedInteractionData
function interact.addGlobalPlayer(data)
    local id, options in data

    if not id or not options then
        lib.print.error('addGlobalPlayer: missing parameters')
        return
    end

    data = utils.loadInteractionData(data, GetInvokingResource())
    if doesInteractionExist(globals.playerInteractions, data) then return end
    globals.playerInteractions[#globals.playerInteractions+1] = data
    table.wipe(globals.cachedPlayers)
    return id
end

---add global interaction for non-player ped
---@param data PedInteractionData
function interact.addGlobalPed(data)
    local id, options in data

    if not id or not options then
        lib.print.error('addGlobalPed: missing parameters')
        return
    end

    data = utils.loadInteractionData(data, GetInvokingResource())
    if doesInteractionExist(globals.pedInteractions, data) then return end
    globals.pedInteractions[#globals.pedInteractions+1] = data
    table.wipe(globals.cachedPeds)
    return id
end

---add global interaction for networked vehicle
---@param data VehicleInteractionData
function interact.addGlobalVehicle(data)
    local id, options in data

    if not id or not options then
        lib.print.error('addGlobalVehicle: missing parameters')
        return
    end

    data = utils.loadInteractionData(data, GetInvokingResource())
    if doesInteractionExist(globals.vehicleInteractions, data) then return end
    globals.vehicleInteractions[#globals.vehicleInteractions+1] = data
    table.wipe(globals.cachedVehicles)
    return id
end

-- REMOVE INTERACTIONS

---@param property string
---@param value string | number
local function removeByProperty(property, value, similar)
    for i = 1, #globals.Interactions do
        local interaction = globals.Interactions[i]
        if property == 'id' and similar then
            if interaction[property] and tostring(interaction[property]):find(tostring(value)) then
                interaction:destroy()
                globals.Interactions[i] = nil
            end
        else
            if interaction[property] and interaction[property] == value then
                interaction:destroy()
                globals.Interactions[i] = nil
            end
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
---@param similar? boolean
function interact.removeById(id, similar)
    removeByProperty('id', id, similar)
end

---@param model number
local function handleRemoveModel(model, id)
    if type(model) == "string" then
        model = joaat(model)
    end
    
    for i = 1, #globals.Models[model] do
        local data = globals.Models[model][i]
        if data.id == id then
            globals.Models[model][i] = nil
            if #globals.Models[model] == 0 then
                globals.Models[model] = nil
            end
            interact.removeById(id, true)
        end
    end

    if globals.cachedModelEntities[model] then
        table.wipe(globals.cachedModelEntities[model])
    end
end

---remove global model interactions with id
---@param model number | number[]
function interact.removeGlobalModel(model, id)

    if type(model) == 'table' then
        local models = model
        for i = 1, #models do
            local _model = models[i]
            handleRemoveModel(_model, id)
        end
        return
    end

    handleRemoveModel(model, id)
end

---remove global player interactions with id
---@param id number | string
function interact.removeGlobalPlayer(id)
    for i = 1, #globals.playerInteractions do
        local data = globals.playerInteractions[i]
        if data.id == id then
            globals.playerInteractions[i] = nil
            interact.removeById(id, true)
        end
    end
    table.wipe(globals.cachedPlayers)
end

---remove global ped interactions with id
---@param id number | string
function interact.removeGlobalPed(id)
    for i = 1, #globals.pednteractions do
        local data = globals.pednteractions[i]
        if data.id == id then
            globals.pednteractions[i] = nil
            interact.removeById(id, true)
        end
    end
    table.wipe(globals.cachedPeds)
end

---remove global vehicle interactions with id
---@param id number | string
function interact.removeGlobalVehicle(id)
    for i = 1, #globals.vehicleInteractions do
        local data = globals.vehicleInteractions[i]
        if data.id == id then
            globals.vehicleInteractions[i] = nil
            interact.removeById(id, true)
        end
    end
    table.wipe(globals.cachedVehicles)
end
