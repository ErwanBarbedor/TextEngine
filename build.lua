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

-- Merge all code into a single file.
-- Quite dirty, but do the job

local version = "Plume - TextEngine 0.1.0 (dev)"
local code = io.open("txe.lua"):read "*a"


code = code:gsub('(txe = {}[\r\n]+)', 'local %1')

for i=1, 2 do
    code = code:gsub('require "(.-)"', function (m)
        return "\n-- ## " .. m .. ".lua ##\n" .. io.open(m..".lua"):read "*a":gsub('%-%-%[%[.-%]%][\r\n]+', '', 1)
    end)
end

code = code:gsub('\n%-%- <DEV>.-%-%- </DEV>\n', '')
code = code:gsub('#VERSION#', version)
code = code:gsub('#GITHUB#', 'https://github.com/ErwanBarbedor/Plume_-_TextEngine')

io.open('dist/txe.lua', 'w'):write(code)

print("Building " .. version .. " done." )