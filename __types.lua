---made repeat types for exports because the required fields that were inherited didnt show as required in other files.

---@class InteractOptions 
---@field text string
---@field icon string
---@field destroy boolean
---@field action fun(data: CoordsInteraction | LocalEntityInteraction | EntityInteraction)
---@field canInteract fun(data: {entity?: number, distance: number, coords: vector3, id: string | number}): boolean

---@class CoordsData
---@field id string | number unique identifier for the interaction
---@field coords vector3 | vector3[]
---@field options InteractOptions
---@field renderDistance? number distance that the interaction indicator is visible from (default: 5.0)
---@field activeDistance? number distance that the interaction menu is visible from (default: 1.0)
---@field cooldown? number time 'in' ms between interactions. prevent players from spamming E (default: 1000)

---@class LocalEntityData
---@field id string | number unique identifier for the interaction
---@field entity number entity handle
---@field offset? vector3
---@field bone? string | table<string> name of bone for entity
---@field options InteractOptions
---@field renderDistance? number distance that the interaction indicator is visible from (default: 5.0)
---@field activeDistance? number distance that the interaction menu is visible from (default: 1.0)
---@field cooldown? number time 'in' ms between interactions. prevent players from spamming E (default: 1000)

---@class EntityData
---@field id string | number unique identifier for the interaction
---@field netId number network id for the networked entity
---@field offset? vector3
---@field bone? string | table<string> name of bone for entity
---@field options InteractOptions
---@field renderDistance? number distance that the interaction indicator is visible from (default: 5.0)
---@field activeDistance? number distance that the interaction menu is visible from (default: 1.0)
---@field cooldown? number time 'in' ms between interactions. prevent players from spamming E (default: 1000)

---@class ModelData
---@field id string | number unique identifier for the interaction
---@field models table<{model: string | number, offset?: vector3, bone?: string}>
---@field InteractOptions
---@field renderDistance? number distance that the interaction indicator is visible from (default: 5.0)
---@field activeDistance? number distance that the interaction menu is visible from (default: 1.0)
---@field cooldown? number time 'in' ms between interactions. prevent players from spamming E (default: 1000)

---@class PedInteractionData
---@field id string | number unique identifier for the interaction
---@field options InteractOptions
---@field offset? vector3
---@field bone? string | table<string> name of bone for entity
---@field renderDistance? number distance that the interaction indicator is visible from (default: 5.0)
---@field activeDistance? number distance that the interaction menu is visible from (default: 1.0)
---@field cooldown? number time 'in' ms between interactions. prevent players from spamming E (default: 1000)

---@class VehicleInteractionData
---@field id string | number unique identifier for the interaction
---@field options {text: string, icon: string, destroy?: boolean, action: fun(data: EntityInteraction), canInteract: fun(entity?: number, distance: number, coords: vector3, id: string | number): boolean}[] list of options and actions for the interaction
---@field offset? vector3
---@field bone? string | table<string> name of bone for entity
---@field renderDistance? number distance that the interaction indicator is visible from (default: 5.0)
---@field activeDistance? number distance that the interaction menu is visible from (default: 1.0)
---@field cooldown? number time 'in' ms between interactions. prevent players from spamming E (default: 1000)