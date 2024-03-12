---@diagnostic disable: undefined-field
local dui = require 'imports.dui'
local globals = require 'imports.globals'
local config = require 'imports.config'
local utils = require 'imports.utils'
local txdName, txtName in dui
local color, indicatorSprite in config
local interactionIds = {}

---@todo: FUTURE: may need to merge options for entities based on bones.

--[[
    if not entityBoneOptions[bone] then
        entityBoneOptions[bone] = {}
    end

    > merge new options with old options INSTEAD of creating a new interaction
    which distances to use? highest?
    which id?
    maybe even only merge them in the ui? keep both instances of it in lua?
]]

---@class Interaction
---@field id string Unique identifier.
---@field options {text: string, action: fun(data: Interaction), canInteract: fun(data: Interaction)} table of options for the UI.
---@field groups? table<string, number> list of jobs and grades allowed to interact
---@field currentOption? number currently selected option
---@field renderDistance? number Optional render distance. (default: 5.0)
---@field activeDistance? number Optional activation distance. (default: 1.0)
---@field currentDistance number current distance from player
---@field isActive boolean is this interaction active?
---@field cooldown? number time 'in' ms between actions. prevent spam (default: 1000)
---@field lastActionTime number
---@field action fun(data: self) allows for just a button action with no options
---@field handleInteract fun(data: self) handles action when e is pressed for current option
---@field getCoords fun(data: self): vector3 abstract method for getting coords for the interaction
---@field getDistance fun(data: self): vector3 abstract method for getting distance from the interaction
---@field shouldRender fun(data: self): number abstract method for getting if the interaction should render
---@field shouldBeActive fun(data: self): number abstract method for getting if the interaction should be active
local Interaction = lib.class('Interaction')

function Interaction:super()
    lib.requestStreamedTextureDict(txdName)
    lib.requestStreamedTextureDict(indicatorSprite.dict)
    if interactionIds[self.id] then
        lib.print.warn(string.format('duplicate interaction id added: %s', self.id))
        interactionIds[self.id]:destroy()
        Wait(100)
    end
    RegisterNetEvent('onResourceStop', function(resourceName)
        if self.resource == resourceName then
            self:destroy()
        end
    end)
    self.currentDistance = 999
    self.currentOption = 1
    self.textOptions = {}
    self.lastActionTime = 0
    if self.action then
        self.options = {}
    else
        for i = 1, #self.options do
            self.textOptions[i] = { text = self.options[i].text, icon = self.options[i].icon }
        end
    end
    interactionIds[self.id] = self
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

function Interaction:destroy()
    self.shouldDestroy = true

    local netId, entity in self
    local serverid = entity and IsPedAPlayer(entity) and GetPlayerServerId(NetworkGetPlayerIndex(entity))
    local key = serverid or netId or entity
    
    if key then
        globals.cachedModelEntities[key] = nil
        globals.cachedPlayers[key] = nil
        globals.cachedVehicles[key] = nil
        globals.cachedPeds[key] = nil
    end
    interactionIds[self.id] = nil
end

function Interaction:setCurrentTextOption(index)
    self.currentOption = index
end

function Interaction:isOnCooldown(time)
    return time - self.lastActionTime < self.cooldown
end

function Interaction:handleInteract()
    local time = GetGameTimer()
    if self:isOnCooldown(time) then return end
    self.lastActionTime = time

    if self.netId then
        self.entity = self:getEntity()
    end

    local option = self.options[self.currentOption]
    local response = utils.getActionData(self)

    if option.action then
        option.action(response)
    elseif option.onSelect then -- ox_target compatibility
        option.onSelect(response)
    elseif option.export then
        exports[option.resource][option.export](response)
    elseif option.event then
        TriggerEvent(option.event, response)
    elseif option.serverEvent then
        TriggerServerEvent(option.serverEvent, response)
    elseif option.command then
        ExecuteCommand(option.command)
    end

    if option.destroy then
        self:destroy()
    end
end

local ratio = GetAspectRatio(true)
function Interaction:drawSprite()
    if self.shouldDestroy then return end
    local coords = self:getCoords()
    SetDrawOrigin(coords.x, coords.y, coords.z)
    if self.isActive and not self:isOnCooldown(GetGameTimer()) then
        local scale = 1
        DrawInteractiveSprite(txdName, txtName, 0, 0, scale, scale, 0.0, 255, 255, 255, 255)
    else
        local distanceRatio = self:getDistance() / self.renderDistance
        distanceRatio = 0.5 + (0.25 * distanceRatio)
        local scale = 0.025 * (distanceRatio)
        local x,y,z,w in color
        local dict, txt in indicatorSprite
        DrawInteractiveSprite(dict, txt, 0, 0, scale, scale * ratio, 0.0, x, y, z, w)
    end
    ClearDrawOrigin()
end

return Interaction
