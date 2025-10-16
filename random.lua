--[[
	functions that use randomness
]]

local random = {}

local _rng

function random.set_rng(rng)
    _rng = rng
end

--(internal; use a provided random generator object, or not)
local function _random(rng, ...)
    if rng then return rng:random(...) end
    if _rng then return _rng:random(...) end
    if love then return love.math.random(...) end
    return math.random(...)
end

setmetatable(random, {
    __call = function(self, a, b, int)
        if not b then
            if a == true then
                -- random boolean
                return _random() < 0.5
            end

            if type(a) == "table" then
                -- random table element
                return a[_random(nil, 1, #a)]
            end
        end

        if b == true or int == true then
            if b == true then
                b = a
                a = 1
            end
            -- random integer
            return _random(nil, a, b)
        end

        if a then
            if not b then
                -- random float
                return _random() * a
            end

            -- random float
            return a + _random() * (b - a)
        end

        return _random()
    end
})

function random.int(a, b, rng)
    return _random(rng, a, b)
end

function random.float(a, b, rng)
    if not a then a, b = 0, 1 end
    if not b then b = 0 end
    return a + _random(rng) * (b - a)
end

--return a random sign
function random.sign(v, rng)
    return (_random(rng) < 0.5 and -1 or 1) * (v or 1)
end

--return a random value between two numbers (continuous)
function random.lerp(min, max, rng)
    return random.lerp(min, max, _random(rng))
end

function random.bool(rng)
    return _random(rng) < 0.5
end

function random.string(length, rng)
    local t = {}
    for i = 1, length do
        t[i] = string.char(_random(rng, 32, 126))
    end
    return table.concat(t)
end

function random.table(t, rng)
    return t[_random(rng, 1, #t)]
end

function random.index(t, rng)
    return _random(rng, 1, #t)
end

function random.angle()
    return -math.pi + _random() * math.pi * 2
end

--return a function that returns a random integer between two integers (inclusive)
--but never the same value twice in a row
function random.unique(a, b, rng)
    local last = nil
    return function()
        if a == b then return a end
        local v
        repeat
            v = _random(rng, a, b)
        until v ~= last
        last = v
        return v
    end
end

-- return a value based on a table of weights
function random.weighted(w, rng)
    local iter = w[1] and ipairs or pairs
    local sum = 0
    for _, v in iter(w) do
        assert(v >= 0, "weight value less than zero")
        sum = sum + v
    end
    assert(sum ~= 0, "all weights are zero")
    local rnd = random(sum)
    local last_key
    for k, v in iter(w) do
        last_key = k
        if rnd < v then return k end
        rnd = rnd - v
    end
    return last_key
end

--return a function that returns a random integer between two integers (inclusive)
--but decreasing the chance of the same value reappearing
function random.weighted_auto(a, b, decr, rng)
    local weights = {}
    local last = nil
    decr = decr or 0.5
    local min_weight = 0.01

    for i = a, b do
        weights[i] = 1
    end

    return function()
        if a == b then return a end

        local total = 0
        for i = a, b do
            total = total + weights[i]
        end

        if last then
            local decrease_amount = math.max(weights[last] * decr, min_weight)
            weights[last] = math.max(weights[last] - decrease_amount, min_weight)

            local distribute_amount = decrease_amount / (b - a)
            for i = a, b do
                if i ~= last then
                    weights[i] = weights[i] + distribute_amount
                end
            end
        end

        total = 0
        for i = a, b do
            total = total + weights[i]
        end

        local rand = _random(rng, total)
        local sum = 0
        local value = a -- In case of errors, use this

        for i = a, b do
            sum = sum + weights[i]
            if rand <= sum then
                value = i
                break
            end
        end

        last = value
        return value
    end
end

--return a function that returns a random integer between two integers (inclusive)
--but decreasing the chance of the same value reappearing
--and never the same value twice in a row
function random.unique_weighted(a, b, decr, rng)
    local f = random.weighted_auto(a, b, decr, rng)
    local last = nil
    return function()
        if a == b then return a end
        local v
        repeat
            v = f()
        until v ~= last
        last = v
        return v
    end
end

function random.chance(c, rng)
    return _.random(rng) * 100 < c
end

function random.chance_auto(decr, rng)
    local f = random.weighted_auto(0, 1, decr, rng)
    return function()
        return f() == 0
    end
end

return random
