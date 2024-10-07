local LocalEntityInteraction = require 'classes.localEntityInteraction'
local utils = require 'imports.utils'

---@class NetEntityInteraction: Interaction
local NetEntityInteraction = lib.class('NetEntityInteraction', LocalEntityInteraction)

function NetEntityInteraction:constructor(data)
    self:super(data)
    self.netId = data.netId
end

function NetEntityInteraction:update(data)
    utils.loadInteractionDefaults(data, self.resource)

    self.renderDistance = data.renderDistance
    self.activeDistance = data.activeDistance
    self.text = data.text
    self.label = data.label
    self.icon = data.icon
    self.groups = data.groups
    self.items = data.items
    self.anyItem = data.anyItem
    self.remove = data.remove
    self.canInteract = data.canInteract
    self.onSelect = data.onSelect
    self.export = data.export
    self.event = data.event
    self.serverEvent = data.serverEvent
    self.command = data.command
    self.bones = data.bones
    self.private.cooldown = data.cooldown
    self.DuiOptions = { id = self.id, text = self.label or self.text, icon = self.icon }


    self.netId = data.netId
    self.bone = data.bone
    self.offset = data.offset
    self.removeWhenDead = data.removeWhenDead
end

function NetEntityInteraction:getEntity()
    if self.isDestroyed or not self:verifyEntity() then
        return 0
    end
    self.entity = NetworkGetEntityFromNetworkId(self.netId)
    return self.entity
end

function NetEntityInteraction:verifyEntity()
    if not self.isDestroyed and ((self.globalType and not NetworkDoesEntityExistWithNetworkId(self.netId)) or (self.removeWhenDead and IsEntityDead(NetworkGetEntityFromNetworkId(self.netId)))) then
        self.isDestroyed = true
        lib.print.warn(string.format('entity didnt exist with netid %s for interaction: %s. interaction removed',
            self.netId, self.id))
        interact.removeById(self.id)
        if self.globalType then
            utils.wipeCacheForEntityKey(self.globalType, self.netId)
        end
        return false
    end
    return true
end

return NetEntityInteraction
