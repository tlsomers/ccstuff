--
-- Created by IntelliJ IDEA.
-- User: tlsomers
-- Date: 7/13/20
-- Time: 1:00 PM
-- To change this template use File | Settings | File Templates.
--

local Types = {}

function Types.new(data)
    local name = data.name or "UnknownType"
    local mti = data.data or {}
    local constructor = data.constructor or function(mt, data) return setmetatable(data, mt) end
    local getType = data.getType or name

    local mt = {__index = mti, __type = getType, __tostring = data.toString}

    local TMT = {}
    local Type = setmetatable({mti = mti, MT = TMT, mt = mt}, TMT)

    function TMT.__call(_, ...)
        return constructor(mt, ...)
    end

    return Type
end

local oldType = nativetype or type
function Types.getType(a)
    if oldType(a) ~= "table" then
        return oldType(a)
    else
        local mtable = getmetatable(a) or {}
        local tpe = mtable.__type or "table"
        if oldType(tpe) == "string" then
            return tpe
        else
            return mtable.__type(a) or "table"
        end
    end
end

function Types.expect(par, tpe)
    local part = Types.getType(par)
    if part ~= tpe and not part:match(tpe) then
        error("Expected type "..tpe.." found ".. part ..".")
    end
end

-- Replace global type function
if not _G.nativetype then
    _G.nativetype = oldType
    _G.type = Types.getType
    _G.expectType = Types.expect
else
    _G.type = Types.getType
    _G.expectType = Types.expect
end

-- Install the Types library
_G.Types = Types

return Types



