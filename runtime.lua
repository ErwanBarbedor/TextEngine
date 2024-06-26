--[[This file is part of TextEngine.

TextEngine is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

TextEngine is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with TextEngine. If not, see <https://www.gnu.org/licenses/>.
]]

txe.lua_cache      = {}
txe.chunck_count = 0

-- Define 'load' function for Lua 5.1 compatibility
if _VERSION == "Lua 5.1" or jit then
    function txe.load_lua_chunck (code, _, _, env)
        local f, err = loadstring(code)
        if f then
            setfenv(f, env)
        end
        return f, err
    end
else
    txe.load_lua_chunck = load
end

function txe.eval_lua_expression (token, code)
    code = code or token:source ()
    code = 'return ' .. code

    return txe.call_lua_chunck (token, code)
end

function txe.call_lua_chunck(token, code)
    -- Load, cache and execute code
    -- find in the given token or string
    -- If the string is given, token is use only
    -- to throw error

    code = code or token:source ()

    if not txe.lua_cache[code] then
        --put chunck ref in the code, to retrieve it
        --in case of error
        txe.chunck_count = txe.chunck_count + 1
        code = "--token" .. txe.chunck_count .. "\n" .. code
        
        local loaded_func, load_err
        loaded_func, load_err = txe.load_lua_chunck(code, nil, "bt", txe.lua_env)

        if not loaded_func then
            load_err = load_err:gsub('^.-%]:[0-9]+:', '')
            txe.error(token, "(Lua syntax error)" .. load_err)
        end
        
        txe.lua_cache[code] = setmetatable({
            token=token,
            chunck_count=chunck_count
            
        },{
            __call = function ()
                return loaded_func()
            end
        })
    end

    local result = { pcall(txe.lua_cache[code]) }
    local sucess = result[1]
    table.remove(result, 1)
    if not sucess then
        err = result[1]:gsub('^.-%]:[0-9]+:', '')
        txe.error(token, "(Lua error)" .. err)
    end
    -- print(code, ">", sucess, ">", result)
    return (table.unpack or unpack)(result)
end

local env = {{}}
txe.lua_env = setmetatable({}, {
    __newindex = function (self, key, value)
        for i=#env, 1, -1 do
            if env[i][key] or i==1 then
                env[i][key] = value
            end
        end
    end,
    __index = function (self, key)
        for i=#env, 1, -1 do
            local value = env[i][key]
            if value or i==1 then
                return value
            end
        end
    end
})

function txe.push_env ()
    table.insert(env, {})
end
function txe.pop_env ()
    table.remove(env)
end
function txe.lua_env_set_local (key, value)
    env[#env][key] = value
end
function txe.purge_env ()
    env = {{}}
end

-- Save all lua standard functions to be available from "eval" macros
local lua_std_functions
if _VERSION == "Lua 5.1" then
    if jit then
        lua_std_functions = "math package arg module require assert string table type next pairs ipairs getmetatable setmetatable getfenv setfenv rawget rawset rawequal unpack select tonumber tostring error pcall xpcall loadfile load loadstring dofile gcinfo collectgarbage newproxy print _VERSION coroutine jit bit debug os io"
    else
        lua_std_functions = "string xpcall package tostring print os unpack require getfenv setmetatable next assert tonumber io rawequal collectgarbage arg getmetatable module rawset math debug pcall table newproxy type coroutineselect gcinfo pairs rawget loadstring ipairs _VERSION dofile setfenv load error loadfile"
    end
else -- Assume version is 5.4
    lua_std_functions = "load require error os warn ipairs collectgarbage package rawlen utf8 coroutine xpcall math select loadfile next rawget dofile table tostring _VERSION tonumber io pcall print setmetatable string debug arg assert pairs rawequal getmetatable type rawset"
end

txe.lua_std = {}
for name in lua_std_functions:gmatch('%S+') do
    txe.lua_std[name] = _G[name]
end

function txe.init_lua ()
    for k, v in pairs(txe.lua_std) do
        txe.lua_env[k] = v
    end

    -- Add a self-reference
    txe.lua_env._G = txe.lua_env
end
txe.init_lua ()

function txe.reset ()
    -- Remove all session specific data
    txe.purge_env ()
    txe.macros = {}
    for k, v in pairs(txe.std_macros) do
        txe.macros[k] = v
    end
    txe.init_lua ()

    txe.last_error = nil
    txe.traceback = {}
end