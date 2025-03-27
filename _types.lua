--- Represents an interaction option with various properties.
---@class InteractOption
---@field label string The display label for the option.
---@field icon? string The icon associated with the option.
---@field iconColor? string The css color for the icon
---@field distance? number The maximum distance at which the option is available.
---@field holdTime? number Makes the option a press and hold and sets how long it should be held for. (miliseconds)
---@field canInteract? fun(entity: number, distance: number, coords: vector3, name: string): boolean? A function to determine if the option can be interacted with.
---@field name? string A unique identifier for the option.
---@field resource? string The resource that registered the option.
---@field offset? vector3 A relative offset from the entity's position.
---@field offsetAbsolute? vector3 An absolute offset in world coordinates.
---@field color? number[] 4 numbers in an array that will be used for rgba and will overwrite the theme color for that option.
---@field bones? string | string[] An array of bone IDs associated with the option.
---@field allowInVehicle? boolean marks the option as being able to be used inside a vehicle.
---@field onSelect? fun(data: InteractResponse) A function to execute when the option is selected.
---@field cooldown? number number of miliseconds the interact system should cooldown for after this option is selected. prevents spam.
---@field export? string Optional export function name
---@field event? string Client-side event to trigger
---@field serverEvent? string Server-side event to trigger
---@field command? string Command to execute
---@field onActive? fun(data: InteractResponse) A function to execute when the option is active.
---@field onInactive? fun(data: InteractResponse) A function to execute when the option was active and is now inactive.
---@field whileActive? fun(data: InteractResponse) A function to execute while the option is active on a loop.

---@class NearbyItem
---@field options InteractOption[]
---@field currentDistance number
---@field entity? number
---@field bone? string
---@field coords vector3
---@field offset? string
---@field coordId? string

-- Represents the response structure sent to onSelect and other callable methods.
---@class InteractResponse
---@field entity? number Entity ID or 0 if not applicable.
---@field coordsId? string ID of the coordinate zone, if applicable.
---@field coords vector3 Coordinates of the interaction point.
---@field distance number Distance from the player to the interaction point.
---@field label string Label of the option.
---@field name? string Name of the option, if provided.
---@field resource string Resource that registered the option.
---@field offset? vector3 Offset from the entity's position, if applicable.
---@field offsetAbsolute? vector3 Absolute offset in world coordinates, if applicable.
---@field bones? string|string[] Bones associated with the option, if applicable.

-- Represents the current interaction state in the store.
---@class CurrentInteraction
---@field entity? number Entity ID
---@field coordsId? string ID of the coordinate, if applicable.
---@field coords? vector3 Coordinates of the interaction point.
---@field distance number Distance from the player to the interaction point.
---@field options table<string, InteractOption[]> Options grouped by category (e.g., "global", "model")

--- A table mapping string keys (e.g., bone IDs or offset IDs) to arrays of options.
---@class OptionsMap
---@field [string] InteractOption[]

--- A table mapping model hashes (numbers) to arrays of options.
---@class ModelOptions
---@field [number] InteractOption[]

--- A table mapping network IDs (numbers) to arrays of options.
---@class EntityOptions
---@field [number] InteractOption[]

--- A table mapping local entity IDs (numbers) to arrays of options.
---@class LocalEntityOptions
---@field [number] InteractOption[]nsArray

--- A table mapping coordinate IDs (strings) to arrays of options.
---@class CoordOptions
---@field [string] InteractOption[]

--- A table mapping coordinate IDs (strings) to their vector3 positions.
---@class CoordIds
---@field [string] vector3

--- A structure for storing bone-specific options across different categories.
---@class BonesStore
---@field peds OptionsMap Bone options for peds.
---@field vehicles OptionsMap Bone options for vehicles.
---@field objects OptionsMap Bone options for objects.
---@field players OptionsMap Bone options for players.
---@field models table<number, OptionsMap> Bone options for models, keyed by model hash.
---@field entities table<number, OptionsMap> Bone options for networked entities, keyed by netId.
---@field localEntities table<number, OptionsMap> Bone options for local entities, keyed by entityId.

--- A structure for storing offset-specific options across different categories.
---@class OffsetsStore
---@field peds OptionsMap Offset options for peds.
---@field vehicles OptionsMap Offset options for vehicles.
---@field objects OptionsMap Offset options for objects.
---@field players OptionsMap Offset options for players.
---@field models table<number, OptionsMap> Offset options for models, keyed by model hash.
---@field entities table<number, OptionsMap> Offset options for networked entities, keyed by netId.
---@field localEntities table<number, OptionsMap> Offset options for local entities, keyed by entityId.

--- The main store module structure for organizing interaction options.
---@class Store
---@field peds InteractOption[] Options for all peds globally.
---@field vehicles InteractOption[] Options for all vehicles globally.
---@field objects InteractOption[] Options for all objects globally.
---@field players InteractOption[] Options for all players globally.
---@field models ModelOptions Options for specific models, keyed by model hash.
---@field entities EntityOptions Options for networked entities, keyed by netId.
---@field localEntities LocalEntityOptions Options for local entities, keyed by entityId.
---@field coords CoordOptions Options for specific coordinates, keyed by coordId.
---@field coordIds CoordIds Coordinate positions, keyed by coordId.
---@field bones BonesStore Bone-specific options for various categories.
---@field offsets OffsetsStore Offset-specific options for various categories.
