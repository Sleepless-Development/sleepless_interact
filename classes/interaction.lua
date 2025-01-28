---@diagnostic disable: undefined-field
local config           = require 'imports.config'
local utils            = require 'imports.utils'
local defaultIndicator = config.defaultIndicatorSprite
local color            = config.color
local store            = require 'imports.store'
local dui              = require 'imports.dui'

---@class Interaction: OxClass
local Interaction      = lib.class('Interaction')

---@param data Interaction
function Interaction:constructor(data)
    if store.InteractionIds[data.id] then
        lib.print.warn(string.format("interaction id '%s' already exists. updating existing data", data.id))
        store.InteractionIds[data.id]:update(data)
        return
    end

    self.id = data.id
    store.InteractionIds[self.id] = self

    self.resource = data.resource
    self.globalType = data.globalType
    self.renderDistance = data.renderDistance
    self.activeDistance = data.activeDistance
    self.currentDistance = 1 / 0
    self.options = data.options
    self.removeWhenDead = data.removeWhenDead
    self.isDestroyed = false
    self.DuiOptions = {}
    self.sprite = data.sprite
    self.allowInVehicle = data.allowInVehicle

    if data?.sprite?.dict then
        pcall(lib.requestStreamedTextureDict, data.sprite.dict)
    end

    self.private = {
        lastActionTime = 0,
        cooldown = data.cooldown
    }

    for i = 1, #self.options do
        self.DuiOptions[i] = { text = self.options[i].label or self.options[i].text, icon = self.options[i].icon }
    end

    self.onStop = AddEventHandler('onResourceStop', function(resourceName)
        if data.resource == resourceName then
            interact.removeById(self.id)
        end
    end)
end

function Interaction:isOnCooldown(time)
    return time - self.private.lastActionTime < self.private.cooldown
end

function Interaction:handleInteract()
    local time = GetGameTimer()
    if self:isOnCooldown(time) then return end
    self.private.lastActionTime = time

    if self.netId then
        self.entity = self:getEntity()
    end

    self.coords = self:getCoords()

    local option = self.options[store.currentOptionIndex]

    if option.action then
        option.action(self)
    elseif option.onSelect then -- ox_target compatibility
        option.onSelect(self)
    elseif option.export then
        exports[option.resource][option.export](self)
    elseif option.event then
        TriggerEvent(option.event, self)
    elseif option.serverEvent then
        TriggerServerEvent(option.serverEvent, self)
    elseif option.command then
        ExecuteCommand(option.command)
    end

    if option.remove then
        interact.removeById(self.id)
    end
end

local ratio = GetAspectRatio(true)
function Interaction:drawSprite()
    if self.isDestroyed then return end
    local coords = self:getCoords()
    SetDrawOrigin(coords.x, coords.y, coords.z)
    if self.isActive and not self:isOnCooldown(GetGameTimer()) then
        if not store.menuBusy then
            DrawInteractiveSprite(dui.txdName, dui.txtName, 0, 0, 1, 1, 0.0, 255, 255, 255, 255)
        end
    else
        local distanceRatio = self:getDistance() / self.renderDistance
        distanceRatio = 0.5 + (0.25 * distanceRatio)
        local scale = 0.025 * (distanceRatio)
        local dict = defaultIndicator.dict
        local txt = defaultIndicator.txt
        local spriteColour = color

        if self?.sprite?.dict and self?.sprite?.txt then
            dict = self.sprite.dict --[[@as string]]
            txt = self.sprite.txt --[[@as string]]
        end

        if self?.sprite?.color and type(self.sprite.color) == 'vector4' then
            spriteColour = self.sprite.color --[[@as vector4]]
        end

        DrawInteractiveSprite(dict, txt, 0, 0, scale, scale * ratio, 0.0, spriteColour.x, spriteColour.y, spriteColour.z,
            spriteColour.w)
    end
    ClearDrawOrigin()
end

function Interaction:destroy()
    self.isDestroyed = true

    if self.point then
        self.point:remove()
    end

    if self.globalType and (self.netId or self.entity) then
        utils.wipeCacheForEntityKey(self.globalType, self.netId or self.entity, self.id)
    end

    if self?.sprite?.dict then
        SetStreamedTextureDictAsNoLongerNeeded(self.sprite.dict)
    end

    RemoveEventHandler(self.onStop)
    store.InteractionIds[self.id] = nil
end

function Interaction:vehicleCheck()
    return not cache.vehicle or (self.allowInVehicle and cache.vehicle)
end

function Interaction:getCoords() --abstract method
    error("Abstract method getCoords not implemented")
end

function Interaction:getDistance() --abstract method
    error("Abstract method getDistance not implemented")
end

function Interaction:shouldRender() --abstract method
    error("Abstract method shouldRender not implemented")
end

function Interaction:shouldBeActive() --abstract method
    error("Abstract method shouldBeActive not implemented")
end

return Interaction
