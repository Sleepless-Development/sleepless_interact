---@diagnostic disable: inject-field
local store = require 'client.modules.store'
local utils = {}

---@param coords vector3 The coordinates to convert.
---@return string id A string ID in the format "x_y_z".
function utils.makeIdFromCoords(coords)
    local x = math.floor(coords.x * 1000)
    local y = math.floor(coords.y * 1000)
    local z = math.floor(coords.z * 1000)
    return string.format('%s_%s_%s', x, y, z)
end

---@param offset vector3 The offset vector.
---@param offsetType string The type of offset ("offset" or "offsetAbsolute").
---@return string id A string ID in the format "x_y_z_type".
function utils.makeOffsetIdFromCoords(offset, offsetType)
    local x = math.floor(offset.x * 1000)
    local y = math.floor(offset.y * 1000)
    local z = math.floor(offset.z * 1000)
    return string.format("%d_%d_%d_%s", x, y, z, offsetType)
end

---@param id string The offset ID to parse.
---@return number x The x-coordinate.
---@return number y The y-coordinate.
---@return number z The z-coordinate.
---@return string offsetType The type of offset.
function utils.getCoordsAndTypeFromOffsetId(id)
    local x, y, z, offsetType = id:match("(%-?%d+)_(%-?%d+)_(%-?%d+)_(%w+)")
    return x / 1000, y / 1000, z / 1000, offsetType
end

---@param coords table|vector3|vector4 The input coordinates.
---@return vector3 The converted or validated vector3.
function utils.convertToVector(coords)
    local _type = type(coords)

    if _type ~= 'vector3' then
        if _type == 'table' or _type == 'vector4' then
            return vec3(coords[1] or coords.x, coords[2] or coords.y, coords[3] or coords.z)
        end

        error(("expected type 'vector3' or 'table' (received %s)"):format(_type))
    end

    return coords
end

---@param option InteractOption The interaction option.
---@param server boolean|nil Whether to prepare the response for server-side use.
---@return InteractResponse response The response table with context from the current interaction.
function utils.getResponse(option, server)
    local response = table.clone(option) --[[@as InteractResponse]]
    response.entity = store.current.entity
    response.coordsId = store.current.coordsId
    response.coords = store.current.coords
    response.distance = store.current.distance

    if server then
        response.entity = response.entity ~= 0 and NetworkGetEntityIsNetworked(response.entity) and
            NetworkGetNetworkIdFromEntity(response.entity) or 0
    end

    response.icon = nil
    response.groups = nil
    response.items = nil
    response.canInteract = nil
    response.onSelect = nil
    response.export = nil
    response.event = nil
    response.serverEvent = nil
    response.command = nil

    return response
end

local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetModelDimensions = GetModelDimensions
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetEntityCoords = GetEntityCoords
local GetEntityModel = GetEntityModel

---@param item NearbyItem
function utils.getDrawCoordsForInteract(item)
    if not item then return vec3(0, 0, 0) end

    if item.coordId then
        return item.coords
    end

    if item.offset then
        local x, y, z, offsetType = utils.getCoordsAndTypeFromOffsetId(item.offset)
        local entityModel = GetEntityModel(item.entity)

        ---@diagnostic disable-next-line: param-type-mismatch
        local offset = vec3(tonumber(x), tonumber(y), tonumber(z))

        if offsetType == "offset" then
            local min, max = GetModelDimensions(entityModel)
            offset = (max - min) * offset + min
        end

        return GetOffsetFromEntityInWorldCoords(item.entity, offset.x, offset.y, offset.z)
    end

    if item.bone then
        local boneIndex = GetEntityBoneIndexByName(item.entity, item.bone)
        return boneIndex and GetEntityBonePosition_2(item.entity, boneIndex) or item.coords
    end

    if item.entity then
        return GetEntityCoords(item.entity)
    end

    return item.coords
end

local playerItems = {}

function utils.getItems()
    return playerItems
end

---@param filter string | string[] | table<string, number>
---@param hasAny boolean?
---@return boolean
function utils.hasPlayerGotItems(filter, hasAny)
    if not playerItems then return true end

    local _type = type(filter)

    if _type == 'string' then
        return (playerItems[filter] or 0) > 0
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            for name, amount in pairs(filter) do
                local hasItem = (playerItems[name] or 0) >= amount

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local hasItem = (playerItems[filter[i]] or 0) > 0

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        end
    end

    return not hasAny
end

---@param coords vector3
---@return number
function utils.getScreenDistanceSquared(coords)
    local success, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not success then return math.huge end

    local dx = screenX - 0.5
    local dy = screenY - 0.5
    return dx * dx + dy * dy
end

SetTimeout(0, function()
    if GetResourceState('ox_inventory'):find('start') then
        setmetatable(playerItems, {
            __index = function(self, index)
                self[index] = exports.ox_inventory:Search('count', index) or 0
                return self[index]
            end
        })

        AddEventHandler('ox_inventory:itemCount', function(name, count)
            playerItems[name] = count
        end)
    end


    if GetResourceState('ox_core'):find('start') then
        require 'client.framework.ox'
    elseif GetResourceState('es_extended'):find('start') then
        require 'client.framework.esx'
    elseif GetResourceState('qbx_core'):find('start') then
        require 'client.framework.qbx'
    elseif GetResourceState('ND_Core'):find('start') then
        require 'client.framework.nd'
    elseif GetResourceState('qb-core'):find('start') then
        require 'client.framework.qb'
    end
end)

return utils
