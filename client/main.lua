local dui = require 'client.modules.dui'
local store = require 'client.modules.store'
local config = require 'client.modules.config'
local utils = require 'client.modules.utils'

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

---@param options InteractOption[]
---@param entity number
---@param distance number
---@param coords vector3
---@return nil | table<string, InteractOption[]>, number | nil, boolean | nil
local function filterValidOptions(options, entity, distance, coords)
    if not options then return nil end
    local validOptions = {}
    local totalValid = 0
    local hasGlobal = options['global'] ~= nil
    local hasNonGlobal = false

    for category, _options in pairs(options) do
        if category ~= 'global' then
            hasNonGlobal = true
        end

        local validCategoryOptions = {}

        for i = 1, #_options do
            local option = _options[i]
            local hide = false

            if not hide and not option.allowInVehicle and cache.vehicle then
                hide = true
            end

            if not hide then hide = distance > (option.distance or 2.0) end

            if not hide and option.groups then hide = not utils.hasPlayerGotGroup(option.groups) end

            if not hide and option.items then hide = not utils.hasPlayerGotItems(option.items, option.anyItem) end

            if not hide and option.canInteract then
                local success, resp = pcall(option.canInteract, entity, distance, coords, option.name)
                hide = not success or not resp
            end

            if not hide then
                validCategoryOptions[#validCategoryOptions + 1] = option
                totalValid = totalValid + 1
            end
        end

        if #validCategoryOptions > 0 then
            validOptions[category] = validCategoryOptions
        end
    end

    local hideCompletely = hasGlobal and not hasNonGlobal and totalValid == 0

    if totalValid == 0 then
        return nil, nil, hideCompletely
    end

    return validOptions, totalValid, hideCompletely
end

---@param entity number
---@param globalType string
---@return InteractOption[] | nil
local function getOptionsForEntity(entity, globalType)
    if not entity then return nil end

    if IsPedAPlayer(entity) then
        return {
            global = store.players,
        }
    end

    local model, netId = cachedEntityInfo(entity)

    local options = {
        global = (store[globalType] ~= nil and #store[globalType] > 0 and store[globalType]) or nil,
        model = (store.models[model] ~= nil and #store.models[model] > 0 and store.models[model]) or nil,
        entity = (netId and store.entities[netId] ~= nil and #store.entities[netId] > 0 and store.entities[netId]) or nil,
        localEntity = (store.localEntities[entity] ~= nil and #store.localEntities[entity] > 0 and store.localEntities[entity]) or nil,
    }

    return next(options) and options or nil
end

---@param entity number
---@param globalType string
---@return table<string, InteractOption[]> | nil
local function getBoneOptionsForEntity(entity, globalType)
    if not entity then return nil end
    local model, netId = cachedEntityInfo(entity)
    local boneOptions = {}
    local hasOptions = false

    if store.bones[globalType] then
        for boneId, options in pairs(store.bones[globalType]) do
            if #options > 0 then
                boneOptions[boneId] = boneOptions[boneId] or {}
                boneOptions[boneId].global = options
                hasOptions = true
            end
        end
    end

    if store.bones.models and store.bones.models[model] then
        for boneId, options in pairs(store.bones.models[model]) do
            if #options > 0 then
                boneOptions[boneId] = boneOptions[boneId] or {}
                boneOptions[boneId].model = options
                hasOptions = true
            end
        end
    end

    if netId and store.bones.entities and store.bones.entities[netId] then
        for boneId, options in pairs(store.bones.entities[netId]) do
            if #options > 0 then
                boneOptions[boneId] = boneOptions[boneId] or {}
                boneOptions[boneId].entity = options
                hasOptions = true
            end
        end
    end

    if not netId and store.bones.localEntities and store.bones.localEntities[entity] then
        for boneId, options in pairs(store.bones.localEntities[entity]) do
            if #options > 0 then
                boneOptions[boneId] = boneOptions[boneId] or {}
                boneOptions[boneId].localEntity = options
                hasOptions = true
            end
        end
    end

    return hasOptions and boneOptions or nil
end

---@param entity number
---@param globalType string
---@return table<string, InteractOption[]> | nil
local function getOffsetOptionsForEntity(entity, globalType)
    if not entity then return nil end
    local model, netId = cachedEntityInfo(entity)
    local offsetOptions = {}
    local hasOptions = false

    if store.offsets[globalType] then
        for offsetStr, options in pairs(store.offsets[globalType]) do
            if #options > 0 then
                offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
                offsetOptions[offsetStr].global = options
                hasOptions = true
            end
        end
    end

    if store.offsets.models and store.offsets.models[model] then
        for offsetStr, options in pairs(store.offsets.models[model]) do
            if #options > 0 then
                offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
                offsetOptions[offsetStr].model = options
                hasOptions = true
            end
        end
    end

    if netId and store.offsets.entities and store.offsets.entities[netId] then
        for offsetStr, options in pairs(store.offsets.entities[netId]) do
            if #options > 0 then
                offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
                offsetOptions[offsetStr].entity = options
                hasOptions = true
            end
        end
    end

    if not netId and store.offsets.localEntities and store.offsets.localEntities[entity] then
        for offsetStr, options in pairs(store.offsets.localEntities[entity]) do
            if #options > 0 then
                offsetOptions[offsetStr] = offsetOptions[offsetStr] or {}
                offsetOptions[offsetStr].localEntity = options
                hasOptions = true
            end
        end
    end

    return hasOptions and offsetOptions or nil
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
                            options = _options
                        }
                    end
                end
            end

            if offsetOptions then
                for offsetStr, _options in pairs(offsetOptions) do
                    local x, y, z, offsetType = utils.getCoordsAndTypeFromOffsetId(offsetStr)
                    if x and y and z and offsetType then
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
                            options = _options
                        }
                    end
                end
            end
        end
    end

    processEntities(getNearbyObjects(coords, 4.0), 'objects')
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


local function shouldHideInteract()
    if IsNuiFocused() or LocalPlayer.state.hideInteract or (lib and lib.progressActive()) or hidePerKeybind or LocalPlayer.state.invOpen then
        return true
    end
    return false
end

local activeOptions = {}

local aspectRatio = GetAspectRatio(true)
local function drawLoop()
    if drawLoopRunning then return end
    drawLoopRunning = true

    lib.requestStreamedTextureDict('shared')
    local lastClosestItem, lastValidCount, lastValidOptions = nil, 0, nil
    local nearbyData = {}
    local playerCoords

    local entityStartCoords = {}
    local movingEntity = {}

    CreateThread(function()
        while drawLoopRunning do
            if shouldHideInteract() then
                table.wipe(store.nearby)
                break
            end

            playerCoords = GetEntityCoords(cache.ped)
            nearbyData = {}
            for i = 1, #store.nearby do
                local item = store.nearby[i]

                local coords = utils.getDrawCoordsForInteract(item)

                if coords then
                    if item.entity then
                        if not entityStartCoords[item.entity] then
                            entityStartCoords[item.entity] = coords
                        end

                        if coords ~= entityStartCoords then
                            movingEntity[item.entity] = true
                        end
                    end

                    local distance = #(playerCoords - coords)
                    local validOpts, validCount, hideCompletely = filterValidOptions(item.options, item.entity, distance, coords)
                    local id = item.bone or item.offset or item.entity or item.coordId
                    local shouldUpdate = false

                    if id == lastClosestItem then
                        if lastValidOptions then
                            shouldUpdate = not lib.table.matches(validOpts, lastValidOptions)
                        end
                    end

                    nearbyData[i] = {
                        item = item,
                        coords = coords,
                        shouldUpdate = shouldUpdate,
                        hideCompletely = hideCompletely,
                        distance = distance,
                        validOpts = validOpts,
                        validCount = validCount
                    }
                end
            end
            Wait(150)
        end
    end)

    while #store.nearby > 0 do
        Wait(0)
        local foundValid = false

        for i = 1, #store.nearby do
            local data = nearbyData[i]

            if data and data.coords and not data.hideCompletely then
                local item = data.item
                local coords = (item.entity and not movingEntity[item.entity] and data.coords) or utils.getDrawCoordsForInteract(item)

                SetDrawOrigin(coords.x, coords.y, coords.z)

                if not foundValid and data.validOpts and data.validCount > 0 then
                    foundValid = true

                    DrawSprite(dui.instance.dictName, dui.instance.txtName, 0.0, 0.0, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                    local newClosestId = item.bone or item.offset or item.entity or item.coordId
                    if data.shouldUpdate or lastClosestItem ~= newClosestId or lastValidCount ~= data.validCount then
                        local newOptions = {}

                        if data.validOpts then
                            for _, opts in pairs(data.validOpts) do
                                for j = 1, #opts do
                                    local opt = opts[j]
                                    newOptions[opt] = true
                                    if not activeOptions[opt] then
                                        activeOptions[opt] = true
                                        local resp = (opt.onActive or opt.whileActive) and utils.getResponse(opt)

                                        if opt.onActive then
                                            pcall(opt.onActive, resp)
                                        end

                                        if opt.whileActive then
                                            CreateThread(function()
                                                while activeOptions[opt] do
                                                    pcall(opt.whileActive, resp)
                                                    Wait(0)
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end

                        if lastValidOptions then
                            for _, opts in pairs(lastValidOptions) do
                                for j = 1, #opts do
                                    local opt = opts[j]

                                    if opt.onInactive and not newOptions[opt] and activeOptions[opt] then
                                        pcall(opt.onInactive, utils.getResponse(opt))
                                        activeOptions[opt] = nil
                                    end
                                end
                            end
                        end

                        local resetIndex = lastClosestItem ~= newClosestId
                        lastClosestItem = newClosestId
                        lastValidCount = data.validCount
                        lastValidOptions = data.validOpts

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
                    if distance < config.maxInteractDistance and item.currentScreenDistance < math.huge then
                        local distanceRatio = math.min(0.5 + (0.25 * (distance / 10.0)), 1.0)
                        local scale = 0.025 * distanceRatio
                        DrawSprite(config.IndicatorSprite.dict, config.IndicatorSprite.txt, 0.0, 0.0, scale, scale * aspectRatio, 0.0, r, g, b, a)
                    end
                end

                ClearDrawOrigin()
            end
        end

        if not foundValid and next(store.current) then
            for _, opts in pairs(store.current.options) do
                for j = 1, #opts do
                    local opt = opts[j]

                    if opt.onInactive and activeOptions[opt] then
                        pcall(opt.onInactive, utils.getResponse(opt))
                        activeOptions[opt] = nil
                    end
                end
            end
            store.current = {}
            lastClosestItem = nil
        end
    end

    drawLoopRunning = false
end

local function BuilderLoop()
    while true do
        if shouldHideInteract() then
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
    local currentTime = GetGameTimer()
    if store.current.options and currentTime > (store.cooldownEndTime or 0) then
        local option = store.current.options?[data[1]]?[data[2]]
        if option then
            if option.onSelect then
                option.onSelect(option.qtarget and store.current.entity or utils.getResponse(option))
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
    cb(1)
end)

CreateThread(BuilderLoop)
