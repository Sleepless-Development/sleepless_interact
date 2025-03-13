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
---@param options Option | Option[] A single option table or an array of option tables.
---@return Option[] options An array of options.
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
---@param target Option[] The array of options to modify.
---@param remove string | string[] A single option name or array of names to remove.
---@param resource string The resource owning the options.
---@param showWarning? boolean Whether to show a warning when replacing options.
local function removeOptions(target, remove, resource, showWarning)
    if type(remove) ~= 'table' then remove = { remove } end
    for i = #target, 1, -1 do
        local option = target[i]
        if option.resource == resource then
            for j = #remove, 1, -1 do
                if option.name == remove[j] then
                    table.remove(target, i)
                    if showWarning then
                        utils.warn(("Replacing existing target option '%s'."):format(option.name))
                    end
                end
            end
        end
    end
end

--- Adds options to a target array, handling bones and offsets if present.
---@param target Option[] The array to add options to.
---@param options Option | Option[] A single option or array of options to add.
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
        end

        if option.offset or option.offsetAbsolute then
            local offsetKey = option.offset and 'offset' or 'offsetAbsolute'
            local offset = option[offsetKey]
            local offsetStr = utils.makeOffsetIdFromCoords(offset, offsetKey)

            if offsetsTarget and offsetStr then
                offsetsTarget[offsetStr] = offsetsTarget[offsetStr] or {}
                if option.name then
                    removeOptions(offsetsTarget[offsetStr], { option.name }, resource, true)
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
                    removeOptions(bonesTarget[boneId], { option.name }, resource, true)
                end
                table.insert(bonesTarget[boneId], boneOptions)
            end
        elseif option.name then
            checkNames[#checkNames + 1] = option.name
        end
    end

    if checkNames[1] then
        removeOptions(target, checkNames, resource, true)
    end

    for i = 1, #options do
        local option = options[i]
        table.insert(target, option)
    end
end

--- Removes options from a target and its associated bones and offsets.
---@param target Option[] The array to remove options from.
---@param remove string | string[] A single option name or array of names to remove.
---@param resource string The resource owning the options.
---@param bonesTarget OptionsMap|nil The bone options map to update, if applicable.
---@param offsetsTarget OptionsMap|nil The offset options map to update, if applicable.
local function removeTarget(target, remove, resource, bonesTarget, offsetsTarget)
    if type(remove) ~= 'table' then remove = { remove } end
    removeOptions(target, remove, resource)
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
---@param options Option | Option[] A single option or array of options.
---@return string | string[] ids The ID of the added coordinate options.
function interact.addCoords(coords, options)
    local coordsType = type(coords)
    if coordsType ~= 'table' and coordsType ~= 'vector3' then
        typeError('coords', 'vector3 or vector3[]', coordsType)
    end

    if coordsType == "table" and coords.x ~= nil then
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

--- Removes options from a coordinate location or the entire coordinate.
---@param id string The coordinate ID to modify.
---@param options? string | string[] Specific option names to remove, or nil to remove all.
---@param suppressWarning? boolean Whether to suppress warnings if the ID doesn't exist.
function interact.removeCoords(id, options, suppressWarning)
    if not store.coords[id] then
        if not suppressWarning then
            warn(('attempted to remove a coord that does not exist (id: %s)'):format(id))
        end
        return
    end

    local resource = GetInvokingResource()

    if options then
        removeOptions(store.coords[id], options, resource)
        if #store.coords[id] == 0 then
            store.coords[id] = nil
            store.coordIds[id] = nil
        end
    else
        store.coords[id] = nil
        store.coordIds[id] = nil
    end
end

--- Adds options globally for all peds.
---@param options Option | Option[] A single option or array of options.
function interact.addGlobalPed(options)
    addOptions(store.peds, options, GetInvokingResource(), store.bones.peds, store.offsets.peds)
end

--- Removes options globally from all peds.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeGlobalPed(options)
    removeTarget(store.peds, options, GetInvokingResource(), store.bones.peds, store.offsets.peds)
end

--- Adds options globally for all vehicles.
---@param options Option[] A single option or array of options.
function interact.addGlobalVehicle(options)
    addOptions(store.vehicles, options, GetInvokingResource(), store.bones.vehicles, store.offsets.vehicles)
end

--- Removes options globally from all vehicles.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeGlobalVehicle(options)
    removeTarget(store.vehicles, options, GetInvokingResource(), store.bones.vehicles, store.offsets.vehicles)
end

--- Adds options globally for all objects.
---@param options Option | Option[] A single option or array of options.
function interact.addGlobalObject(options)
    addOptions(store.objects, options, GetInvokingResource(), store.bones.objects, store.offsets.objects)
end

--- Removes options globally from all objects.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeGlobalObject(options)
    removeTarget(store.objects, options, GetInvokingResource(), store.bones.objects, store.offsets.objects)
end

--- Adds options globally for all players.
---@param options Option | Option[] A single option or array of options.
function interact.addGlobalPlayer(options)
    addOptions(store.players, options, GetInvokingResource(), store.bones.players, store.offsets.players)
end

--- Removes options globally from all players.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeGlobalPlayer(options)
    removeTarget(store.players, options, GetInvokingResource(), store.bones.players, store.offsets.players)
end

--- Adds options for specific models.
---@param arr number | string | (number | string)[] A single model (hash or name) or array of models.
---@param options Option | Option[] A single option or array of options.
function interact.addModel(arr, options)
    if type(arr) ~= 'table' then arr = { arr } end
    local resource = GetInvokingResource()
    for i = 1, #arr do
        local model = arr[i]
        model = tonumber(model) or joaat(model)
        store.models[model] = store.models[model] or {}
        store.bones.models[model] = store.bones.models[model] or {}
        store.offsets.models[model] = store.offsets.models[model] or {}
        addOptions(store.models[model], table.clone(options), resource, store.bones.models[model], store.offsets.models[model])
    end
end

--- Removes options from specific models.
---@param arr number | string | (number | string)[] A single model (hash or name) or array of models.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeModel(arr, options)
    if type(arr) ~= 'table' then arr = { arr } end
    local resource = GetInvokingResource()
    for i = 1, #arr do
        local model = arr[i]
        model = tonumber(model) or joaat(model)
        if store.models[model] then
            removeTarget(store.models[model], options, resource, store.bones.models[model], store.offsets.models[model])
            if #store.models[model] == 0 and (not store.bones.models[model] or next(store.bones.models[model]) == nil) and (not store.offsets.models[model] or next(store.offsets.models[model]) == nil) then
                store.models[model] = nil
                store.bones.models[model] = nil
                store.offsets.models[model] = nil
            end
        end
    end
end

--- Adds options for specific networked entities.
---@param arr number | number[] A single netId or array of netIds.
---@param options Option | Option[] A single option or array of options.
function interact.addEntity(arr, options)
    if type(arr) ~= 'table' then arr = { arr } end
    local resource = GetInvokingResource()
    for i = 1, #arr do
        local netId = arr[i]
        if NetworkDoesNetworkIdExist(netId) then
            store.entities[netId] = store.entities[netId] or {}
            store.bones.entities[netId] = store.bones.entities[netId] or {}
            store.offsets.entities[netId] = store.offsets.entities[netId] or {}
            addOptions(store.entities[netId], table.clone(options), resource, store.bones.entities[netId], store.offsets.entities[netId])
        end
    end
end

--- Removes options from specific networked entities.
---@param arr number | number[] A single netId or array of netIds.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeEntity(arr, options)
    if type(arr) ~= 'table' then arr = { arr } end
    local resource = GetInvokingResource()
    for i = 1, #arr do
        local netId = arr[i]
        if store.entities[netId] then
            removeTarget(store.entities[netId], options, resource, store.bones.entities[netId],
                store.offsets.entities[netId])
            if #store.entities[netId] == 0 and (not store.bones.entities[netId] or next(store.bones.entities[netId]) == nil) and (not store.offsets.entities[netId] or next(store.offsets.entities[netId]) == nil) then
                store.entities[netId] = nil
                store.bones.entities[netId] = nil
                store.offsets.entities[netId] = nil
            end
        end
    end
end

--- Adds options for specific local entities.
---@param arr number | number[] A single entityId or array of entityIds.
---@param options Option | Option[] A single option or array of options.
function interact.addLocalEntity(arr, options)
    if type(arr) ~= 'table' then arr = { arr } end
    local resource = GetInvokingResource()
    for i = 1, #arr do
        local entityId = arr[i]
        if DoesEntityExist(entityId) then
            store.localEntities[entityId] = store.localEntities[entityId] or {}
            store.bones.localEntities[entityId] = store.bones.localEntities[entityId] or {}
            store.offsets.localEntities[entityId] = store.offsets.localEntities[entityId] or {}
            addOptions(store.localEntities[entityId], table.clone(options), resource, store.bones.localEntities[entityId], store.offsets.localEntities[entityId])
        else
            print(('No entity with id "%s" exists.'):format(entityId))
        end
    end
end

--- Removes options from specific local entities.
---@param arr number | number[] A single entityId or array of entityIds.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeLocalEntity(arr, options)
    if type(arr) ~= 'table' then arr = { arr } end
    local resource = GetInvokingResource()
    for i = 1, #arr do
        local entityId = arr[i]
        if store.localEntities[entityId] then
            removeTarget(store.localEntities[entityId], options, resource, store.bones.localEntities[entityId], store.offsets.localEntities[entityId])
            if #store.localEntities[entityId] == 0 and (not store.bones.localEntities[entityId] or next(store.bones.localEntities[entityId]) == nil) and (not store.offsets.localEntities[entityId] or next(store.offsets.localEntities[entityId]) == nil) then
                store.localEntities[entityId] = nil
                store.bones.localEntities[entityId] = nil
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
---@param target Option[] The array to clean up.
---@param resource string The resource whose options should be removed.
local function removeResourceOptions(target, resource)
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
    for _, options in pairs(store.bones.peds) do removeResourceOptions(options, resource) end
    for _, options in pairs(store.bones.vehicles) do removeResourceOptions(options, resource) end
    for _, options in pairs(store.bones.objects) do removeResourceOptions(options, resource) end
    for _, options in pairs(store.bones.players) do removeResourceOptions(options, resource) end
    for _, options in pairs(store.offsets.peds) do removeResourceOptions(options, resource) end
    for _, options in pairs(store.offsets.vehicles) do removeResourceOptions(options, resource) end
    for _, options in pairs(store.offsets.objects) do removeResourceOptions(options, resource) end
    for _, options in pairs(store.offsets.players) do removeResourceOptions(options, resource) end

    for model, options in pairs(store.models) do
        removeResourceOptions(options, resource)
        for _, boneOptions in pairs(store.bones.models[model] or {}) do
            removeResourceOptions(boneOptions, resource)
        end
        for _, offsetOptions in pairs(store.offsets.models[model] or {}) do
            removeResourceOptions(offsetOptions, resource)
        end
        if #options == 0 and (not store.bones.models[model] or next(store.bones.models[model]) == nil) and (not store.offsets.models[model] or next(store.offsets.models[model]) == nil) then
            store.models[model] = nil
            store.bones.models[model] = nil
            store.offsets.models[model] = nil
        end
    end

    for netId, options in pairs(store.entities) do
        removeResourceOptions(options, resource)
        for _, boneOptions in pairs(store.bones.entities[netId] or {}) do
            removeResourceOptions(boneOptions, resource)
        end
        for _, offsetOptions in pairs(store.offsets.entities[netId] or {}) do
            removeResourceOptions(offsetOptions, resource)
        end
        if #options == 0 and (not store.bones.entities[netId] or next(store.bones.entities[netId]) == nil) and (not store.offsets.entities[netId] or next(store.offsets.entities[netId]) == nil) then
            store.entities[netId] = nil
            store.bones.entities[netId] = nil
            store.offsets.entities[netId] = nil
        end
    end

    for entityId, options in pairs(store.localEntities) do
        removeResourceOptions(options, resource)
        for _, boneOptions in pairs(store.bones.localEntities[entityId] or {}) do
            removeResourceOptions(boneOptions, resource)
        end
        for _, offsetOptions in pairs(store.offsets.localEntities[entityId] or {}) do
            removeResourceOptions(offsetOptions, resource)
        end
        if #options == 0 and (not store.bones.localEntities[entityId] or next(store.bones.localEntities[entityId]) == nil) and (not store.offsets.localEntities[entityId] or next(store.offsets.localEntities[entityId]) == nil) then
            store.localEntities[entityId] = nil
            store.bones.localEntities[entityId] = nil
            store.offsets.localEntities[entityId] = nil
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