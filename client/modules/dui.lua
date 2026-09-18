local store = require 'client.modules.store'
local config = require 'client.modules.config'
local utils = require 'client.modules.utils'

local dui = {}
local controlsRunning = false
local lastInteractKey
dui.anchorX = 0.07
dui.anchorY = 0.5

function dui.register()
    if dui.instance then
        dui.instance:remove()
    end

    lastInteractKey = nil

    local screenW, screenH = GetActualScreenResolution()
    local spriteScale = config.duiScale or 0.12
    local superSample = 2
    local aspect = 2.4
    local height = math.max(2, math.floor(screenH * spriteScale * superSample + 0.5))
    local width = math.max(2, math.floor(height * aspect + 0.5))
    width = width - (width % 2)
    height = height - (height % 2)

    local maxEdge = config.duiResolution or 2048
    local longEdge = math.max(width, height)
    if longEdge > maxEdge then
        local fit = maxEdge / longEdge
        width = math.max(2, math.floor(width * fit + 0.5))
        height = math.max(2, math.floor(height * fit + 0.5))
        width = width - (width % 2)
        height = height - (height % 2)
    end

    dui.width = width
    dui.height = height

    dui.instance = lib.dui:new(
        {
            url = ("nui://%s/web/index.html"):format(cache.resource),
            width = width,
            height = height,
        }
    )

    while not dui.loaded do Wait(100) end

    dui.sendMessage('visible', false)
    dui.sendMessage('setTheme', config.theme or 'modern')
    if config.themeColor then
        dui.sendMessage('setColor', config.themeColor)
    end
    dui.sendMessage('setMenu', {
        compact = config.compactOptions ~= false,
        idleMs = config.compactIdleMs or 2500,
    })
    dui.syncLocales()
end

function dui.syncInteractKey()
    if not dui.instance then return end

    local key = utils.toHumanKeybind('+interact_action')
    if key == lastInteractKey then return end
    lastInteractKey = key

    dui.instance:sendMessage({
        action = 'setKey',
        value = key,
    })
end

function dui.syncLocales()
    if not dui.instance then return end

    dui.instance:sendMessage({
        action = 'setLabel',
        value = locale('interact'),
    })
end

AddEventHandler('ox_lib:setLocale', function()
    dui.syncLocales()
end)

RegisterNuiCallback('load', function(_, cb)
    dui.loaded = true
    Wait(1000)
    cb(1)
end)

RegisterNuiCallback('currentOption', function(data, cb)
    store.current.index = data[1]
    cb(1)
end)

RegisterNuiCallback('promptAnchor', function(data, cb)
    if type(data) == 'table' then
        if type(data.x) == 'number' then
            dui.anchorX = data.x
        end
        if type(data.y) == 'number' then
            dui.anchorY = data.y
        end
    end
    cb(1)
end)

function dui.sendMessage(action, value)
    dui.instance:sendMessage({
        action = action,
        value = value
    })

    if action == 'setOptions' then
        dui.syncInteractKey()
    end

    if action == 'setOptions' and not controlsRunning then
        if controlsRunning then return end
        controlsRunning = true
        CreateThread(function()
            while next(store.current) do
                dui.handleDuiControls()
                Wait(0)
            end
            controlsRunning = false
        end)
    end
end

local IsControlJustPressed = IsControlJustPressed
local SendDuiMouseWheel = SendDuiMouseWheel

dui.handleDuiControls = function()
    if not dui.instance?.duiObject then return end

    local input = false

    if (IsControlJustPressed(3, 180)) then -- SCROLL DOWN
        SendDuiMouseWheel(dui.instance.duiObject, -50, 0.0)
        input = true
    end

    if (IsControlJustPressed(3, 181)) then -- SCROLL UP
        SendDuiMouseWheel(dui.instance.duiObject, 50, 0.0)
        input = true
    end

    if (IsControlJustPressed(3, 173)) then -- ARROW DOWN
        SendDuiMouseWheel(dui.instance.duiObject, -50, 0.0)
        input = true
    end

    if (IsControlJustPressed(3, 172)) then -- ARROW UP
        SendDuiMouseWheel(dui.instance.duiObject, 50, 0.0)
        input = true
    end

    if input then
        Wait(110)
    end
end

dui.register() --- on load and on resource start?

return dui
