if not lib.checkDependency('qbx_core', '1.18.0', true) then return end

require '@qbx_core/modules/playerdata.lua'
local qbx = exports.qbx_core
local utils = require 'client.modules.utils'

---@diagnostic disable-next-line: duplicate-set-field
function utils.hasPlayerGotGroup(filter)
    return qbx:HasPrimaryGroup(filter) and QBX.PlayerData.job.onduty
end
