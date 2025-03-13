local function generateUUID()
    return ('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'):gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return ('%x'):format(v)
    end)
end

local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_interact_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

local function convert(data, resource)
    local converted = {}
    local id = data.id or generateUUID()
    for i = 1, #data.options do
        local option = data.options[i]
        local newOption = {
            label = option.label or "Unnamed Option",
            icon = option.icon,
            iconColor = option.iconColor,
            distance = data.interactDst or 1.0,
            canInteract = option.canInteract,
            groups = data.groups,
            name = id,
            resource = resource,
            offset = data.offset,
            bones = (data.bone and { data.bone }) or nil,
            onSelect = option.action,
            cooldown = 1000,
            event = option.event,
            serverEvent = option.serverEvent,
        }
        converted[#converted + 1] = newOption
    end
    return converted, id
end

exportHandler('AddInteraction', function(data)
    local coords = data.coords
    local options = convert(data, GetInvokingResource())
    local id = interact.addCoords(coords, options)
    return id
end)

exportHandler('AddLocalEntityInteraction', function(data)
    local entity = data.entity
    local options, id = convert(data, GetInvokingResource())
    interact.addLocalEntity(entity, options)
    return id
end)

exportHandler('AddEntityInteraction', function(data)
    local netId = data.netId
    local options, id = convert(data, GetInvokingResource())
    interact.addEntity(netId, options)
    return id
end)

exportHandler('AddGlobalVehicleInteraction', function(data)
    local options, id = convert(data, GetInvokingResource())
    interact.addGlobalVehicle(options)
    return id
end)

exportHandler('addGlobalPlayerInteraction', function(data)
    local options, id = convert(data, GetInvokingResource())
    interact.addGlobalPlayer(options)
    return id
end)

exportHandler('AddModelInteraction', function(data)
    local model = data.model
    local options, id = convert(data, GetInvokingResource())
    interact.addModel(model, options)
    return id
end)

exportHandler('RemoveInteraction', function(id)
    interact.removeCoords(id, nil, true)
end)

exportHandler('RemoveLocalEntityInteraction', function(entity, id)
    interact.removeLocalEntity(entity, id)
end)

exportHandler('RemoveEntityInteraction', function(netId, id)
    interact.removeEntity(netId, id)
end)

exportHandler('RemoveModelInteraction', function(model, id)
    interact.removeModel(model, id)
end)

exportHandler('RemoveGlobalVehicleInteraction', function(id)
    interact.removeGlobalVehicle(id)
end)

exportHandler('RemoveGlobalPlayerInteraction', function(id)
    interact.removeGlobalPlayer(id)
end)
