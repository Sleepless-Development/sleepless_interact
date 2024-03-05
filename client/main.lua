local globals = require 'imports.globals'
local utils = require 'imports.utils'
local dui = require 'imports.dui'
local updateMenu, handleDuiControls in dui
local ClosestInteraction = nil
local ActiveInteraction

lib.addKeybind({
    name = 'sleepless_interact',
    description = 'Interact',
    defaultKey = 'E',
    onPressed = function(self)
        if ActiveInteraction then
            ActiveInteraction:handleInteract()
        end
    end,
})

RegisterNuiCallback('setCurrentTextOption', function(data, cb)
    cb(1)
    if not ActiveInteraction then return end
    ActiveInteraction:setCurrentTextOption(data.index)
end)

local nearbyInteractions = {}

local function drawTick()
    globals.DrawTickRunning = true
    while next(nearbyInteractions) do
        local newActiveInteraction
        for i = 1, #nearbyInteractions do
            local interaction = nearbyInteractions[i]
            local active = ClosestInteraction == interaction and interaction:shouldBeActive()
            interaction.isActive = active
            if active then
                if interaction.action or utils.checkOptions(interaction) then
                    newActiveInteraction = interaction
                    if newActiveInteraction ~= ActiveInteraction then
                        updateMenu('updateInteraction', {id = interaction.id, options = (interaction.action and {}) or interaction.textOptions})
                    end
                    ActiveInteraction = interaction
                    handleDuiControls()
                else
                    interaction.isActive = false
                end
            end
            interaction:drawSprite()
        end
        ActiveInteraction = newActiveInteraction
        Wait(0)
    end
    globals.DrawTickRunning = false
    ActiveInteraction = nil
end

local mainLoopRunning = false
function MainLoop()
    if mainLoopRunning then return end
    mainLoopRunning = true
    while mainLoopRunning do
        local newNearbyInteractions = {}
        utils.checkEntities()
        table.sort(globals.Interactions, function (a, b)
            return (a?.currentDistance or 999) < (b?.currentDistance or 999)
        end)
        ClosestInteraction = nil

        for i = 1, #globals.Interactions do
            local interaction = globals.Interactions[i]
            if interaction then
                if interaction.shouldDestroy then
                    globals.Interactions[i] = nil
                else
                    if interaction:shouldRender() then
                        if not ClosestInteraction then
                            ClosestInteraction = globals.Interactions[i]
                        end
                        newNearbyInteractions[#newNearbyInteractions + 1] = interaction
                    end
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

AddStateBagChangeHandler("invOpen", nil, function(bagName, _, state)
    if GetPlayerFromStateBagName(bagName) ~= cache.playerId then return end

    if state then
        mainLoopRunning = false
    else
        if not cache.vehicle then
            MainLoop()
        end
    end
end)

lib.onCache('vehicle', function (vehicle)
    if vehicle then
        mainLoopRunning = false
    else
        MainLoop()
    end
end)
