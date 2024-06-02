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
