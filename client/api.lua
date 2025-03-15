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

    local removeSet = {}
    for i = 1, #remove do
        removeSet[remove[i]] = true
    end

    for i = #target, 1, -1 do
        local option = target[i]
        if option.resource == resource and removeSet[option.name] then
            table.remove(target, i)
            if showWarning then
                lib.print.warn(("Replacing existing target option '%s'."):format(option.name))
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

    if bonesTarget and not next(bonesTarget) then
        bonesTarget = nil
    end

    if offsetsTarget and not next(offsetsTarget) then
        offsetsTarget = nil
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
---@param options Option | Option[] A single option or array of options.
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
---@param options Option[] A single option or array of options.
function interact.addGlobalVehicle(options)
    addOptions(store.vehicles, options, GetInvokingResource(), store.bones.vehicles, store.offsets.vehicles)
end

--- Removes options globally from all vehicles.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeGlobalVehicle(options)
    removeTarget(store.vehicles, options, GetInvokingResource(), store.bones.vehicles, store.offsets.vehicles)

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
---@param options Option | Option[] A single option or array of options.
function interact.addGlobalObject(options)
    addOptions(store.objects, options, GetInvokingResource(), store.bones.objects, store.offsets.objects)
end

--- Removes options globally from all objects.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeGlobalObject(options)
    removeTarget(store.objects, options, GetInvokingResource(), store.bones.objects, store.offsets.objects)

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
---@param options Option | Option[] A single option or array of options.
function interact.addGlobalPlayer(options)
    addOptions(store.players, options, GetInvokingResource(), store.bones.players, store.offsets.players)
end

--- Removes options globally from all players.
---@param options string | string[] A single option name or array of names to remove.
function interact.removeGlobalPlayer(options)
    removeTarget(store.players, options, GetInvokingResource(), store.bones.players, store.offsets.players)

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

        removeTarget(store.entities[netId], options, resource, store.bones.entities[netId], store.offsets.entities[netId])

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
            lib.print.warn(('No entity with id "%s" exists.'):format(entityId))
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

        removeTarget(store.localEntities[entityId], options, resource, store.bones.localEntities[entityId], store.offsets.localEntities[entityId])


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
---@param target Option[] The array to clean up.
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
    if store.peds and #store.peds == 0 then
        store.peds = nil
    end

    removeResourceOptions(store.vehicles, resource)
    if store.vehicles and #store.vehicles == 0 then
        store.vehicles = nil
    end

    removeResourceOptions(store.objects, resource)
    if store.objects and #store.objects == 0 then
        store.objects = nil
    end

    removeResourceOptions(store.players, resource)
    if store.players and #store.players == 0 then
        store.players = nil
    end

    for boneId, options in pairs(store.bones.peds or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.peds[boneId] = nil
        end
    end
    if store.bones.peds and not next(store.bones.peds) then
        store.bones.peds = nil
    end

    for boneId, options in pairs(store.bones.vehicles or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.vehicles[boneId] = nil
        end
    end
    if store.bones.vehicles and not next(store.bones.vehicles) then
        store.bones.vehicles = nil
    end

    for boneId, options in pairs(store.bones.objects or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.objects[boneId] = nil
        end
    end
    if store.bones.objects and not next(store.bones.objects) then
        store.bones.objects = nil
    end

    for boneId, options in pairs(store.bones.players or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.bones.players[boneId] = nil
        end
    end
    if store.bones.players and not next(store.bones.players) then
        store.bones.players = nil
    end

    for offsetStr, options in pairs(store.offsets.peds or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.peds[offsetStr] = nil
        end
    end
    if store.offsets.peds and not next(store.offsets.peds) then
        store.offsets.peds = nil
    end

    for offsetStr, options in pairs(store.offsets.vehicles or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.vehicles[offsetStr] = nil
        end
    end
    if store.offsets.vehicles and not next(store.offsets.vehicles) then
        store.offsets.vehicles = nil
    end

    for offsetStr, options in pairs(store.offsets.objects or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.objects[offsetStr] = nil
        end
    end
    if store.offsets.objects and not next(store.offsets.objects) then
        store.offsets.objects = nil
    end

    for offsetStr, options in pairs(store.offsets.players or {}) do
        removeResourceOptions(options, resource)
        if #options == 0 then
            store.offsets.players[offsetStr] = nil
        end
    end
    if store.offsets.players and not next(store.offsets.players) then
        store.offsets.players = nil
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
