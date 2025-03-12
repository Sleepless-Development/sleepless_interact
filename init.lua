local export = exports.sleepless_interact

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
    name = 'sleepless_interact',
}, {
    __index = call,
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        if debug.getinfo(2, 'S').short_src:find('@sleepless_interact/client/api.lua') then
            exports(key, fn)
        end
    end
})

_ENV.interact = interact