local Interaction = require 'classes.interaction'
local utils = require 'imports.utils'

---@class CoordsInteraction: Interaction
local CoordsInteraction = lib.class('CoordsInteraction', Interaction)

function CoordsInteraction:constructor(data)
    self:super(data)
    if not self.id then return end
    self.coords = data.coords
    self:createInteractPoint()
end

function CoordsInteraction:update(data)
    utils.loadInteractionDefaults(data, self.resource)

    self.renderDistance = data.renderDistance
    self.activeDistance = data.activeDistance
    self.options = data.options
    self.DuiOptions = {}

    self.private.cooldown = data.cooldown

    for i = 1, #self.options do
        self.DuiOptions[i] = { text = self.options[i].label or self.options[i].text, icon = self.options[i].icon }
    end

    self.point:remove()
    self.coords = data.coords
    self:createInteractPoint()
end

function CoordsInteraction:createInteractPoint()
    local coordInteraction = self
    local point = lib.points.new({
        coords = coordInteraction.coords,
        distance = coordInteraction.renderDistance,
    })

    if coordInteraction.onEnter then
        function point:onEnter()
            coordInteraction.onEnter(self)
        end
    end

    function point:onExit()
        coordInteraction.currentDistance = 1 / 0

        if coordInteraction.onExit then
            coordInteraction.onExit(self)
        end
    end

    function point:nearby()
        coordInteraction.currentDistance = self.currentDistance
        if coordInteraction.nearby then
            coordInteraction.nearby(self)
        end
    end
    self.point = point
end

function CoordsInteraction:shouldRender()
    return self.currentDistance <= self.renderDistance
end

function CoordsInteraction:shouldBeActive()
    return self.currentDistance <= self.activeDistance
end

function CoordsInteraction:getCoords()
    return self.coords
end

function CoordsInteraction:getDistance()
    return self.currentDistance
end

return CoordsInteraction
