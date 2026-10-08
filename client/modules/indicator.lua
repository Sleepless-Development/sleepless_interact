local config = require 'client.modules.config'

local indicator = {
    active = false,
}

local function loaderName()
    local name = config.indicator
    if type(name) ~= 'string' then return end

    name = name:lower()
    if name == '' or name == 'sprite' then return end
    if not name:match('^[%w_-]+$') then return end

    return name
end

local function setup()
    local name = loaderName()
    if not name then return end

    local css = LoadResourceFile(cache.resource, ('web/indicators/%s.css'):format(name))
    if not css then
        lib.print.warn(('indicator "%s" was not found, using the sprite'):format(name))
        return
    end

    local color = config.getThemeColor()
    local r = color[1] or 255
    local g = color[2] or 255
    local b = color[3] or 255
    local url = ('nui://%s/web/indicator.html?style=%s&accent=%d,%d,%d'):format(cache.resource, name, r, g, b)

    indicator.dui = lib.dui:new({
        url = url,
        width = 256,
        height = 256,
    })
    indicator.dict = indicator.dui.dictName
    indicator.txt = indicator.dui.txtName
    indicator.active = true
end

setup()

return indicator
