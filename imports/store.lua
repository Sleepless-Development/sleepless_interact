local store = {}

store.ox_lib = GetResourceState('ox_lib'):find('start')
store.ox_inv = GetResourceState('ox_inventory'):find('start')

---@type Interaction | nil
store.activeInteraction = nil
store.currentOptionIndex = 1
store.menuBusy = false

store.Interactions = {}
store.InteractionIds = {}

store.globalIds = {}
store.globalVehicle = {}
store.globalPlayer = {}
store.globalPed = {}
store.globalModels = {}

store.cachedVehicles = {}
store.cachedPlayers = {}
store.cachedPeds = {}
store.cachedObjects = {}

store.nearby = {}

return store