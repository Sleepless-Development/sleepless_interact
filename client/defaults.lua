local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetVehicleDoorLockStatus = GetVehicleDoorLockStatus

local bones = {
    [0] = 'dside_f',
    [1] = 'pside_f',
    [2] = 'dside_r',
    [3] = 'pside_r'
}

---@param vehicle number
---@param door number
local function toggleDoor(vehicle, door)
    if GetVehicleDoorLockStatus(vehicle) ~= 2 then
        if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end
    end
end

---@param entity number
---@param coords vector3
---@param door number
---@param useOffset boolean?
---@return boolean?
local function canInteractWithDoor(entity, coords, door, useOffset)
    if not GetIsDoorValid(entity, door) or GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, door) or cache.vehicle then return end

    if useOffset then return true end

    local boneName = bones[door]

    if not boneName then return false end

    local boneId = GetEntityBoneIndexByName(entity, 'door_' .. boneName)

    if boneId ~= -1 then
        return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_' .. boneName))) < 0.72
    end
end

local function onSelectDoor(data, door)
    local entity = data.entity

    if NetworkGetEntityOwner(entity) == cache.playerId then
        return toggleDoor(entity, door)
    end

    TriggerServerEvent('ox_target:toggleEntityDoor', VehToNet(entity), door)
end

RegisterNetEvent('ox_target:toggleEntityDoor', function(netId, door)
    local entity = NetToVeh(netId)
    toggleDoor(entity, door)
end)
