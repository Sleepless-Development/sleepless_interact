local store = require "imports.store"


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
        return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or
            #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_' .. boneName))) < 0.72
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


--VEHICLE

if store.ox_inv then
    interact.addGlobalVehicle({
        options = {
            {
                name = 'ox:Trunk', --- special handling for this id. pulls trunk data from ox_inventory vehicles
                bones = 'boot',
                text = 'Abrir Porta Malas',
                icon = 'car',
                activeDistance = 1.2,
                renderDistance = 3.0,
                canInteract = function(entity, distance, coords, id)
                    local veh = entity
                    return GetVehicleDoorLockStatus(veh) ~= 2 and GetVehicleDoorAngleRatio(veh, 5) == 0
                end,
                action = function(interaction)
                    local veh = interaction.entity
                    SetVehicleDoorOpen(veh, 5, false, false)
                    ExecuteCommand('+inv2')
                end
            },
            {
                name = 'ox:TrunkClose', --- special handling for this id. pulls trunk data from ox_inventory vehicles
                bones = 'boot',
                text = 'Fechar Porta Malas',
                icon = 'car',
                activeDistance = 1.2,
                renderDistance = 3.0,
                canInteract = function(entity, distance, coords, id)
                    local veh = entity
                    return GetVehicleDoorAngleRatio(veh, 5) > 0
                end,
                action = function(interaction)
                    local veh = interaction.entity
                    SetVehicleDoorShut(veh, 5, false)
                end
            },
            {
                name = 'ox_target:driverF',
                icon = 'car-side',
                label = "Abrir / Fechar porta 1",
                bones = { 'door_dside_f', 'seat_dside_f' },
                activeDistance = 1.2,
                renderDistance = 3.0,
                canInteract = function(entity, distance, coords, name)
                    return canInteractWithDoor(entity, coords, 0)
                end,
                onSelect = function(data)
                    onSelectDoor(data, 0)
                end
            },
            {
                name = 'ox_target:passengerF',
                icon = 'car-side',
                label = "Abrir / Fechar porta 2",
                bones = { 'door_pside_f', 'seat_pside_f' },
                activeDistance = 1.2,
                renderDistance = 3.0,
                canInteract = function(entity, distance, coords, name)
                    return canInteractWithDoor(entity, coords, 1)
                end,
                onSelect = function(data)
                    onSelectDoor(data, 1)
                end
            },
            {
                name = 'ox_target:driverR',
                icon = 'car-side',
                label = "Abrir / Fechar porta 3",
                bones = { 'door_dside_r', 'seat_dside_r' },
                activeDistance = 1.2,
                renderDistance = 3.0,
                canInteract = function(entity, distance, coords)
                    return canInteractWithDoor(entity, coords, 2)
                end,
                onSelect = function(data)
                    onSelectDoor(data, 2)
                end
            },
            {
                name = 'ox_target:passengerR',
                icon = 'car-side',
                label = "Abrir / Fechar porta 4",
                bones = { 'door_pside_r', 'seat_pside_r' },
                activeDistance = 1.2,
                renderDistance = 3.0,
                canInteract = function(entity, distance, coords)
                    return canInteractWithDoor(entity, coords, 3)
                end,
                onSelect = function(data)
                    onSelectDoor(data, 3)
                end
            },
            {
                name = 'ox_target:bonnet',
                icon = 'fa-solid fa-car',
                label = "Abrir / Fechar capô",
                offset = vec3(0, 1, 0.2),
                bones = "bonnet",
                activeDistance = 1.2,
                renderDistance = 3.0,
                canInteract = function(entity, distance, coords)
                    return canInteractWithDoor(entity, coords, 4, true)
                end,
                onSelect = function(data)
                    onSelectDoor(data, 4)
                end
            },
        }
    })
end
