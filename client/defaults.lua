--VEHICLE
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
                return GetVehicleDoorLockStatus(veh) ~= 2
            end,
            action = function(interaction)
                local veh = interaction.entity
                SetVehicleDoorOpen(veh, 5, false, false)
                ExecuteCommand('+inv2')
            end
        },
    }
})

interact.addGlobalPlayer({
    id = 'global:Player',
    options = {
        {
            text = 'wave',
            icon = 'hand',
            action = function(interaction)
                ExecuteCommand('e wave4')
            end
        },
    }
})

interact.addGlobalPed({
    id = 'global:Ped',
    options = {
        {
            text = 'kill',
            icon = 'skull',
            canInteract = function(entity, distance, coords, id)
                return not IsEntityDead(entity)
            end,
            action = function(interaction)
                SetEntityHealth(NetToPed(interaction.netId), 0)
            end
        },
        {
            text = 'revive',
            icon = 'hand-holding-medical',
            canInteract = function(entity, distance, coords, id)
                return IsEntityDead(entity)
            end,
            action = function(interaction)
                local ped = NetToPed(interaction.netId)
                print(ped)
                ResurrectPed(ped)
                Wait(100)
                local coords = GetEntityCoords(ped)
                ClearPedTasksImmediately(ped)
                SetEntityCoords(ped, coords.x, coords.y, coords.z)
            end
        },
    }
})
