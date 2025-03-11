--- compat for https://github.com/darktrovx/interact

-- Utility function to generate UUIDs (for compatibility with the second script)
local function generateUUID()
    return ('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'):gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return ('%x'):format(v)
    end)
end

-- Export handler to register functions as exports
local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_interact_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

-- Convert options from the second script to sleepless_interact's Option structure
local function convertOptions(options, resource, id)
    local converted = {}
    for _, option in ipairs(options) do
        local newOption = {
            label = option.label or "Unnamed Option",
            icon = option.icon,
            iconColor = option.iconColor,
            distance = option.distance,
            canInteract = option.canInteract,
            name = option.name or id,
            resource = resource,
            offset = option.offset,
            bones = option.bone, -- Map 'bone' to 'bones' in sleepless_interact
            onSelect = option.onSelect,
            cooldown = option.cooldown,
            export = option.export,
            event = option.event,
            serverEvent = option.serverEvent,
            command = option.command
        }
        -- Handle groups (jobs) if present
        if option.groups or option.job then
            newOption.groups = option.groups or option.job
        end
        converted[#converted + 1] = newOption
    end
    return converted
end

-- AddInteraction (coords-based)
exportHandler('AddInteraction', function(data)
    local coords = data.coords
    local options = convertOptions(data.options, GetInvokingResource())
    local id = interact.addCoords(coords, options)
    return id -- Returns the coordinate-based ID from sleepless_interact
end)

-- AddLocalEntityInteraction
exportHandler('AddLocalEntityInteraction', function(data)
    local entity = data.entity
    local options = convertOptions(data.options, GetInvokingResource())
    interact.addLocalEntity({ entity }, options)
    -- Generate a UUID since addLocalEntity doesn't return an ID
    return generateUUID()
end)

-- AddEntityInteraction (networked entity)
exportHandler('AddEntityInteraction', function(data)
    local netId = data.netId
    local options = convertOptions(data.options, GetInvokingResource())
    interact.addEntity({ netId }, options)
    -- Generate a UUID since addEntity doesn't return an ID
    return generateUUID()
end)

-- AddGlobalVehicleInteraction
exportHandler('AddGlobalVehicleInteraction', function(data)
    local options = convertOptions(data.options, GetInvokingResource())
    interact.addGlobalVehicle(options)
    -- Generate a UUID since addGlobalVehicle doesn't return an ID
    return generateUUID()
end)

-- AddGlobalPlayerInteraction
exportHandler('addGlobalPlayerInteraction', function(data)
    local options = convertOptions(data.options, GetInvokingResource())
    interact.addGlobalPlayer(options)
    -- Generate a UUID since addGlobalPlayer doesn't return an ID
    return generateUUID()
end)

-- AddModelInteraction
exportHandler('AddModelInteraction', function(data)
    local model = data.model
    local options = convertOptions(data.options, GetInvokingResource())
    interact.addModel(model, options)
    -- Generate a UUID since addModel doesn't return an ID
    return generateUUID()
end)

-- RemoveInteraction (by ID)
exportHandler('RemoveInteraction', function(id)
    interact.removeCoords(id, nil, true) -- Remove coords-based interaction by ID
end)

-- RemoveLocalEntityInteraction
exportHandler('RemoveLocalEntityInteraction', function(entity, id)
    interact.removeLocalEntity({ entity }, id)
end)

-- RemoveEntityInteraction
exportHandler('RemoveEntityInteraction', function(netId, id)
    interact.removeEntity({ netId }, id)
end)

-- RemoveModelInteraction
exportHandler('RemoveModelInteraction', function(model, id)
    interact.removeModel(model, id)
end)

-- RemoveGlobalVehicleInteraction
exportHandler('RemoveGlobalVehicleInteraction', function(id)
    interact.removeGlobalVehicle(id)
end)

-- RemoveGlobalPlayerInteraction
exportHandler('RemoveGlobalPlayerInteraction', function(id)
    interact.removeGlobalPlayer(id)
end)