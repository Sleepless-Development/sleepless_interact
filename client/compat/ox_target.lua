local glm = require 'glm'

local zoneToCoord = {}

local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_ox_target_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

local function disableTargeting(state)
    interact.disableInteract(state)
end

local function addGlobalObject(options)
    interact.addGlobalObject(options)
end

local function removeGlobalObject(optionNames)
    interact.removeGlobalObject(optionNames)
end

local function addGlobalPed(options)
    interact.addGlobalPed(options)
end

local function removeGlobalPed(optionNames)
    interact.removeGlobalPed(optionNames)
end

local function addGlobalPlayer(options)
    interact.addGlobalPlayer(options)
end

local function removeGlobalPlayer(optionNames)
    interact.removeGlobalPlayer(optionNames)
end

local function addGlobalVehicle(options)
    interact.addGlobalVehicle(options)
end

local function removeGlobalVehicle(optionNames)
    interact.removeGlobalVehicle(optionNames)
end

local function addModel(models, options)
    interact.addModel(models, options)
end

local function removeModel(models, optionNames)
    interact.removeModel(models, optionNames)
end

local function addEntity(netIds, options)
    interact.addEntity(netIds, options)
end

local function removeEntity(netIds, optionNames)
    interact.removeEntity(netIds, optionNames)
end

local function addLocalEntity(entities, options)
    interact.addLocalEntity(entities, options)
end

local function removeLocalEntity(entities, optionNames)
    interact.removeLocalEntity(entities, optionNames)
end

local function addSphereZone(data)
    local coordsId = interact.addCoords(data.coords, data.options)

    if data.name then
        zoneToCoord[data.name] = coordsId
    end

    return coordsId
end

local function addBoxZone(data)
    local coordsId = interact.addCoords(data.coords, data.options)

    if data.name then
        zoneToCoord[data.name] = coordsId
    end

    return coordsId
end

local function addPolyZone(data)

    local points = {}
    for i = 1, #data.points do
        points[i] = glm.vec3(data.points[i].x, data.points[i].y, data.z or 0)
    end

    local polygon = glm.polygon.new(points)
    local coords = polygon:centroid()

    if not polygon:isPlanar() then
        local zCoords = {}
        for i = 1, #points do
            local z = points[i].z
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

        for i = 1, #points do
            points[i] = glm.vec3(data.points[i].x, data.points[i].y, zCoord)
        end

        polygon = glm.polygon.new(points)
        coords = polygon:centroid()
    end

    if not data.z then
        coords.z = GetHeightmapBottomZForPosition(coords.x, coords.y)
    end

    local finalCoords = vec3(coords.x, coords.y, coords.z)

    local coordsId = interact.addCoords(finalCoords, data.options)

    if data.name then
        zoneToCoord[data.name] = coordsId
    end

    return coordsId
end

local function removeZone(id)
    if zoneToCoord[id] then
        id = zoneToCoord[id]
    end

    interact.removeCoords(id)

    zoneToCoord[id] = nil
end

exportHandler('disableTargeting', disableTargeting)
exportHandler('addGlobalObject', addGlobalObject)
exportHandler('removeGlobalObject', removeGlobalObject)
exportHandler('addGlobalPed', addGlobalPed)
exportHandler('removeGlobalPed', removeGlobalPed)
exportHandler('addGlobalPlayer', addGlobalPlayer)
exportHandler('removeGlobalPlayer', removeGlobalPlayer)
exportHandler('addGlobalVehicle', addGlobalVehicle)
exportHandler('removeGlobalVehicle', removeGlobalVehicle)
exportHandler('addModel', addModel)
exportHandler('removeModel', removeModel)
exportHandler('addEntity', addEntity)
exportHandler('removeEntity', removeEntity)
exportHandler('addLocalEntity', addLocalEntity)
exportHandler('removeLocalEntity', removeLocalEntity)
exportHandler('addSphereZone', addSphereZone)
exportHandler('addBoxZone', addBoxZone)
exportHandler('addPolyZone', addPolyZone)
exportHandler('removeZone', removeZone)