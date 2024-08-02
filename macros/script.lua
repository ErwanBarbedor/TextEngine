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

-- Define script-related macro

txe.register_macro("script", {"body"}, {}, function(args)
    --Execute a lua chunk and return the result, if any
    local result = txe.call_lua_chunk(args.body)

    --if result is a token, render it
    if type(result) == "table" and result.render then
        result = result:render ()
    end
    
    return result
end)

txe.register_macro("eval", {"expr"}, {}, function(args)
    --Eval lua expression and return the result
    -- \eval{1+1} or #{1+1}
    -- Can format the result : #{1/3}[.2f]
    -- (use lua format without leading '%')

    -- Get format if provided
    local format
    if args.__args[1] then
        format = args.__args[1]:render ()
    end

    local result = txe.eval_lua_expression(args.expr)

    --if result is a token, render it
    if type(result) == "table" and result.render then
        result = result:render ()
    end
    
    if format then
        result = string.format("%"..format, result)
    end

    return result
end)