---Thanks linden https://github.com/overextended
local export = exports.demi_interact

local function call(self, index, ...)
    local function method(...)
        return export[index](nil, ...)
    end

    if not ... then
        self[index] = method
    end

    return method
end

local interact = setmetatable({
    name = 'demi_interact',
}, {
    __index = call,
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        if debug.getinfo(2, 'S').short_src:find('@demi_interact/exports') then
            exports(key, fn)
        end
    end
})

_ENV.interact = interact
