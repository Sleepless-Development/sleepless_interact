local glm = require 'glm'

local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_qb-target_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

local zoneToCoord = {}

---@param options table
---@return table
local function convert(options)
    local distance = options.distance
    options = options.options

    -- People may pass options as a hashmap (or mixed, even)
    for k, v in pairs(options) do
        if type(k) ~= 'number' then
            table.insert(options, v)
        end
    end

    for id, v in pairs(options) do
        if type(id) ~= 'number' then
            options[id] = nil
            goto continue
        end

        v.onSelect = v.action
        v.distance = v.distance or distance
        v.name = v.name or v.label
        v.items = v.item
        v.icon = v.icon
        v.groups = v.job

        local groupType = type(v.groups)
        if groupType == 'nil' then
            v.groups = {}
            groupType = 'table'
        end
        if groupType == 'string' then
            local val = v.gang
            if type(v.gang) == 'table' then
                if table.type(v.gang) ~= 'array' then
                    val = {}
                    for k in pairs(v.gang) do
                        val[#val + 1] = k
                    end
                end
            end

            if val then
                v.groups = {v.groups, type(val) == 'table' and table.unpack(val) or val}
            end

            val = v.citizenid
            if type(v.citizenid) == 'table' then
                if table.type(v.citizenid) ~= 'array' then
                    val = {}
                    for k in pairs(v.citizenid) do
                        val[#val+1] = k
                    end
                end
            end

            if val then
                v.groups = {v.groups, type(val) == 'table' and table.unpack(val) or val}
            end
        elseif groupType == 'table' then
            local val = {}
            if table.type(v.groups) ~= 'array' then
                for k in pairs(v.groups) do
                    val[#val + 1] = k
                end
                v.groups = val
                val = nil
            end

            val = v.gang
            if type(v.gang) == 'table' then
                if table.type(v.gang) ~= 'array' then
                    val = {}
                    for k in pairs(v.gang) do
                        val[#val + 1] = k
                    end
                end
            end

            if val then
                v.groups = {table.unpack(v.groups), type(val) == 'table' and table.unpack(val) or val}
            end

            val = v.citizenid
            if type(v.citizenid) == 'table' then
                if table.type(v.citizenid) ~= 'array' then
                    val = {}
                    for k in pairs(v.citizenid) do
                        val[#val+1] = k
                    end
                end
            end

            if val then
                v.groups = {table.unpack(v.groups), type(val) == 'table' and table.unpack(val) or val}
            end
        end

        if type(v.groups) == 'table' and table.type(v.groups) == 'empty' then
            v.groups = nil
        end

        if v.event and v.type and v.type ~= 'client' then
            if v.type == 'server' then
                v.serverEvent = v.event
            elseif v.type == 'command' then
                v.command = v.event
            end

            v.event = nil
            v.type = nil
        end

        v.action = nil
        v.job = nil
        v.gang = nil
        v.citizenid = nil
        v.item = nil
        v.qtarget = true

        ::continue::
    end

    return options
end

exportHandler('AddBoxZone', function(name, center, length, width, options, targetoptions)
    local coordsId = interact.addCoords(center, convert(targetoptions))

    if name then
        zoneToCoord[name] = coordsId
    end

    return coordsId
end)

exportHandler('AddPolyZone', function(name, points, options, targetoptions)
    local newPoints = {}
    for i = 1, #points do
        newPoints[i] = glm.vec3(points[i].x, points[i].y, 0)
    end

    local polygon = glm.polygon.new(newPoints)
    local coords = polygon:centroid()

    if not polygon:isPlanar() then
        local zCoords = {}
        for i = 1, #newPoints do
            local z = newPoints[i].z
            zCoords[z] = (zCoords[z] or 0) + 1
        end

        local coordsArray = {}
        for z, count in pairs(zCoords) do
            coordsArray[#coordsArray + 1] = { coord = z, count = count }
        end

        table.sort(coordsArray, function(a, b) return a.count > b.count end)

        local zCoord = coordsArray[1].coord
        local averageTo = 1
        for i = 2, #coordsArray do
            if coordsArray[i].count < coordsArray[1].count then
                averageTo = i - 1
                break
            end
        end

        if averageTo > 1 then
            zCoord = 0
            for i = 1, averageTo do
                zCoord = zCoord + coordsArray[i].coord
            end
            zCoord = zCoord / averageTo
        end

        -- Update points with averaged z coordinate
        for i = 1, #newPoints do
            newPoints[i] = glm.vec3(points[i].x, points[i].y, zCoord)
        end

        polygon = glm.polygon.new(newPoints)
        coords = polygon:centroid()
    end

    if not options.z then
        coords.z = GetHeightmapBottomZForPosition(coords.x, coords.y)
    end

    local finalCoords = vec3(coords.x, coords.y, coords.z)

    local coordsId = interact.addCoords(finalCoords, convert(targetoptions))

    if name then
        zoneToCoord[name] = coordsId
    end

    return coordsId
end)

exportHandler('AddCircleZone', function(name, center, radius, options, targetoptions)
    local coordsId = interact.addCoords(center, convert(targetoptions))

    if name then
        zoneToCoord[name] = coordsId
    end

    return coordsId
end)

exportHandler('RemoveZone', function(id)
    if zoneToCoord[id] then
        id = zoneToCoord[id]
    end

    interact.removeCoords(id)

    zoneToCoord[id] = nil
end)

exportHandler('AddTargetBone', function(bones, options)
    if type(bones) ~= 'table' then bones = { bones } end
    options = convert(options)

    for _, v in pairs(options) do
        v.bones = bones
    end

    interact.addGlobalVehicle(options)
end)

exportHandler('AddTargetEntity', function(entities, options)
    if type(entities) ~= 'table' then entities = { entities } end
    options = convert(options)

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            interact.addEntity(NetworkGetNetworkIdFromEntity(entity), options)
        else
            interact.addLocalEntity(entity, options)
        end
    end
end)

exportHandler('RemoveTargetEntity', function(entities, labels)
    if type(entities) ~= 'table' then entities = { entities } end

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            interact.removeEntity(NetworkGetNetworkIdFromEntity(entity), labels)
        else
            interact.removeLocalEntity(entity, labels)
        end
    end
end)

exportHandler('AddTargetModel', function(models, options)
    interact.addModel(models, convert(options))
end)

exportHandler('RemoveTargetModel', function(models, labels)
    interact.removeModel(models, labels)
end)

exportHandler('AddGlobalPed', function(options)
    interact.addGlobalPed(convert(options))
end)

exportHandler('RemoveGlobalPed', function(labels)
    interact.removeGlobalPed(labels)
end)

exportHandler('AddGlobalVehicle', function(options)
    interact.addGlobalVehicle(convert(options))
end)

exportHandler('RemoveGlobalVehicle', function(labels)
    interact.removeGlobalVehicle(labels)
end)

exportHandler('AddGlobalObject', function(options)
    interact.addGlobalObject(convert(options))
end)

exportHandler('RemoveGlobalObject', function(labels)
    interact.removeGlobalObject(labels)
end)

exportHandler('AddGlobalPlayer', function(options)
    interact.addGlobalPlayer(convert(options))
end)

exportHandler('RemoveGlobalPlayer', function(labels)
    interact.removeGlobalPlayer(labels)
end)

exportHandler('AddEntityZone', function()
    lib.print.warn('AddEntityZone is not supported by sleepless_interact - try using addEntity/addLocalEntity.')
end)

exportHandler('RemoveTargetBone', function()
    lib.print.warn('RemoveTargetBone is not supported by sleepless_interact.')
end)