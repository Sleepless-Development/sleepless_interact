local utils = require 'imports.utils'
local store = require 'imports.store'
local dui = require 'imports.dui'
local config = require 'imports.config'
local indicator = config.defaultIndicatorSprite

local drawLoopRunning = false
local BuilderLoopRunning = false

LocalPlayer.state.interactBusy = false

lib.addKeybind({
    name = 'sleepless_interact:action',
    description = 'Interagir',
    defaultKey = 'E',
    onPressed = function(self)
        if store.activeInteraction then
            store.activeInteraction:handleInteract()
        end
    end,
})

store.hidePerKeybind = false
local defaultShowKeyBind = config.defaultShowKeyBind
local showKeyBindBehavior = config.showKeyBindBehavior
local useShowKeyBind = config.useShowKeyBind
if useShowKeyBind then
    store.hidePerKeybind = true
    lib.addKeybind({
        name = 'sleepless_interact:toggle',
        description = 'show interactions',
        defaultKey = defaultShowKeyBind,
        onPressed = function(self)
            if cache.vehicle then return end
            if showKeyBindBehavior == "toggle" then
                store.hidePerKeybind = not store.hidePerKeybind
                if store.hidePerKeybind then
                    BuilderLoopRunning = false
                else
                    BuilderLoop()
                end
            else
                store.hidePerKeybind = false
                BuilderLoop()
            end
        end,
        onReleased = function(self)
            if showKeyBindBehavior == "toggle" or cache.vehicle then return end
            store.hidePerKeybind = true
            BuilderLoopRunning = false
        end
    })
end

local drawPrint = false

local function drawLoop()
    lib.requestStreamedTextureDict(indicator.dict)

    while next(store.nearby) do
        ---@type Interaction[]
        local newActives = {}
        local DUIOptions = {}
        local alreadyDraw = false

        for i = 1, #store.nearby do
            local interaction = store.nearby[i]
            local active = false

            if interaction:shouldBeActive() and utils.checkOptions(interaction) then
                newActives[interaction.id] = interaction
                active = true

                DUIOptions[#DUIOptions + 1] = interaction.DuiOptions

                dui.handleDuiControls()
            end

            if interaction.isActive ~= active then
                interaction.isActive = active
            end

            if not active or (active and not alreadyDraw) then
                alreadyDraw = true
                interaction:drawSprite()
            end
        end


        if #DUIOptions > 0 and not lib.table.matches(store.activeInteractions, newActives) then
            store.menuBusy = true

            dui.updateMenu('updateInteraction',
                { options = DUIOptions })

            SetTimeout(100, function()
                store.menuBusy = false
            end)
        end

        local hasNext = next(newActives)

        if (not hasNext and next(store.activeInteractions)) or (hasNext and not lib.table.matches(store.activeInteractions, newActives)) then
            store.activeInteractions = {}
        end

        if store.activeInteraction and not hasNext then
            dui.updateMenu('updateInteraction', nil)
        end

        if newActives then
            store.activeInteractions = newActives
        end

        if drawPrint then
            drawPrint = false
            print('yes draw loop is running')
        end
        Wait(0)
    end
    SetStreamedTextureDictAsNoLongerNeeded(indicator.dict)
    drawLoopRunning = false
end

local builderPrint = false

function BuilderLoop()
    if BuilderLoopRunning then return end
    BuilderLoopRunning = true
    while BuilderLoopRunning do
        if utils.shouldHideInteractions() then
            store.nearby = {}
        else
            utils.checkEntities()
            local nearby = {}

            for i = 1, #store.Interactions do
                local interaction = store.Interactions[i]

                if interaction and interaction:shouldRender() and utils.checkOptions(interaction) then
                    nearby[#nearby + 1] = interaction
                end
            end

            table.sort(nearby, function(a, b)
                return a.currentDistance < b.currentDistance
            end)

            store.nearby = nearby

            if #store.nearby > 0 and not drawLoopRunning then
                drawLoopRunning = true
                CreateThread(drawLoop)
            end

            if builderPrint then
                builderPrint = false
                print('yes builder is running')
            end
        end
        Wait(500)
    end
    store.nearby = {}
end

RegisterNetEvent('onResourceStop', function(resourceName)
    for i = #store.globalVehicle, 1, -1 do
        local data = store.globalVehicle[i]
        if data.resource == resourceName then
            store.globalIds[data.id] = nil
            table.remove(store.globalVehicle, i)
        end
    end


    for i = #store.globalVehicle, 1, -1 do
        local data = store.globalVehicle[i]
        if data.resource == resourceName then
            store.globalIds[data.id] = nil
            table.remove(store.globalVehicle, i)
        end
    end


    for i = #store.globalVehicle, 1, -1 do
        local data = store.globalVehicle[i]
        if data.resource == resourceName then
            store.globalIds[data.id] = nil
            table.remove(store.globalVehicle, i)
        end
    end
end)


RegisterCommand('checkInteractions', function(source, args, raw)
    print('==========================================================================================')
    lib.print.info('number of ALL interactions:', #store.Interactions)
    lib.print.info('number of NEARBY interactions:', #store.nearby)
    lib.print.info('is builder running?', BuilderLoopRunning)
    builderPrint = true
    Wait(1000)
    lib.print.info('is draw running?', drawLoopRunning)
    drawPrint = true
    lib.print.info(msgpack.unpack(msgpack.pack(store)))
    print('==========================================================================================')
end)
