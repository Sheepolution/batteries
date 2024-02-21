--[[
	list - sequence with simpler foreach calls
]]

local path = (...):gsub("sequence", "")
local table = require(path .. "tablex") --shadow global table module
local sequence = require(path .. "sequence")

local list = {}
for k, v in pairs(sequence) do
    list[k] = v
end
list.__index = list
list.__call = function(self, f)
    return list.foreach(self, f)
end


setmetatable(list, {
    __index = function(self, n)
        if tonumber(n) then
            return rawget(self, n)
        end

        local f = table[n]
        if f then
            return f
        end

        if n:find("__") then
            return nil
        end

        self[n] = function(s, ...)
            for i = 1, #s do
                if s[i][n] then
                    s[i][n](s[i], ...)
                else
                    if rawget(self, "__strict") then
                        error("Method " .. n .. " not found in object " .. i)
                    end
                end
            end
        end

        return self[n]
    end,
    __call = function(self, ...)
        return list:new(...)
    end,
})

--upgrade a table into a list, or create a new list
function list:new(t, config)
    if t and not t[1] then
        t, config = nil, t
    end

    t = t or {}

    if config then
        t.__strict = config.strict
        t.__set = config.set
    end

    return setmetatable(t, list)
end

function list:add(...)
    local t = { ... }

    if rawget(self, "__set") then
        for _, v in ipairs(t) do
            table.add_value(self, v)
        end
        return t[1]
    end

    table.append_inplace(self, t)

    return t[1]
end

return list
