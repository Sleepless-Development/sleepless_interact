local animation = {}

local createdProps = {}

local currentAnim = nil

local function createProp(ped, prop)
    lib.requestModel(prop.model)
    local coords = GetEntityCoords(ped)
    local object = CreateObject(prop.model, coords.x, coords.y, coords.z, false, false, false)

    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, prop.bone or 60309), prop.pos.x, prop.pos.y, prop.pos.z, prop.rot.x, prop.rot.y, prop.rot.z, true, true, false, true, prop.rotOrder or 0, true)
    SetModelAsNoLongerNeeded(prop.model)
    return object
end

local function deleteProgressProps(serverId)
    local playerProps = createdProps[serverId]
    if not playerProps then return end
    for i = 1, #playerProps do
        local prop = playerProps[i]
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    createdProps[serverId] = nil
end

function animation.playAnim(anim, prop)
    if anim.dict then
        currentAnim = anim

        lib.requestAnimDict(anim.dict)

        TaskPlayAnim(cache.ped, anim.dict, anim.clip, anim.blendIn or 3.0, anim.blendOut or 1.0, anim.duration or -1, anim.flag or 49, anim.playbackRate or 0,
            anim.lockX, anim.lockY, anim.lockZ)
        RemoveAnimDict(anim.dict)
    elseif anim.scenario then
        TaskStartScenarioInPlace(cache.ped, anim.scenario, 0, anim.playEnter == nil or anim.playEnter --[[@as boolean]])
    end

    if prop then
        TriggerServerEvent('Interact:SetHoldProps', prop)
    end
end

function animation.stopAnim()
    if currentAnim then
        if currentAnim.dict then
            StopAnimTask(cache.ped, currentAnim.dict, currentAnim.clip, 1.0)
            Wait(0)
        else
            ClearPedTasks(cache.ped)
        end
        currentAnim = nil
    end

    TriggerServerEvent('Interact:SetHoldProps', nil)
end

AddStateBagChangeHandler('interact:holdProps', nil, function(bagName, key, value, reserved, replicated)
    if replicated then return end

    local ply = GetPlayerFromStateBagName(bagName)
    if ply == 0 then return end

    local ped = GetPlayerPed(ply)
    local serverId = GetPlayerServerId(ply)

    if not value then
        return deleteProgressProps(serverId)
    end

    createdProps[serverId] = {}
    local playerProps = createdProps[serverId]

    if value.model then
        playerProps[#playerProps + 1] = createProp(ped, value)
    else
        for i = 1, #value do
            local prop = value[i]

            if prop then
                playerProps[#playerProps + 1] = createProp(ped, prop)
            end
        end
    end
end)

return animation
