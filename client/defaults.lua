--VEHICLE
local ox_inv = GetResourceState('ox_inventory'):find('start')

if ox_inv then
    interact.addGlobalVehicle({
        id = 'global:vehicle:Trunk',
        bone = 'boot',
        activeDistance = 1.5,
        renderDistance = 3.0,
        options = {
            {
                text = 'open trunk',
                icon = 'car',
                canInteract = function(entity, distance, coords, id)
                    local veh = entity
                    return GetVehicleDoorLockStatus(veh) ~= 2 and GetVehicleDoorAngleRatio(veh, 5) == 0
                end,
                action = function(interaction)
                    local veh = interaction.entity
                    SetVehicleDoorOpen(veh, 5, false, false)
                    ExecuteCommand('+inv')
                end
            },
            {
                text = 'close trunk',
                icon = 'car',
                canInteract = function(entity, distance, coords, id)
                    local veh = entity
                    return GetVehicleDoorAngleRatio(veh, 5) > 0
                end,
                action = function(interaction)
                    local veh = interaction.entity
                    SetVehicleDoorShut(veh, 5, false)
                end
            },
        }
    })
end
