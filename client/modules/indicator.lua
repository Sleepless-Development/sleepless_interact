local config = require 'client.modules.config'

local indicator = {
    active = false,
}

local function loaderName()
    local name = config.indicator
    if type(name) ~= 'string' then return end

    name = name:lower()
    if not name:match('^[%w_-]+$') then return end

    return name
end

local function channel(value, fallback)
    local number = tonumber(value)
    if not number then return fallback end
    return math.max(0, math.min(255, math.floor(number + 0.5)))
end

local function alphaFraction(value)
    if value == nil then return end

    local number = tonumber(value)
    if not number then return end
    if number <= 1 then
        return math.max(0, number)
    end

    return math.max(0, math.min(255, number)) / 255
end

local function colorQuery(color, fallback)
    local source = color or fallback
    local r = channel(source[1], 255)
    local g = channel(source[2], 255)
    local b = channel(source[3], 255)
    local alpha = color and alphaFraction(color[4])
    if alpha == nil then
        return ('%d,%d,%d'):format(r, g, b)
    end

    return ('%d,%d,%d,%.3f'):format(r, g, b, alpha)
end

local function isWhite(color)
    if not color then return true end

    local alpha = alphaFraction(color[4])
    return channel(color[1], 255) == 255
        and channel(color[2], 255) == 255
        and channel(color[3], 255) == 255
        and (alpha == nil or alpha >= 0.999)
end

local function setup()
    local name = loaderName()
    if not name then
        lib.print.warn('indicator id is missing')
        return
    end

    local css = LoadResourceFile(cache.resource, ('web/indicators/%s.css'):format(name))
    if not css then
        lib.print.warn(('indicator "%s" was not found'):format(name))
        return
    end

    local chosen = config.indicatorColors
    local color1 = chosen and chosen[1] or nil
    local color2 = chosen and chosen[2] or nil
    local override = (not isWhite(color1) or color2 ~= nil) and '1' or '0'
    local url = ('nui://%s/web/indicator.html?style=%s&color1=%s&color2=%s&override=%s'):format(
        cache.resource,
        name,
        colorQuery(color1, { 255, 255, 255 }),
        colorQuery(color2, config.getThemeColor()),
        override
    )

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
