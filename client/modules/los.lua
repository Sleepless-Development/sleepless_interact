local config = require 'client.modules.config'

local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetEntityType = GetEntityType
local GetEntityModel = GetEntityModel
local GetEntityForwardVector = GetEntityForwardVector

local los = {}

local DEFAULT_LOS_FLAGS = 17
local LOS_HIT_SLOP = 0.08
local LOS_SCREEN_DOT = 0.15
local LOS_CACHE_MS = 250
local LOS_CACHE_MOVE_SQ = 0.04
local ENTITY_OBJECT = 3

local facingByEntity = {}

local ATM_MODELS = {
    [`prop_atm_01`] = true,
    [`prop_atm_02`] = true,
    [`prop_atm_03`] = true,
    [`prop_fleeca_atm`] = true,
}

---@param model number
---@return boolean
function los.isAtmModel(model)
    return ATM_MODELS[model] == true
end

local function shellPad()
    local pad = config.losShellDepth
    if pad == nil then return 2.0 end
    if pad < 0.0 then return 0.0 end
    return pad
end

---@param from vector3
---@param to vector3
---@param flags number
---@param ignore number
---@return boolean hit
---@return vector3|nil endCoords
---@return number entityHit
---@return number hitDist
local function probe(from, to, flags, ignore)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(
        from.x, from.y, from.z,
        to.x, to.y, to.z,
        flags, ignore, 7
    )
    local retval, hit, endCoords, _, entityHit = GetShapeTestResult(handle)
    if retval == 0 or not (hit == 1 or hit == true) then
        return false, nil, 0, 0.0
    end

    return true, endCoords, entityHit or 0, #(endCoords - from)
end

---@param value? vector3
---@return string
local function vecText(value)
    if not value then return '-' end
    return ('%.2f %.2f %.2f'):format(value.x, value.y, value.z)
end

---@param item NearbyItem
---@param info table
local function record(item, info)
    if not config.debug then
        item.debugLos = nil
        return
    end

    info.entity = item.entity
    info.atm = item.atm == true
    if item.entity and DoesEntityExist(item.entity) then
        info.model = GetEntityModel(item.entity)
    end

    item.debugLos = info
end

---@param nearby NearbyItem[]
function los.dump(nearby)
    print('--- sleepless_interact los ---')
    local count = 0

    for i = 1, #nearby do
        local dbg = nearby[i].debugLos
        if dbg then
            count = count + 1
            print(('[los %s] clear=%s atm=%s model=%s reason=%s gap=%s hitEntity=%s hitSelf=%s'):format(
                i,
                tostring(dbg.clear),
                tostring(dbg.atm),
                dbg.model and tostring(dbg.model) or '-',
                dbg.reason or '-',
                dbg.gap and ('%.2f'):format(dbg.gap) or '-',
                dbg.hitEntity and tostring(dbg.hitEntity) or '-',
                tostring(dbg.hitEntity ~= nil and dbg.hitEntity == dbg.entity)
            ))
            print(('  origin %s'):format(vecText(dbg.origin)))
            print(('  target %s'):format(vecText(dbg.target)))
            print(('  hit    %s'):format(vecText(dbg.hit)))
        end
    end

    if count == 0 then
        print('[los] nothing recorded. Look at a target with /interact_debug on.')
    end
end

---@param entity number
---@return number x
---@return number y
local function flatFacing(entity)
    local now = GetGameTimer()
    local row = facingByEntity[entity]
    if row and now - row.at < 1000 then
        return row.x, row.y
    end

    local forward = GetEntityForwardVector(entity)
    facingByEntity[entity] = { at = now, x = forward.x, y = forward.y }
    return forward.x, forward.y
end

---@param entity number
---@param origin vector3
---@param coords vector3
---@return boolean
local function onScreenSide(entity, origin, coords)
    local fx, fy = flatFacing(entity)
    local dx = origin.x - coords.x
    local dy = origin.y - coords.y
    local scale = math.sqrt(dx * dx + dy * dy) * math.sqrt(fx * fx + fy * fy)
    if scale < 0.0001 then return true end
    return dot(vec3(dx, dy, 0.0), vec3(fx, fy, 0.0)) <= LOS_SCREEN_DOT * scale
end

---@param item NearbyItem
---@param origin vector3
---@param coords vector3
---@return boolean|nil
local function readCache(item, origin, coords)
    if config.debug or not item.losAt then return end
    if GetGameTimer() - item.losAt > LOS_CACHE_MS then return end

    local dx = origin.x - item.losX
    local dy = origin.y - item.losY
    local dz = origin.z - item.losZ
    if dx * dx + dy * dy + dz * dz > LOS_CACHE_MOVE_SQ then return end

    dx = coords.x - item.losCX
    dy = coords.y - item.losCY
    dz = coords.z - item.losCZ
    if dx * dx + dy * dy + dz * dz > LOS_CACHE_MOVE_SQ then return end

    return item.losClear
end

---@param item NearbyItem
---@param origin vector3
---@param coords vector3
---@param clear boolean
---@return boolean
local function remember(item, origin, coords, clear)
    if config.debug then return clear end

    item.losAt = GetGameTimer()
    item.losX = origin.x
    item.losY = origin.y
    item.losZ = origin.z
    item.losCX = coords.x
    item.losCY = coords.y
    item.losCZ = coords.z
    item.losClear = clear
    if item.debugLos then
        item.debugLos = nil
    end

    return clear
end

---@param entity number
---@param origin vector3
---@param coords vector3
---@param flags number
---@param ped number
---@return boolean clear
---@return vector3 target
---@return vector3|nil hitCoords
---@return string|nil reason
---@return number|nil gap
local function hasAtmLos(entity, origin, coords, flags, ped)
    if not onScreenSide(entity, origin, coords) then
        return false, coords, nil, 'wall', nil
    end

    if HasEntityClearLosToEntity(ped, entity, flags) then
        return true, coords, nil, nil, nil
    end

    local dist = #(coords - origin)
    if dist < 0.05 then
        return true, coords, nil, nil, nil
    end

    local hit, endCoords, entityHit, hitDist = probe(origin, coords, flags, ped)
    if not hit or entityHit == entity or hitDist >= dist - LOS_HIT_SLOP then
        return true, coords, nil, nil, nil
    end

    local gap = dist - hitDist
    if gap <= shellPad() then
        return true, coords, nil, nil, nil
    end

    return false, coords, endCoords, 'shell', gap
end

---@param item NearbyItem
---@param coords vector3
---@param origin? vector3
---@return boolean
function los.hasClear(item, coords, origin)
    if config.requireLos == false then
        item.debugLos = nil
        return true
    end

    if not coords then
        item.debugLos = nil
        return false
    end

    local ped = cache.ped
    if not origin then
        local pedCoords = GetEntityCoords(ped)
        origin = vec3(pedCoords.x, pedCoords.y, pedCoords.z + 0.6)
    end

    local flags = config.losFlags or DEFAULT_LOS_FLAGS
    local cached = readCache(item, origin, coords)
    if cached ~= nil then
        if not item.entity or DoesEntityExist(item.entity) then
            return cached
        end

        return false
    end

    if item.entity then
        if not DoesEntityExist(item.entity) then
            if config.debug then
                record(item, { origin = origin, target = coords, clear = false, reason = 'missing' })
            end
            return remember(item, origin, coords, false)
        end

        local atm = item.atm
        if atm == nil then
            atm = GetEntityType(item.entity) == ENTITY_OBJECT and ATM_MODELS[GetEntityModel(item.entity)] == true
        end

        if atm then
            local clear, target, hitCoords, reason, gap = hasAtmLos(item.entity, origin, coords, flags, ped)
            if config.debug then
                record(item, {
                    origin = origin,
                    target = target,
                    hit = not clear and hitCoords or nil,
                    clear = clear,
                    reason = reason,
                    gap = gap,
                })
            end
            return remember(item, origin, coords, clear)
        end

        local clear = HasEntityClearLosToEntity(ped, item.entity, flags)
        local hitCoords, gap, hitEntity
        local dist = #(coords - origin)
        if not clear and dist >= 0.05 then
            local hit, endCoords, entityHit, hitDist = probe(origin, coords, flags, ped)
            if not hit or entityHit == item.entity or hitDist >= dist - LOS_HIT_SLOP then
                clear = true
            elseif hit then
                hitCoords = endCoords
                hitEntity = entityHit
                gap = dist - hitDist
            end
        end

        if config.debug then
            record(item, {
                origin = origin,
                target = coords,
                hit = not clear and hitCoords or nil,
                clear = clear,
                reason = 'native',
                gap = gap,
                hitEntity = hitEntity,
            })
        end
        return remember(item, origin, coords, clear)
    end

    local dist = #(coords - origin)
    local hit, endCoords, entityHit, hitDist = probe(origin, coords, flags, ped)
    local clear = not hit or dist < 0.05 or hitDist >= dist - LOS_HIT_SLOP
    if config.debug then
        record(item, {
            origin = origin,
            target = coords,
            hit = not clear and endCoords or nil,
            clear = clear,
            reason = 'point',
            gap = hit and (dist - hitDist) or nil,
            hitEntity = hit and entityHit or nil,
        })
    end
    return remember(item, origin, coords, clear)
end

return los
