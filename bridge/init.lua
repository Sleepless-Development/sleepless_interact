local function hasFramework(framework)
    return GetResourceState(framework) ~= 'missing'
end

local framework = hasFramework('ox_core') and 'ox' or hasFramework('qb-core') and 'qb' or
hasFramework('qbx_core') and 'qb' or hasFramework('es_extended') and 'esx' or nil

if not framework then
    return print('No framework detected')
end

local resource = ('bridge.%s.client'):format(framework)

require(resource)
