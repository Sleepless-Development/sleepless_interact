local EntityInteraction = require 'classes.entityInteraction'

---@class LocalEntityInteraction: Interaction
---@field entity number entity handle.
local LocalEntityInteraction = lib.class('LocalEntityInteraction', EntityInteraction)

local DoesEntityExist = DoesEntityExist

function LocalEntityInteraction:init()
    self:super()
end

function LocalEntityInteraction:getEntity()

    if self.shouldDestroy then return 0 end

    if not DoesEntityExist(self.entity) then
        self:destroy()
        return 0
    end
    return self.entity
end

function LocalEntityInteraction:verifyEntity()
    if not DoesEntityExist(self.entity) then
        lib.print.warn(string.format('entity didnt exist for interaction: %s. interaction removed', self.id))
        self:destroy()
        return false
    end
end

return LocalEntityInteraction
