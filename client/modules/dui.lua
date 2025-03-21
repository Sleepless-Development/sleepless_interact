local store = require 'client.modules.store'
local config = require 'client.modules.config'

local dui = {}
local screenW, screenH = GetActualScreenResolution()
local controlsRunning = false

function dui.register()
    if dui.instance then
        dui.instance:remove()
    end

    dui.instance = lib.dui:new(
        {
            url = ("nui://%s/web/index.html"):format(cache.resource),
            width = screenW,
            height = screenH,
        }
    )

    while not dui.loaded do Wait(100) end

    dui.sendMessage('visible', true)
    dui.sendMessage('setColor', config.themeColor)
end

RegisterNuiCallback('load', function(_, cb)
    dui.loaded = true
    Wait(1000)
    cb(1)
end)

RegisterNuiCallback('currentOption', function(data, cb)
    store.current.index = data[1]
    cb(1)
end)

function dui.sendMessage(action, value)
    dui.instance:sendMessage({
        action = action,
        value = value
    })

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
        Wait(200)
    end
end

dui.register() --- on load and on resource start?

return dui
