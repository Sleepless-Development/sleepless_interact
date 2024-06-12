local Interaction = require 'classes.interaction'
local utils = require 'imports.utils'
local store = require 'imports.store'

---@class LocalEntityInteraction: Interaction
local LocalEntityInteraction = lib.class('LocalEntityInteraction', Interaction)

function LocalEntityInteraction:constructor(data)
    self:super(data)
    if not self.id then return end
    self.entity = data.entity
    self.bone = data.bone
    self.offset = data.offset
end

function LocalEntityInteraction:update(data)
    utils.loadInteractionDefaults(data, self.resource)

    self.renderDistance = data.renderDistance
    self.activeDistance = data.activeDistance
    self.options = data.options
    self.DuiOptions = {}

    self.private.cooldown = data.cooldown

    for i = 1, #self.options do
        self.DuiOptions[i] = { text = self.options[i].label or self.options[i].text, icon = self.options[i].icon }
    end

    self.entity = data.entity
    self.bone = data.bone
    self.offset = data.offset
    self.removeWhenDead = data.removeWhenDead
end

function LocalEntityInteraction:getEntity()
    if self.isDestroyed or not self:verifyEntity() then
        return 0
    end
    return self.entity
end

function LocalEntityInteraction:verifyEntity()
    if not self.isDestroyed and ((self.globalType and not DoesEntityExist(self.entity)) or (self.removeWhenDead and IsEntityDead(self.entity))) then
        self.isDestroyed = true
        lib.print.warn(string.format("entity didnt exist for interaction id '%s'. interaction removed", self.id))
        interact.removeById(self.id)
        if self.globalType then
            utils.wipeCacheForEntityKey(self.globalType, self.entity)
        end
        return false
    end
    return true
end

function LocalEntityInteraction:shouldRender()
    if not self.isDestroyed and not self:verifyEntity() then return false end

    self.currentDistance = self:getDistance()
    return self.currentDistance <= self.renderDistance
end

function LocalEntityInteraction:shouldBeActive()
    return not self.isDestroyed and self.currentDistance <= self.activeDistance
end

function LocalEntityInteraction:getCoords()
    local entity = self:getEntity()
    local offset = self.offset
    local bone = self.bone

    if store.ox_inv and self.id:find('ox:Trunk') then
        local pos = utils.getTrunkPosition(entity)
        if pos then
            return pos
        end
    end

    if bone then
        local boneIndex = GetEntityBoneIndexByName(entity, bone)

        if boneIndex ~= -1 then
            local bonePos = GetEntityBonePosition_2(entity, boneIndex)
            return offset and GetOffsetFromCoordAndHeadingInWorldCoords(bonePos.x, bonePos.y, bonePos.z, GetEntityHeading(entity),offset .x, offset.y, offset.z) or bonePos
        end
    end

    return offset and GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z) or GetEntityCoords(entity)
end

function LocalEntityInteraction:getDistance()
    return #(self:getCoords() - GetEntityCoords(cache.ped))
end

return LocalEntityInteraction
