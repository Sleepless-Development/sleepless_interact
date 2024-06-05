local dui = {}
local config = require('imports.config')
local color = config.color
local store = require 'imports.store'

dui.txdName = "interaction_dui"
dui.txtName = "interaction_dui_texture"
dui.txd = CreateRuntimeTxd(dui.txdName)
dui.screenW, dui.screenH = GetActiveScreenResolution()
dui.loaded = false

RegisterNuiCallback('loaded', function(_, cb)
    cb(1)
    dui.loaded = true
end)

RegisterNuiCallback('setCurrentTextOption', function(data, cb)
    cb(1)
    if not store.activeInteraction then return end
    store.currentOptionIndex = data.index
end)

local function loadDui()
    dui.DuiObject = CreateDui("https://cfx-nui-sleepless_interact/web/build/index.html", dui.screenW, dui.screenH)
    CreateRuntimeTextureFromDuiHandle(dui.txd, dui.txtName, GetDuiHandle(dui.DuiObject))
    while not dui.loaded do
        Wait(100)
    end
    SendDuiMessage(dui.DuiObject, json.encode({
        action = 'setColor',
        data = color
    }))
end

RegisterNetEvent('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SetStreamedTextureDictAsNoLongerNeeded("interaction_dui")
end)

RegisterNetEvent('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    loadDui()
end)

RegisterNetEvent('sleepless_interact:LoadDui', loadDui)

local lastScroll = 0
dui.handleDuiControls = function()
    local time = GetGameTimer()
    if time - lastScroll < 100 or not dui.DuiObject then return end

    if (IsControlJustPressed(3, 180)) then -- SCROLL DOWN
        lastScroll = time
        SendDuiMouseWheel(dui.DuiObject, -50, 0.0)
    end

    if (IsControlJustPressed(3, 181)) then -- SCROLL UP
        lastScroll = time
        SendDuiMouseWheel(dui.DuiObject, 50, 0.0)
    end

    if (IsControlJustPressed(3, 173)) then -- ARROW DOWN
        lastScroll = time
        SendDuiMouseWheel(dui.DuiObject, -50, 0.0)
    end

    if (IsControlJustPressed(3, 172)) then -- ARROW UP
        lastScroll = time
        SendDuiMouseWheel(dui.DuiObject, 50, 0.0)
    end
end

dui.updateMenu = function(action, data)
    if not dui.DuiObject then return end
    SendDuiMessage(dui.DuiObject, json.encode({
        action = action,
        data = data
    }))
end

return dui
