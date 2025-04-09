local utils = require 'client.modules.utils'
local store = require 'client.modules.store'

--- Throws a type error with a formatted message.
---@param variable string The name of the variable with the type issue.
---@param expected string The expected type.
---@param received string The actual type received.
local function typeError(variable, expected, received)
    error(("expected %s to have type '%s' (received %s)"):format(variable, expected, received))
end

--- Validates and normalizes an options table into an array.
---@param options InteractOption | InteractOption[] A single option table or an array of option tables.
---@return InteractOption[] options An array of options.
local function checkOptions(options)
    local optionsType = type(options)
    if optionsType ~= 'table' then
        typeError('options', 'table', optionsType)
    end

    local tableType = table.type(options)
    if tableType == 'hash' and options.label then
        options = { options }
    elseif tableType ~= 'array' then
        typeError('options', 'array', ('%s table'):format(tableType))
    end

    return options
end

--- Removes options from a target array based on names and resource.
---@param target InteractOption[] The array of options to modify.
---@param remove? string | string[] A single option name or array of names to remove. If nil, removes all options for the resource.
---@param resource string The resource owning the options.
local function removeOptions(target, remove, resource)
    if remove then
        if type(remove) ~= 'table' then remove = { remove } end
        local removeSet = {}
        for i = 1, #remove do
            removeSet[remove[i]] = true
        end
        for i = #target, 1, -1 do
            local option = target[i]
            if option.resource == resource and removeSet[option.name] then
                table.remove(target, i)
            end
        end
    else
        -- Remove all options for the resource
        for i = #target, 1, -1 do
            if target[i].resource == resource then
                table.remove(target, i)
            end
        end
    end
end

--- Adds options to a target array, handling bones and offsets if present.
---@param target InteractOption[] The array to add options to.
---@param options InteractOption | InteractOption[] A single option or array of options to add.
---@param resource string The resource registering the options.
---@param bonesTarget OptionsMap|nil The bone options map to update, if applicable.
---@param offsetsTarget OptionsMap|nil The offset options map to update, if applicable.
local function addOptions(target, options, resource, bonesTarget, offsetsTarget)
    options = checkOptions(options)
    local checkNames = {}

    resource = resource or 'sleepless_interact'

    for i = #options, 1, -1 do
        local option = options[i]
        option.resource = option.resource or resource

        if resource == 'sleepless_interact' then
            if option.canInteract then
                option.canInteract = msgpack.unpack(msgpack.pack(option.canInteract))
            end
            if option.onSelect then
                option.onSelect = msgpack.unpack(msgpack.pack(option.onSelect))
            end
            if option.onActive then
                option.onActive = msgpack.unpack(msgpack.pack(option.onActive))
            end
            if option.onInactive then
                option.onInactive = msgpack.unpack(msgpack.pack(option.onInactive))
            end
            if option.whileActive then
                option.whileActive = msgpack.unpack(msgpack.pack(option.whileActive))
            end
        end

        if option.offset or option.offsetAbsolute then
            local offsetKey = option.offset and 'offset' or 'offsetAbsolute'
            local offset = option[offsetKey]
            local offsetType = type(offset)

            if offsetType == 'table' and offset.x and offset.y and offset.z then
                offset = vec3(offset.x, offset.y, offset.z)
            end

            if offsetType ~= 'table' and offsetType ~= 'vector3' then
                typeError('offset', 'vector3', offsetType)
            end

            local offsetStr = utils.makeOffsetIdFromCoords(offset, offsetKey)

            if offsetsTarget and offsetStr then
                offsetsTarget[offsetStr] = offsetsTarget[offsetStr] or {}
                if option.name then
                    removeOptions(offsetsTarget[offsetStr], { option.name }, resource)
                end
                table.insert(offsetsTarget[offsetStr], table.remove(options, i))
            end
        elseif option.bones and bonesTarget then
            if type(option.bones) ~= "table" then
                option.bones = { option.bones --[[@as string]] }
            end

            local boneOptions = table.remove(options, i)

            for j = 1, #option.bones do
                local boneId = option.bones[j]
                bonesTarget[boneId] = bonesTarget[boneId] or {}
                if option.name then
                    removeOptions(bonesTarget[boneId], { option.name }, resource)
                end
                table.insert(bonesTarget[boneId], boneOptions)
            end
        elseif option.name then
            checkNames[#checkNames + 1] = option.name
        end
    end

    if checkNames[1] then
        removeOptions(target, checkNames, resource)
    end

    for i = 1, #options do
        table.insert(target, options[i])
    end
end

--- Removes options from a target and its associated bones and offsets.
---@param target InteractOption[] The array to remove options from.
---@param remove? string | string[] A single option name or array of names to remove. If nil, removes all options for the resource.
---@param resource string The resource owning the options.
---@param bonesTarget OptionsMap|nil The bone options map to update, if applicable.
---@param offsetsTarget OptionsMap|nil The offset options map to update, if applicable.
local function removeTarget(target, remove, resource, bonesTarget, offsetsTarget)
    if target then
        removeOptions(target, remove, resource)
    end

    if bonesTarget then
        for _, options in pairs(bonesTarget) do
            removeOptions(options, remove, resource)
        end
    end

    if offsetsTarget then
        for _, options in pairs(offsetsTarget) do
            removeOptions(options, remove, resource)
        end
    end
end

--- Disables or enables interaction and clears nearby/current options.
---@param state boolean True to disable interaction, false to enable.
function interact.disableInteract(state)
    if type(state) == "boolean" then
        LocalPlayer.state.hideInteract = state
    end
    store.nearby = {}
    store.current = {}
end

--- Adds options to a specific coordinate location.
---@param coords vector3 | vector3[] The world coordinates for the options.
---@param options InteractOption | InteractOption[] A single option or array of options.
---@return string | string[] ids The ID of the added coordinate options.
function interact.addCoords(coords, options)
    local coordsType = type(coords)
    if coordsType ~= 'table' and coordsType ~= 'vector3' and coordsType ~= 'vector4' then
        typeError('coords', 'vector3 or vector3[]', coordsType)
    end

    if coordsType == "table" and coords.x and coords.y and coords.z then
        coords = { vector3(coords.x, coords.y, coords.z) }
    end

    if coordsType ~= "table" then
        coords = { coords }
    end

    local resource = GetInvokingResource()
    options = checkOptions(options)
    local ids = {}

    for i = 1, #coords do
        local c = coords[i]
        local cType = type(c)

        if cType == 'vector4' then
            c = vec3(c.x, c.y, c.z)
            cType = type(c)
        end

        if cType ~= 'vector3' then
            typeError('coords', 'vector3', cType)
        end

        local id = utils.makeIdFromCoords(c)
        store.coords[id] = store.coords[id] or {}
        store.coordIds[id] = c
        addOptions(store.coords[id], table.clone(options), resource, nil, nil)
        ids[i] = id
    end

    return (#ids == 1 and ids[1]) or ids
end

--- Removes options from a coordinate location.
---@param id string The coordinate ID to modify.
---@param remove? string | string[] Specific option names to remove, or nil to remove all for the resource.
function interact.removeCoords(id, remove)
    if not store.coords[id] then
        warn(('attempted to remove a coord that does not exist (id: %s)'):format(id))
        return
    end

    local resource = GetInvokingResource()
    removeOptions(store.coords[id], remove, resource)

    if #store.coords[id] == 0 then
        store.coords[id] = nil
        store.coordIds[id] = nil
    end
end

--- Adds options globally for all peds.
---@param options InteractOption | InteractOption[] A single option or array of options.
function interact.addGlobalPed(options)
    addOptions(store.peds, options, GetInvokingResource(), store.bones.peds, store.offsets.peds)
end

--- Removes options globally from all peds.
---@param remove? string | string[] A single option name or array of names to remove, or nil to remove all for the resource.
function interact.removeGlobalPed(remove)
    if not remove then return end

    removeTarget(store.peds, remove, GetInvokingResource(), store.bones.peds, store.offsets.peds)

    if store.bones.peds then
        for boneId, boneOptions in pairs(store.bones.peds) do
            if #boneOptions == 0 then
                store.bones.peds[boneId] = nil
            end
        end
        if not next(store.bones.peds) then
            store.bones.peds = nil
        end
    end

    if store.offsets.peds then
        for offsetStr, offsetOptions in pairs(store.offsets.peds) do
            if #offsetOptions == 0 then
                store.offsets.peds[offsetStr] = nil
            end
        end
        if not next(store.offsets.peds) then
            store.offsets.peds = nil
        end
    end
end

--- Adds options globally for all vehicles.
---@param options InteractOption | InteractOption[] A single option or array of options.
function interact.addGlobalVehicle(options)
    addOptions(store.vehicles, options, GetInvokingResource(), store.bones.vehicles, store.offsets.vehicles)
end

--- Removes options globally from all vehicles.
---@param remove? string | string[] A single option name or array of names to remove, or nil to remove all for the resource.
function interact.removeGlobalVehicle(remove)
    if not remove then return end
    
    removeTarget(store.vehicles, remove, GetInvokingResource(), store.bones.vehicles, store.offsets.vehicles)

    if store.bones.vehicles then
        for boneId, boneOptions in pairs(store.bones.vehicles) do
            if #boneOptions == 0 then
                store.bones.vehicles[boneId] = nil
            end
        end
        if not next(store.bones.vehicles) then
            store.bones.vehicles = nil
        end
    end

    if store.offsets.vehicles then
        for offsetStr, offsetOptions in pairs(store.offsets.vehicles) do
            if #offsetOptions == 0 then
                store.offsets.vehicles[offsetStr] = nil
            end
        end
        if not next(store.offsets.vehicles) then
            store.offsets.vehicles = nil
        end
    end
end

--- Adds options globally for all objects.
---@param options InteractOption | InteractOption[] A single option or array of options.
function interact.addGlobalObject(options)
    addOptions(store.objects, options, GetInvokingResource(), store.bones.objects, store.offsets.objects)
end

--- Removes options globally from all objects.
---@param remove? string | string[] A single option name or array of names to remove, or nil to remove all for the resource.
function interact.removeGlobalObject(remove)
    if not remove then return end

    removeTarget(store.objects, remove, GetInvokingResource(), store.bones.objects, store.offsets.objects)

    if store.bones.objects then
        for boneId, boneOptions in pairs(store.bones.objects) do
            if #boneOptions == 0 then
                store.bones.objects[boneId] = nil
            end
        end
        if not next(store.bones.objects) then
            store.bones.objects = nil
        end
    end

    if store.offsets.objects then
        for offsetStr, offsetOptions in pairs(store.offsets.objects) do
            if #offsetOptions == 0 then
                store.offsets.objects[offsetStr] = nil
            end
        end
        if not next(store.offsets.objects) then
            store.offsets.objects = nil
        end
    end
end

--- Adds options globally for all players.
---@param options InteractOption | InteractOption[] A single option or array of options.
function interact.addGlobalPlayer(options)
    addOptions(store.players, options, GetInvokingResource(), store.bones.players, store.offsets.players)
end

--- Removes options globally from all players.
---@param remove? string | string[] A single option name or array of names to remove, or nil to remove all for the resource.
function interact.removeGlobalPlayer(remove)
    if not remove then return end

    removeTarget(store.players, remove, GetInvokingResource(), store.bones.players, store.offsets.players)

    if store.bones.players then
        for boneId, boneOptions in pairs(store.bones.players) do
            if #boneOptions == 0 then
                store.bones.players[boneId] = nil
            end
        end
        if not next(store.bones.players) then
            store.bones.players = nil
        end
    end

    if store.offsets.players then
        for offsetStr, offsetOptions in pairs(store.offsets.players) do
            if #offsetOptions == 0 then
                store.offsets.players[offsetStr] = nil
            end
        end
        if not next(store.offsets.players) then
            store.offsets.players = nil
        end
    end
end

--- Adds options for specific models.
---@param models number | string | (number | string)[] A single model (hash or name) or array of models.
---@param options InteractOption | InteractOption[] A single option or array of options.
function interact.addModel(models, options)
    if type(models) ~= 'table' then models = { models } end
    local resource = GetInvokingResource()
    for i = 1, #models do
        local model = models[i]
        model = tonumber(model) or joaat(model)
        store.models[model] = store.models[model] or {}
        store.bones.models[model] = store.bones.models[model] or {}
        store.offsets.models[model] = store.offsets.models[model] or {}
        addOptions(store.models[model], table.clone(options), resource, store.bones.models[model], store.offsets.models[model])
    end
end

--- Removes options from specific models.
---@param models number | string | (number | string)[] A single model (hash or name) or array of models.
---@param remove? string | string[] A single option name or array of names to remove, or nil to remove all for the resource.
function interact.removeModel(models, remove)
    if type(models) ~= 'table' then models = { models } end
    local resource = GetInvokingResource()
    for i = 1, #models do
        local model = models[i]
        model = tonumber(model) or joaat(model)
        if store.models[model] then
            removeTarget(store.models[model], remove, resource, store.bones.models[model], store.offsets.models[model])

            if store.models[model] and #store.models[model] == 0 then
                store.models[model] = nil
            end

            if store.bones.models[model] then
                for boneId, boneOptions in pairs(store.bones.models[model]) do
                    if #boneOptions == 0 then
                        store.bones.models[model][boneId] = nil
                    end
                end
                if not next(store.bones.models[model]) then
                    store.bones.models[model] = nil
                end
            end

            if store.offsets.models[model] then
                for offsetStr, offsetOptions in pairs(store.offsets.models[model]) do
                    if #offsetOptions == 0 then
                        store.offsets.models[model][offsetStr] = nil
                    end
                end
                if not next(store.offsets.models[model]) then
                    store.offsets.models[model] = nil
                end
            end
        end
    end
end

--- Adds options for specific networked entities.
---@param netIds number | number[] A single netId or array of netIds.
---@param options InteractOption | InteractOption[] A single option or array of options.
function interact.addEntity(netIds, options)
    if type(netIds) ~= 'table' then netIds = { netIds } end
    local resource = GetInvokingResource()
    for i = 1, #netIds do
        local netId = netIds[i]
        if NetworkDoesNetworkIdExist(netId) then
            store.entities[netId] = store.entities[netId] or {}
            store.bones.entities[netId] = store.bones.entities[netId] or {}
            store.offsets.entities[netId] = store.offsets.entities[netId] or {}
            addOptions(store.entities[netId], table.clone(options), resource, store.bones.entities[netId], store.offsets.entities[netId])
        end
    end
end

--- Removes options from specific networked entities.
---@param netIds number | number[] A single netId or array of netIds.
---@param remove? string | string[] A single option name or array of names to remove, or nil to remove all for the resource.
function interact.removeEntity(netIds, remove)
    if type(netIds) ~= 'table' then netIds = { netIds } end
    local resource = GetInvokingResource()
    for i = 1, #netIds do
        local netId = netIds[i]
        removeTarget(store.entities[netId], remove, resource, store.bones.entities[netId], store.offsets.entities[netId])

        if store.entities[netId] and #store.entities[netId] == 0 then
            store.entities[netId] = nil
        end

        if store.bones.entities[netId] then
            for boneId, boneOptions in pairs(store.bones.entities[netId]) do
                if #boneOptions == 0 then
                    store.bones.entities[netId][boneId] = nil
                end
            end
            if not next(store.bones.entities[netId]) then
                store.bones.entities[netId] = nil
            end
        end

        if store.offsets.entities[netId] then
            for offsetStr, offsetOptions in pairs(store.offsets.entities[netId]) do
                if #offsetOptions == 0 then
                    store.offsets.entities[netId][offsetStr] = nil
                end
            end
            if not next(store.offsets.entities[netId]) then
                store.offsets.entities[netId] = nil
            end
        end
    end
end

--- Adds options for specific local entities.
---@param entityIds number | number[] A single entityId or array of entityIds.
---@param options InteractOption | InteractOption[] A single option or array of options.
function interact.addLocalEntity(entityIds, options)
    if type(entityIds) ~= 'table' then entityIds = { entityIds } end
    local resource = GetInvokingResource()
    for i = 1, #entityIds do
        local entityId = entityIds[i]
        if DoesEntityExist(entityId) then
            store.localEntities[entityId] = store.localEntities[entityId] or {}
            store.bones.localEntities[entityId] = store.bones.localEntities[entityId] or {}
            store.offsets.localEntities[entityId] = store.offsets.localEntities[entityId] or {}
            addOptions(store.localEntities[entityId], table.clone(options), resource, store.bones.localEntities[entityId], store.offsets.localEntities[entityId])
        else
            lib.print.warn(('No entity with id "%s" exists.'):format(entityId))
        end
    end
end

--- Removes options from specific local entities.
---@param entityIds number | number[] A single entityId or array of entityIds.
---@param remove? string | string[] A single option name or array of names to remove, or nil to remove all for the resource.
function interact.removeLocalEntity(entityIds, remove)
    if type(entityIds) ~= 'table' then entityIds = { entityIds } end
    local resource = GetInvokingResource()
    for i = 1, #entityIds do
        local entityId = entityIds[i]
        removeTarget(store.localEntities[entityId], remove, resource, store.bones.localEntities[entityId], store.offsets.localEntities[entityId])

        if store.localEntities[entityId] and #store.localEntities[entityId] == 0 then
            store.localEntities[entityId] = nil
        end

        if store.bones.localEntities[entityId] then
            for boneId, boneOptions in pairs(store.bones.localEntities[entityId]) do
                if #boneOptions == 0 then
                    store.bones.localEntities[entityId][boneId] = nil
                end
            end
            if not next(store.bones.localEntities[entityId]) then
                store.bones.localEntities[entityId] = nil
            end
        end

        if store.offsets.localEntities[entityId] then
            for offsetStr, offsetOptions in pairs(store.offsets.localEntities[entityId]) do
                if #offsetOptions == 0 then
                    store.offsets.localEntities[entityId][offsetStr] = nil
                end
            end
            if not next(store.offsets.localEntities[entityId]) then
                store.offsets.localEntities[entityId] = nil
            end
        end
    end
end

-- Thread to clean up local entities that no longer exist.
CreateThread(function()
    while true do
        Wait(60000)
        for entityId in pairs(store.localEntities) do
            if not DoesEntityExist(entityId) then
                store.localEntities[entityId] = nil
                store.bones.localEntities[entityId] = nil
                store.offsets.localEntities[entityId] = nil
            end
        end
    end
end)

--- Removes all options associated with a specific resource from a target array.
---@param target InteractOption[] The array to clean up.
---@param resource string The resource whose options should be removed.
local function removeResourceOptions(target, resource)
    if not target then return end
    for i = #target, 1, -1 do
        if target[i].resource == resource then
            table.remove(target, i)
        end
    end
end

AddEventHandler('onClientResourceStop', function(resource)
    removeResourceOptions(store.peds, resource)
    removeResourceOptions(store.vehicles, resource)
    removeResourceOptions(store.objects, resource)
    removeResourceOptions(store.players, resource)

    for boneId, options in pairs(store.bones.peds or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.peds[boneId] = nil
        end
    end

    for boneId, options in pairs(store.bones.vehicles or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.vehicles[boneId] = nil
        end
    end

    for boneId, options in pairs(store.bones.objects or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.objects[boneId] = nil
        end
    end

    for boneId, options in pairs(store.bones.players or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.players[boneId] = nil
        end
    end

    for offsetStr, options in pairs(store.offsets.peds or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.peds[offsetStr] = nil
        end
    end

    for offsetStr, options in pairs(store.offsets.vehicles or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.vehicles[offsetStr] = nil
        end
    end

    for offsetStr, options in pairs(store.offsets.objects or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.objects[offsetStr] = nil
        end
    end

    for offsetStr, options in pairs(store.offsets.players or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.players[offsetStr] = nil
        end
    end

    for model, options in pairs(store.models) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.models[model] = nil
        end

        if store.bones.models[model] then
            for boneId, boneOptions in pairs(store.bones.models[model]) do
                removeResourceOptions(boneOptions, resource)
                if #boneOptions == 0 then
                    store.bones.models[model][boneId] = nil
                end
            end
            if not next(store.bones.models[model]) then
                store.bones.models[model] = nil
            end
        end

        if store.offsets.models[model] then
            for offsetStr, offsetOptions in pairs(store.offsets.models[model]) do
                removeResourceOptions(offsetOptions, resource)
                if #offsetOptions == 0 then
                    store.offsets.models[model][offsetStr] = nil
                end
            end
            if not next(store.offsets.models[model]) then
                store.offsets.models[model] = nil
            end
        end
    end

    for netId, options in pairs(store.entities) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.entities[netId] = nil
        end

        if store.bones.entities[netId] then
            for boneId, boneOptions in pairs(store.bones.entities[netId]) do
                removeResourceOptions(boneOptions, resource)
                if #boneOptions == 0 then
                    store.bones.entities[netId][boneId] = nil
                end
            end
            if not next(store.bones.entities[netId]) then
                store.bones.entities[netId] = nil
            end
        end

        if store.offsets.entities[netId] then
            for offsetStr, offsetOptions in pairs(store.offsets.entities[netId]) do
                removeResourceOptions(offsetOptions, resource)
                if #offsetOptions == 0 then
                    store.offsets.entities[netId][offsetStr] = nil
                end
            end
            if not next(store.offsets.entities[netId]) then
                store.offsets.entities[netId] = nil
            end
        end
    end

    for entityId, options in pairs(store.localEntities) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.localEntities[entityId] = nil
        end

        if store.bones.localEntities[entityId] then
            for boneId, boneOptions in pairs(store.bones.localEntities[entityId]) do
                removeResourceOptions(boneOptions, resource)
                if #boneOptions == 0 then
                    store.bones.localEntities[entityId][boneId] = nil
                end
            end
            if not next(store.bones.localEntities[entityId]) then
                store.bones.localEntities[entityId] = nil
            end
        end

        if store.offsets.localEntities[entityId] then
            for offsetStr, offsetOptions in pairs(store.offsets.localEntities[entityId]) do
                removeResourceOptions(offsetOptions, resource)
                if #offsetOptions == 0 then
                    store.offsets.localEntities[entityId][offsetStr] = nil
                end
            end
            if not next(store.offsets.localEntities[entityId]) then
                store.offsets.localEntities[entityId] = nil
            end
        end
    end

    for id, options in pairs(store.coords) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.coords[id] = nil
            store.coordIds[id] = nil
        end
    end
end)
