local Groups = {}
local Loaded = false

RegisterNetEvent('esx:setPlayerData', function(key, value)
	if not Loaded or GetInvokingResource() ~= 'es_extended' then return end

    if key ~= 'job' then return end

    Groups = { [value.name] = value.grade }
    TriggerEvent('demi_interact:updateGroups', Groups)
end)

RegisterNetEvent('esx:playerLoaded',function(xPlayer)
    Groups = {
            [xPlayer.job.name] = xPlayer.job.grade,
        }
    Loaded = true
    TriggerEvent('demi_interact:updateGroups', Groups)
    TriggerEvent('demi_interact:LoadDui')
    MainLoop()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Groups = table.wipe(Groups)
end)

return Groups