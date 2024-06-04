local Interaction = require 'classes.interaction'
local utils = require 'imports.utils'

---@class CoordsInteraction: Interaction
---@field coords vector3 Interaction coordinates.\
---@field currentDistance number
---@field point CPoint
local CoordsInteraction = lib.class('CoordsInteraction', Interaction)

function CoordsInteraction:constructor(data)
    self:super(data)
    self.coords = data.coords
    self:createStaticPoint()
end

function CoordsInteraction:update(data)
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

    self.point:remove()

    self.coords = data.coords
    self:createStaticPoint()
end

function CoordsInteraction:createStaticPoint()
    local instance = self
    instance.point = lib.points.new({
        coords = instance.coords,
        distance = instance.renderDistance,
    })

    function instance.point:onExit()
        instance.currentDistance = 999
    end

    function instance.point:nearby()
        instance.currentDistance = self.currentDistance
    end
end

function CoordsInteraction:shouldRender()
    if self.shouldDestroy then return false end
    
    return self.currentDistance <= self.renderDistance
end

function CoordsInteraction:shouldBeActive()
    return self?.currentDistance and self.currentDistance <= self.activeDistance
end

function CoordsInteraction:getCoords()
    return self.coords
end

function CoordsInteraction:getDistance()
    return #(self.coords - cache.coords or GetEntityCoords(cache.ped))
end

return CoordsInteraction
