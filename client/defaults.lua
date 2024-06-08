local store = require "imports.store"
--VEHICLE

if store.ox_inv then
    interact.addGlobalVehicle({
        id = 'ox:Trunk', --- special handling for this id. pulls trunk data from ox_inventory vehicles
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