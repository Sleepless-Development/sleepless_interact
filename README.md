To create a comprehensive README for your `interact` library functions within your FiveM resource, we'll break down the documentation into sections for each function, providing descriptions, parameters, return values, and examples where applicable. This approach will make it easy for other developers to understand and integrate your resource into their projects.

---

# Interact Library Documentation

The `interact` library offers a suite of functions to facilitate interactions with static coordinates, local and networked entities, models, and more within the FiveM environment. This documentation covers the setup and usage of various `interact` functions.

## Functions Overview

- `addCoords(data)`
- `addLocalEntity(data)`
- `addLocalEntityBone(data)`
- `addEntity(data)`
- `addEntityBone(data)`
- `addGlobalModel(data)`
- `addGlobalPlayer(data)`
- `addGlobalPed(data)`
- `addGlobalVehicle(data)`
- `removeEntity(netId)`
- `removeId(id)`
- `removeModel(model)`

## Function Descriptions

### `addCoords(data)`

Adds an interaction at specific static coordinates.

**Parameters:**

- `data` (CoordsData): A table containing `id`, `coords`, and `options`.

**Returns:**

- `id` (number | string): The identifier for the added interaction.

### `addLocalEntity(data)`

Adds an interaction for a local non-networked entity.

**Parameters:**

- `data` (LocalEntityData): A table containing `id`, `entity`, and `options`.

**Returns:**

- `id` (number | string): The identifier for the added interaction.

### `addLocalEntityBone(data)`

Adds an interaction for a specific bone of a local non-networked entity.

**Parameters:**

- `data` (LocalEntityBoneData): A table containing `id`, `entity`, `bone`, and `options`.

**Returns:**

- `id` (number | string): The identifier for the added interaction.

### `addEntity(data)`

Adds an interaction for a networked entity.

**Parameters:**

- `data` (EntityData): A table containing `id`, `netId`, and `options`.

**Returns:**

- `id` (number | string): The identifier for the added interaction.

### `addEntityBone(data)`

Adds an interaction for a specific bone of a networked entity.

**Parameters:**

- `data` (EntityBoneData): A table containing `id`, `netId`, `bone`, and `options`.

**Returns:**

- `id` (number | string): The identifier for the added interaction.

### `addGlobalModel(data)`

Adds global interactions for one or more models.

**Parameters:**

- `data` (ModelData): A table containing model details and interaction options.

### `addGlobalPlayer(data)`

Adds a global interaction for players.

**Parameters:**

- `data` (PedInteractionData): A table containing interaction options for players.

### `addGlobalPed(data)`

Adds a global interaction for peds.

**Parameters:**

- `data` (PedInteractionData): A table containing interaction options for peds.

### `addGlobalVehicle(data)`

Adds a global interaction for networked vehicles.

**Parameters:**

- `data` (VehicleInteractionData): A table containing interaction options for vehicles.

### `removeEntity(netId)`

Removes an interaction for a networked entity.

**Parameters:**

- `netId` (number): The network ID of the entity.

### `removeId(id)`

Removes an interaction by its identifier.

**Parameters:**

- `id` (number | string): The identifier of the interaction.

### `removeModel(model)`

Removes global interactions for a model or models.

**Parameters:**

- `model` (number | string | table): The model or models to remove interactions for.

## Example Usage

```lua
-- Adding a static coordinate interaction
interact.addCoords({
    id = "uniqueID1",
    coords = vector3(123.4, 567.8, 250.0),
    options = {
        eventName = "example:eventName",
        radius = 5,
        debugPoly = true
    }
})
```

This README format provides a clear and structured way to document your `interact` library functions. You can expand each section with more details or examples as needed to ensure users fully understand how to use your resource.