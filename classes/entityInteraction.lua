local Interaction = require 'classes.interaction'
local utils = require 'imports.utils'
local ox_inv = GetResourceState('ox_inventory'):find('start')

---@class EntityInteraction: Interaction
---@field netId number entity network id
---@field bone? string | table<string>
---@field offset? vector3 Optional offset for the placement of interaction if on an entity
local EntityInteraction = lib.class('EntityInteraction', Interaction)

local GetEntityCoords = GetEntityCoords
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetEntityBoneIndexByName = GetEntityBoneIndexByName

function EntityInteraction:constructor(data)
    self:super(data)
    self.bone = data.bone
    self.netId = data.netId
    self.offset = data.offset
end

function EntityInteraction:getEntity()
    if self.shouldDestroy or not self:verifyEntity() then return 0 end

    return NetworkGetEntityFromNetworkId(self.netId)
end

function EntityInteraction:verifyEntity()
    if not NetworkDoesNetworkIdExist(self.netId) or not NetworkDoesEntityExistWithNetworkId(self.netId) then
        lib.print.warn(string.format('entity didnt exist with netid %s for interaction: %s. interaction removed', self.netId, self.id))
        utils.clearCacheForInteractionEntity(self.netId)
        interact.removeById(self.id)
        return false
    end
    return true
end

function EntityInteraction:shouldRender()
    if self.shouldDestroy or not self:verifyEntity() then return false end

    self.currentDistance = self:getDistance()
    return self.currentDistance <= self.renderDistance
end

function EntityInteraction:shouldBeActive()
    return self.currentDistance <= self.activeDistance
end

function EntityInteraction:getCoords()
    local entity = self:getEntity()
    local offset = self.offset
    local bone = self.bone

    if bone then
        if ox_inv and bone == 'boot' then
            return utils.getTrunkPosition(entity)
        end
        local boneIndex = GetEntityBoneIndexByName(entity, bone)
        if boneIndex ~= -1 then
            return GetEntityBonePosition_2(entity, boneIndex)
        end
    end

    return offset and GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z) or GetEntityCoords(entity)
end

function EntityInteraction:getDistance()
    local coords = self:getCoords()
    return coords and #(coords - GetEntityCoords(cache.ped)) or 999
end

return EntityInteraction
