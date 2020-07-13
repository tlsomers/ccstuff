--
-- Created by IntelliJ IDEA.
-- User: tlsomers
-- Date: 7/13/20
-- Time: 1:52 PM
-- To change this template use File | Settings | File Templates.
--

local Types = require("types")
local json = require("json")

Error = Types.new {
    name = "Error",
    data = {isSuccess = false, isError = true},
    constructor = function(mt, err) return setmetatable({err = err}, mt) end,
    toString = function(err) return "Error(" .. tostring(err.err) .. ")" end
}

Success = Types.new {
    name = "Success",
    data = {isSuccess = true, isError = false},
    constructor = function(mt, val) return setmetatable({val = val}, mt) end,
    toString = function(succ) return "Success(" .. tostring(succ.val) .. ")" end
}

function Success.mti:map(func) return Success(func(self.val)) end
function Success.mti:flatMap(func) return func(self.val) end
Success.mti.bind = Success.mti.flatMap

function Error.mti:map(func) return self end
function Error.mti:flatMap(func) return self end
Error.mti.bind = Error.mti.flatMap





Parser = Types.new {name = "Parser", constructor = function(mt, func) return setmetatable({func = func}, mt) end}

Tuple = Types.new {
    name = "Tuple",
    constructor = function(mt, a, b) return setmetatable({a,b}, mt) end,
    getType = function(tup) return "Tuple["..type(tup[1])..","..type(tup[2]).."]" end,
    toString = function(tup) return "(" .. tostring(tup[1]) .. "," .. tostring(tup[2]) .. ")" end
}

function Parser.mti:run(str)
    return self.func(str)
end

function Parser.pure(val)
    return Parser(function(str) return Success(Tuple(val, str)) end)
end

function Parser.text(text)
    return Parser(function(str)
        if str:sub(1, #text) == text then
            return Success(Tuple(text, str:sub(#text + 1)))
        else
            return Error("Expected ".. text .." found "..str:sub(1, #text))
        end
    end)
end

function Parser.mti:map(func)
    return Parser(function(str) return self:run(str):map(function(tup) return Tuple(func(tup[1]), tup[2]) end) end)
end

function Parser.mti:flatMap(func)
    return Parser(function(str) return self:run(str):flatMap(function(tup) return func(tup[1]):run(tup[2]) end) end)
end

function Parser.mti:val(value)
    return self:map(function() return value end)
end

function Parser.match(regex)
    local regex = "^" .. regex
    return Parser(function(str)
        local match = {str:match(regex) }
        if type(match[1]) == "number" then match = {""} end

        local len = 0
        for i,v in pairs(match) do
            len = len + #v
        end
        if #match == 0 then
            return Error("Expected matching: '" .. regex .. "' Found: " .. str:sub(1, 10))
        else
            if #match == 1 then match = match[1] end
            return Success(Tuple(match, str:sub(len + 1)))
        end
    end)
end

function Parser.mt.__mul(pa, pb)
    Types.expect(pa, "Parser")
    Types.expect(pb, "Parser")
    return Parser(function(str)
        local a = pa:run(str)
        if a.isSuccess then
            return a
        else
            return pb:run(str)
        end
    end)
end

function Parser.mt.__add(pa, pb)
    Types.expect(pa, "Parser")
    Types.expect(pb, "Parser")
    return pa:flatMap(function(a) return pb:map(function(b) return Tuple(a,b) end) end)
end

function Parser.mt.__mod(pa, func)
    return pa:map(func)
end

return Parser















