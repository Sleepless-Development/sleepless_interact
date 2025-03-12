local dui = require 'client.modules.dui'
local store = require 'client.modules.store'
local config = require 'client.modules.config'
local utils = require 'client.modules.utils'

require 'client.compat.qtarget'
require 'client.compat.ox_target'
require 'client.compat.interact'

---@type boolean
local drawLoopRunning = false

local GetEntityCoords = GetEntityCoords
local DrawSprite = DrawSprite
local SetDrawOrigin = SetDrawOrigin
local getNearbyObjects = lib.getNearbyObjects
local getNearbyPlayers = lib.getNearbyPlayers
local getNearbyVehicles = lib.getNearbyVehicles
local getNearbyPeds = lib.getNearbyPeds
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetModelDimensions = GetModelDimensions
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local GetEntityModel = GetEntityModel

local r, g, b, a = table.unpack(config.themeColor)

local pressed = false
lib.addKeybind({
    name = 'interact_action',
    description = 'Interact',
    defaultKey = 'E',
    onPressed = function(self)
        if GetGameTimer() > store.cooldownEndTime then
            if not next(store.current) then return end
            pressed = true
            dui.sendMessage("interact")
        end
    end,
    onReleased = function(self)
        if not pressed then return end
        pressed = false
        dui.sendMessage("release")
    end,
})


local hidePerKeybind = config.showKeyBindBehavior == "hold"
if config.useShowKeyBind then
    lib.addKeybind({
        name = 'sleepless_interact:toggle',
        description = 'show interactions',
        defaultKey = config.defaultShowKeyBind,
        onPressed = function(self)
            if cache.vehicle then return end
            if config.showKeyBindBehavior == "toggle" then
                hidePerKeybind = not hidePerKeybind

                if hidePerKeybind then
                    table.wipe(store.nearby)
                    lib.notify({
                        title = 'Interact',
                        description = 'Disabled',
                        type = 'warning'
                    })
                else
                    lib.notify({
                        title = 'Interact',
                        description = 'Enabled',
                        type = 'success'
                    })
                end
            else
                hidePerKeybind = false
            end

        end,
        onReleased = function(self)
            if config.showKeyBindBehavior == "toggle" then return end
            hidePerKeybind = true
        end
    })
end

local modelCache, netIdCache = {}, {}

local function cachedEntityInfo(entity)
    if modelCache[entity] then
        return modelCache[entity], netIdCache[entity]
    end

    local model = GetEntityModel(entity)
    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or nil
    modelCache[entity] = model
    netIdCache[entity] = netId
    return model, netId
end

---@param options Option[]
---@param entity number
---@param distance number
---@param coords vector3
---@return nil | Option[], number | nil
local function filterValidOptions(options, entity, distance, coords)
    if not options then return nil end

    local totalOptions = 0
    local hidden = 0
    for _, _options in pairs(options) do
        totalOptions += #_options
        for i = 1, #_options do
            local option = _options[i]
            option.hide = false

            if not option.hide then
                option.hide = distance > (option.distance or 2.0)
            end

            if not option.hide and option.canInteract then
                option.hide = not option.canInteract(entity, distance, coords, option.name)
            end

            if not option.hide and option.groups then
                option.hide = not utils.hasPlayerGotGroup(option.groups)
            end

            if not option.hide and option.items then
                option.hide = not utils.hasPlayerGotItems(option.items, option.anyItem)
            end

            if option.hide then
                hidden += 1
            end
        end
    end

    if hidden >= totalOptions then
        return nil
    end

    return options, totalOptions - hidden
end

---@param entity number
---@param globalType string
---@return Option[] | nil
local function getOptionsForEntity(entity, globalType)
    if not entity then return nil end

    if IsPedAPlayer(entity) then
        return {
            global = store.players,
        }
    end

    local model, netId = cachedEntityInfo(entity)

    local options = {
        global = #store[globalType] > 0 and store[globalType] or nil,
        model = store.models[model],
        entity = netId and store.entities[netId] or nil,
        localEntity = store.localEntities[entity],
    }

    return next(options) and options or nil
end

---@param entity number
---@param globalType string
---@return table<string, Option[]> | nil
local function getBoneOptionsForEntity(entity, globalType)
    if not entity then return nil end

    local model, netId = cachedEntityInfo(entity)

    local boneOptions = {}

    if store.bones[globalType] then
        for boneId, options in pairs(store.bones[globalType]) do
            boneOptions[boneId] = boneOptions[boneId] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(boneOptions[boneId], opt)
            end
        end
    end

    if store.bones.models and store.bones.models[model] then
        for boneId, options in pairs(store.bones.models[model]) do
            boneOptions[boneId] = boneOptions[boneId] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(boneOptions[boneId], opt)
            end
        end
    end

    if netId and store.bones.entities and store.bones.entities[netId] then
        for boneId, options in pairs(store.bones.entities[netId]) do
            boneOptions[boneId] = boneOptions[boneId] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(boneOptions[boneId], opt)
            end
        end
    end

    if not netId and store.bones.localEntities and store.bones.localEntities[entity] then
        for boneId, options in pairs(store.bones.localEntities[entity]) do
            boneOptions[boneId] = boneOptions[boneId] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(boneOptions[boneId], opt)
            end
        end
    end

    return next(boneOptions) and boneOptions or nil
end

---@param entity number
---@param globalType string
---@return table<string, Option[]> | nil
local function getOffsetOptionsForEntity(entity, globalType)
    if not entity then return nil end

    local model, netId = cachedEntityInfo(entity)

    local offsetOptions = {}

    if store.offsets[globalType] then
        for offsetStr, options in pairs(store.offsets[globalType]) do
            offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(offsetOptions[offsetStr], opt)
            end
        end
    end

    if store.offsets.models and store.offsets.models[model] then
        for offsetStr, options in pairs(store.offsets.models[model]) do
            offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(offsetOptions[offsetStr], opt)
            end
        end
    end

    if netId and store.offsets.entities and store.offsets.entities[netId] then
        for offsetStr, options in pairs(store.offsets.entities[netId]) do
            offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(offsetOptions[offsetStr], opt)
            end
        end
    end

    if not netId and store.offsets.localEntities and store.offsets.localEntities[entity] then
        for offsetStr, options in pairs(store.offsets.localEntities[entity]) do
            offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
            for i = 1, #options do
                local opt = options[i]
                table.insert(offsetOptions[offsetStr], opt)
            end
        end
    end

    return next(offsetOptions) and offsetOptions or nil
end

---@param coords vector3
---@return NearbyItem[]
local function checkNearbyEntities(coords)
    local valid = {}
    local num = 0

    local function processEntities(entities, globalType)
        for i = 1, #entities do
            local ent = entities[i]
            local entity = ent.object or ent.vehicle or ent.ped
            local model = cachedEntityInfo(entity)
            local entCoords = GetEntityCoords(entity)
            local options = getOptionsForEntity(entity, globalType)
            local boneOptions = getBoneOptionsForEntity(entity, globalType)
            local offsetOptions = getOffsetOptionsForEntity(entity, globalType)


            if options then
                num = num + 1
                valid[num] = {
                    entity = entity,
                    coords = entCoords,
                    currentDistance = #(coords - entCoords),
                    currentScreenDistance = utils.getScreenDistanceSquared(entCoords),
                    options = options
                }
            end

            if boneOptions then
                for boneId, _options in pairs(boneOptions) do
                    local boneIndex = GetEntityBoneIndexByName(entity, boneId)
                    if boneIndex ~= -1 then
                        local boneCoords = GetEntityBonePosition_2(entity, boneIndex)
                        num = num + 1
                        valid[num] = {
                            entity = entity,
                            bone = boneId,
                            coords = boneCoords,
                            currentDistance = #(coords - boneCoords),
                            currentScreenDistance = utils.getScreenDistanceSquared(boneCoords),
                            options = { options = _options }
                        }
                    end
                end
            end

            if offsetOptions then
                for offsetStr, _options in pairs(offsetOptions) do
                    local x, y, z, offsetType = utils.getCoordsAndTypeFromOffsetId(offsetStr)
                    if x and y and z and offsetType then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        local offset = vec3(tonumber(x), tonumber(y), tonumber(z))
                        local worldPos

                        if offsetType == "offset" then
                            local min, max = GetModelDimensions(model)
                            offset = (max - min) * offset + min
                        end

                        worldPos = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)

                        num = num + 1
                        valid[num] = {
                            entity = entity,
                            offset = offsetStr,
                            coords = worldPos,
                            currentDistance = #(coords - worldPos),
                            currentScreenDistance = utils.getScreenDistanceSquared(worldPos),
                            options = { offset = _options }
                        }
                    end
                end
            end
        end
    end

    processEntities(getNearbyObjects(coords, 15.0), 'objects')
    processEntities(getNearbyVehicles(coords, 4.0), 'vehicles')
    processEntities(getNearbyPlayers(coords, 4.0, false), 'players')
    processEntities(getNearbyPeds(coords, 4.0), 'peds')

    return valid
end

---@param coords vector3
---@param update NearbyItem[]
---@return NearbyItem[]
local function checkNearbyCoords(coords, update)
    for id, _coords in pairs(store.coordIds) do
        local dist = #(coords - _coords)
        if dist < config.maxInteractDistance then
            update[#update + 1] = {
                coords = _coords,
                currentDistance = dist,
                currentScreenDistance = utils.getScreenDistanceSquared(_coords),
                coordId = id,
                options = { coords = store.coords[id] }
            }
        end
    end
    return update
end

local aspectRatio = GetAspectRatio(true)
local function drawLoop()
    if drawLoopRunning then return end
    drawLoopRunning = true

    lib.requestStreamedTextureDict('shared')
    local lastClosestItem, lastValidCount = nil, 0
    local nearbyData = {}
    local playerCoords

    CreateThread(function()
        while drawLoopRunning do
            Wait(100)
            playerCoords = GetEntityCoords(cache.ped)
            nearbyData = {}
            for i = 1, #store.nearby do
                local item = store.nearby[i]
                local coords = utils.getDrawCoordsForInteract(item)
                if coords then
                    local distance = #(playerCoords - coords)
                    local validOpts, validCount = filterValidOptions(item.options, item.entity, distance, coords)
                    nearbyData[i] = {
                        item = item,
                        coords = coords,
                        distance = distance,
                        validOpts = validOpts,
                        validCount = validCount
                    }
                end
            end
        end
    end)

    -- Main drawing loop
    while #store.nearby > 0 do
        Wait(0)
        local foundValid = false
        
        for i = 1, #store.nearby do
            local data = nearbyData[i]
            if data and data.coords then
                local item = data.item
                local coords = data.coords

                SetDrawOrigin(coords.x, coords.y, coords.z)

                if not foundValid and data.validOpts and data.validCount > 0 then
                    foundValid = true
                    DrawSprite(dui.instance.dictName, dui.instance.txtName, 0.0, 0.0, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                    local newClosestId = item.bone or item.offset or item.entity or item.coordId
                    if lastClosestItem ~= newClosestId or lastValidCount ~= data.validCount then
                        local resetIndex = lastClosestItem ~= newClosestId
                        lastClosestItem = newClosestId
                        lastValidCount = data.validCount
                        store.current = {
                            options = data.validOpts,
                            entity = item.entity,
                            distance = data.distance,
                            coords = coords,
                            index = 1,
                        }
                        dui.sendMessage('setOptions', { options = data.validOpts, resetIndex = resetIndex })
                    end
                else
                    local distance = #(playerCoords - coords)
                    if distance < config.maxInteractDistance then
                        local distanceRatio = math.min(0.5 + (0.25 * (distance / 10.0)), 1.0)
                        local scale = 0.025 * distanceRatio
                        DrawSprite('shared', 'emptydot_32', 0.0, 0.0, scale, scale * aspectRatio, 0.0, r, g, b, a)
                    end
                end

                ClearDrawOrigin()
            end
        end

        if not foundValid and next(store.current) then
            store.current = {}
            lastClosestItem = nil
        end
    end

    drawLoopRunning = false -- Stop the slow thread when the draw loop ends
end

local function BuilderLoop()
    while true do
        if LocalPlayer.state.hideInteract or hidePerKeybind then
            table.wipe(store.nearby)
        else
            local coords = GetEntityCoords(cache.ped)
            local update = checkNearbyEntities(coords)
            update = checkNearbyCoords(coords, update)

            store.nearby = update

            table.sort(store.nearby, function(a, b)
                return a.currentScreenDistance < b.currentScreenDistance
            end)

            if #store.nearby > 0 and not drawLoopRunning then
                CreateThread(drawLoop)
            end
        end
        Wait(1000)
    end
end



RegisterNUICallback('select', function(data, cb)
    cb(1)
    local currentTime = GetGameTimer()
    if currentTime > store.cooldownEndTime then
        local option = store.current.options[data[1]][data[2]]
        if option then
            -- Trigger the action
            if option.onSelect then
                option.onSelect(utils.getResponse(option))
            elseif option.export then
                exports[option.resource][option.export](nil, utils.getResponse(option))
            elseif option.event then
                TriggerEvent(option.event, utils.getResponse(option))
            elseif option.serverEvent then
                TriggerServerEvent(option.serverEvent, utils.getResponse(option, true))
            elseif option.command then
                ExecuteCommand(option.command)
            end
            local cooldown = option.cooldown or 1500
            store.cooldownEndTime = currentTime + cooldown

            if cooldown > 0 then
                dui.sendMessage('setCooldown', true)
                Wait(cooldown)
                dui.sendMessage('setCooldown', false)
            end
        end
    end
end)

CreateThread(BuilderLoop)
