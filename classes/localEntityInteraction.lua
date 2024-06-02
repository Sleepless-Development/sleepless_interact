local EntityInteraction = require 'classes.entityInteraction'
local utils = require 'imports.utils'

---@class LocalEntityInteraction: Interaction
---@field entity number entity handle.
local LocalEntityInteraction = lib.class('LocalEntityInteraction', EntityInteraction)

local DoesEntityExist = DoesEntityExist

function LocalEntityInteraction:constructor(data)
    self:super(data)
    self.entity = data.entity
end

function LocalEntityInteraction:getEntity()

    if self.shouldDestroy then return 0 end

    if not self:verifyEntity() then
        interact.removeById(self.id)
        return 0
    end
    return self.entity
end

function LocalEntityInteraction:verifyEntity()
    if not DoesEntityExist(self.entity) then
        lib.print.warn(string.format('entity didnt exist for interaction: %s. interaction removed', self.id))
        utils.clearCacheForInteractionEntity(self.entity)
        interact.removeById(self.id)
        return false
    end
    return true
end

return LocalEntityInteraction
