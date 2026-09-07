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

---@param a vector3
---@param b vector3
---@return number
function utils.getDistanceSquared(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
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

local SPECIAL_KEYS = {
    b_100 = 'M1',
    b_101 = 'M2',
    b_102 = 'M3',
    b_130 = '-',
    b_131 = '+',
    b_140 = 'N4',
    b_141 = 'N5',
    b_142 = 'N6',
    b_143 = 'N7',
    b_144 = 'N8',
    b_145 = 'N9',
    b_146 = 'N2',
    b_147 = 'N3',
    b_138 = 'N0',
    b_139 = 'N1',
    b_170 = 'F1',
    b_171 = 'F2',
    b_172 = 'F3',
    b_173 = 'F4',
    b_174 = 'F5',
    b_175 = 'F6',
    b_176 = 'F7',
    b_177 = 'F8',
    b_178 = 'F9',
    b_179 = 'F10',
    b_180 = 'F11',
    b_181 = 'F12',
    b_194 = 'UP',
    b_195 = 'DN',
    b_196 = 'LT',
    b_197 = 'RT',
    b_198 = 'DEL',
    b_199 = 'ESC',
    b_200 = 'INS',
    b_210 = 'DEL',
    b_211 = 'INS',
    b_212 = 'END',
    b_1000 = 'SHFT',
    b_1002 = 'TAB',
    b_1003 = 'ENT',
    b_1004 = 'BKSP',
    b_1008 = 'HOME',
    b_1009 = 'PGUP',
    b_1010 = 'PGDN',
    b_1012 = 'CAPS',
    b_1013 = 'CTRL',
    b_1014 = 'CTRL',
    b_1015 = 'ALT',
    b_1055 = 'HOME',
    b_1056 = 'PGUP',
    b_2000 = 'SPC',
}

--- Resolve a RegisterKeyMapping command to a short HUD label.
--- Pass a command name (`'+interact_action'`) or a control hash.
---@param command string|number
---@return string
function utils.toHumanKeybind(command)
    local hash = type(command) == 'string' and joaat(command) or command
    local raw = GetControlInstructionalButton(2, hash | 0x80000000, true)

    if type(raw) ~= 'string' or raw == '' then
        return 'E'
    end

    if raw:sub(1, 2):lower() == 't_' then
        return raw:sub(3):upper()
    end

    return SPECIAL_KEYS[raw] or SPECIAL_KEYS[raw:lower()] or 'E'
end

---@param export string
---@return boolean
function utils.hasExport(export)
    local resource, exportName = string.strsplit('.', export)

    return pcall(function()
        return exports[resource][exportName]
    end)
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
