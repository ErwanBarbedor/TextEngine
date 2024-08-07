--[[This file is part of Plume - TextEngine.

Plume - TextEngine is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

Plume - TextEngine is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plume - TextEngine. If not, see <https://www.gnu.org/licenses/>.
]]

-- Manage methods that are visible from user (not much for now)
local api = {}

--- Define a variable locally
-- @param key string
-- @param value string
function api.set_local (key, value)
    txe.scope_set_local (key, value)
end

--- Alias for api.set_local
-- @see api.set_local
api.setl = api.set_local

--- Initializes the API methods visible to the user.
function txe.init_api ()
    local scope = txe.current_scope ()
    scope.txe = {}

    -- keep a reference
    txe.running_api = scope.txe

    for k, v in pairs(api) do
        scope.txe[k] = v
    end

    scope.txe.config = {}
    for k, v in pairs(txe.config) do
        scope.txe.config[k] = v
    end
end