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

function LocalEntityInteraction:update(data)
    self.private.cooldown = data.cooldown

    self.id = data.id
    self.renderDistance = data.renderDistance
    self.activeDistance = data.activeDistance
    self.resource = data.resource
    self.action = data.action
    self.options = data.options

    self.textOptions = {}


    if self.action then
        self.options = {}
    else
        for i = 1, #self.options do
            self.textOptions[i] = { text = self.options[i].text, icon = self.options[i].icon }
        end
    end

    
    self.bone = data.bone
    self.entity = data.entity
    self.offset = data.offset
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
    if self.shouldDestroy then return end

    if not DoesEntityExist(self.entity) then
        self.shouldDestroy = true
        lib.print.warn(string.format('entity didnt exist for interaction: %s. interaction removed', self.id))
        utils.clearCacheForInteractionEntity(self.entity)
        interact.removeById(self.id)
        return false
    end
    return true
end

return LocalEntityInteraction
