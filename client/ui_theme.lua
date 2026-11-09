local GLOBAL_CONVAR = 'sleepless:ui:primary'
local RESOURCE_CONVAR = ('%s:ui:primary'):format(GetCurrentResourceName())
local invalidValues = {}

local function readPrimaryColor(name)
    local value = GetConvar(name, ''):match('^%s*(.-)%s*$')
    if value == '' then return end

    local hex = value:gsub('^#', '')
    if #hex == 6 and hex:match('^%x+$') then
        return '#' .. hex:lower()
    end

    if invalidValues[name] ~= value then
        invalidValues[name] = value
        print(('[%s] %s must be a six-digit hex color; ignoring invalid value.'):format(GetCurrentResourceName(), name))
    end
end

---@return string?
function GetUiPrimaryColor()
    return readPrimaryColor(RESOURCE_CONVAR) or readPrimaryColor(GLOBAL_CONVAR)
end

local function getUiTheme(_, cb)
    cb({ primary = GetUiPrimaryColor() or false })
end

RegisterNUICallback('sleeplessUiTheme', getUiTheme)
