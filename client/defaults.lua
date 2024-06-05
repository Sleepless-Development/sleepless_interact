--VEHICLE
local ox_inv = GetResourceState('ox_inventory'):find('start')

    interact.addGlobalVehicle({
        id = 'global:vehicle:Trunk',
        bone = 'boot',
        activeDistance = 2.0,
        renderDistance = 5.0,
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


local coords1 = GetEntityCoords(cache.ped)
local coords2 = GetOffsetFromEntityInWorldCoords(cache.ped, 0, 10.0, 0)

-- interact.addCoords({
--     id = 'someId',
--     coords = coords1,
--     renderDistance = 20.0,
--     options = {
--         {
--             label = 'something',
--             icon = 'hand',
--             canInteract = function(entity, distance, coords, id)
--                 return true
--             end,
--             onSelect = function(interaction)
--                 print('yo')
--             end
--         },
--     }
-- })

interact.addGlobalPlayer({
    id = 'someId',
    renderDistance = 20.0,
    options = {
        {
            label = 'something',
            icon = 'hand',
            canInteract = function(entity, distance, coords, id)
                return true
            end,
            onSelect = function(interaction)
                print('yo')
            end
        },
    }
})

local props = {
	"prop_gas_pump_1d",
	"prop_gas_pump_1a",
	"prop_gas_pump_1b",
	"prop_gas_pump_1c",
	"prop_vintage_pump",
	"prop_gas_pump_old2",
	"prop_gas_pump_old3",
	"denis3d_prop_gas_pump", -- Gabz Ballas Gas Station Pump.
}


interact.addGlobalModel({
    id = "modelTest",
    models = props,
    offset = vec3(0,0,1),
    options = {
        {
            text = "Interact with Model",
            icon = "hand",  -- Example simple FA icon name
            action = function(data) print("Model interaction triggered") end,
        },
        {
            text = "Interact with Model",
            icon = "hand",  -- Example simple FA icon name
            action = function(data) print("Model interaction triggered") end,
        },
        {
            text = "?",
            icon = "vault",  -- Example simple FA icon name
            action = function(data) print("Model interaction triggered") end,
        }
    },
    renderDistance = 10.0,
    activeDistance = 2.0,
    cooldown = 1500
})


RegisterCommand('testremove', function()
    interact.removeGlobalModel('modelTest')
end)

RegisterCommand('testupdate', function()
    interact.addGlobalModel({
        id = "modelTest",
        models = props,
        offset = vec3(0,0,0.3),
        options = {
            {
                text = "?",
                icon = "vault",  -- Example simple FA icon name
                action = function(data) print("Model interaction triggered") end,
            }
        },
        renderDistance = 10.0,
        activeDistance = 2.0,
        cooldown = 1500
    })
end)