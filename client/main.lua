local globals = require 'imports.globals'
local utils = require 'imports.utils'
local dui = require 'imports.dui'
local config = require 'imports.config'
local updateMenu = dui.updateMenu
local handleDuiControls = dui.handleDuiControls
local ClosestInteraction = nil
local ActiveInteraction
local mainLoopRunning = false


LocalPlayer.state.interactBusy = false

lib.addKeybind({
    name = 'sleepless_interact:action',
    description = 'Interact',
    defaultKey = 'E',
    onPressed = function(self)
        if ActiveInteraction then
            ActiveInteraction:handleInteract()
        end
    end,
})

local hideInteractions = false
local defaultShowKeyBind = config.defaultShowKeyBind
local showKeyBindBehavior = config.showKeyBindBehavior
local useShowKeyBind = config.useShowKeyBind
if useShowKeyBind then
    hideInteractions = true
    lib.addKeybind({
        name = 'sleepless_interact:toggle',
        description = 'show interactions',
        defaultKey = defaultShowKeyBind,
        onPressed = function(self)
            if cache.vehicle then return end
            if showKeyBindBehavior == "toggle" then
                hideInteractions = not hideInteractions
                if hideInteractions then
                    mainLoopRunning = false
                else
                    MainLoop()
                end
            else
                hideInteractions = false
                MainLoop()
            end
        end,
        onReleased = function(self)
            if showKeyBindBehavior == "toggle" or cache.vehicle then return end
            hideInteractions = true
            mainLoopRunning = false
        end
    })
end

RegisterNuiCallback('setCurrentTextOption', function(data, cb)
    cb(1)
    if not ActiveInteraction then return end
    ActiveInteraction:setCurrentTextOption(data.index)
end)

local nearbyInteractions = {}

local function drawTick()
    globals.DrawTickRunning = true
    local menuBusy = false
    while next(nearbyInteractions) do
        local newActiveInteraction
        for i = 1, #nearbyInteractions do
            local interaction = nearbyInteractions[i]
            local active = ClosestInteraction == interaction and interaction:shouldBeActive()
            interaction.isActive = active
            if active then
                if interaction.action or utils.checkOptions(interaction) then
                    newActiveInteraction = interaction
                    if newActiveInteraction and newActiveInteraction ~= ActiveInteraction then
                        menuBusy = true
                        SetTimeout(0, function()
                            updateMenu('updateInteraction',
                                { id = interaction.id, options = (interaction.action and {}) or interaction.textOptions })
                            Wait(100)
                            menuBusy = false
                        end)
                    end
                    ActiveInteraction = interaction
                    handleDuiControls()
                else
                    interaction.isActive = false
                end
            end
            interaction:drawSprite(menuBusy)
        end
        if ActiveInteraction and not newActiveInteraction then
            updateMenu('updateInteraction', nil)
        end
        ActiveInteraction = newActiveInteraction
        Wait(0)
    end
    globals.DrawTickRunning = false
    ActiveInteraction = nil
end


function MainLoop()
    if mainLoopRunning or hideInteractions or LocalPlayer.state.interactBusy then return end
    mainLoopRunning = true
    while mainLoopRunning and not hideInteractions and not LocalPlayer.state.interactBusy do
        local newNearbyInteractions = {}
        utils.checkEntities()
        table.sort(globals.Interactions, function(a, b)
            return (a?.currentDistance or 999) < (b?.currentDistance or 999)
        end)
        ClosestInteraction = nil

        for i = 1, #globals.Interactions do
            local interaction = globals.Interactions[i]
            if interaction then
                if interaction:shouldRender() and utils.checkOptions(interaction) then
                    if not ClosestInteraction then
                        ClosestInteraction = globals.Interactions[i]
                    end
                    newNearbyInteractions[#newNearbyInteractions + 1] = interaction
                end
            end
        end
        nearbyInteractions = newNearbyInteractions

        if not globals.DrawTickRunning and next(nearbyInteractions) then
            CreateThread(drawTick)
        end

        Wait(500)
    end
    nearbyInteractions = {}
end

AddStateBagChangeHandler("invOpen", ('player:%s'):format(cache.serverId), function(bagName, _, state)
    if state then
        mainLoopRunning = false
    else
        if not cache.vehicle then
            MainLoop()
        end
    end
end)

AddStateBagChangeHandler("interactBusy", ('player:%s'):format(cache.serverId), function(bagName, _, state)
    if state then
        mainLoopRunning = false
    else
        if not cache.vehicle then
            MainLoop()
        end
    end
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle then
        mainLoopRunning = false
    else
        MainLoop()
    end
end)

RegisterNetEvent('onResourceStop', function(resourceName)
    for model, modeldata in pairs(globals.Models) do
        for i = #modeldata, 1, -1 do
            local data = modeldata[i]
            if data.resource == resourceName then
                table.remove(globals.Models[model], i)
            end
        end
    end

    for i = #globals.playerInteractions, 1, -1 do
        local data = globals.playerInteractions[i]
        if data.resource == resourceName then
            table.remove(globals.playerInteractions, i)
        end
    end

    for i = #globals.vehicleInteractions, 1, -1 do
        local data = globals.vehicleInteractions[i]
        if data.resource == resourceName then
            table.remove(globals.vehicleInteractions, i)
        end
    end

    for i = #globals.pedInteractions, 1, -1 do
        local data = globals.pedInteractions[i]
        if data.resource == resourceName then
            table.remove(globals.pedInteractions, i)
        end
    end
end)


RegisterCommand('checkInteractions', function()
    lib.print.warn('number of interactions: ', #globals.Interactions)
    lib.print.warn(msgpack.unpack(msgpack.pack(globals.Interactions)))
end, false)