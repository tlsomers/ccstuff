--
-- Created by IntelliJ IDEA.
-- User: tlsomers
-- Date: 7/13/20
-- Time: 3:51 PM
-- To change this template use File | Settings | File Templates.
--

local args = {...}
if not args[1] then error("Expected file") end

if args[1]:sub(-5) == ".luaf" then args[1] = args[1]:sub(1, -6) end
local fileName = args[1]


require("parser")

function transformLuaFunction(newStyle)

    local index = newStyle:match("()=")

    local args = newStyle:sub(2,index - 1):match("(.*%S)%s*"):gsub("%s+", ",")
    local rest, final = newStyle:sub(index+1):gmatch("%s*(%S.-)([\\n;)]?)$")()
    print(rest, final)
    local oldStyle = "function ("..args..") return (" .. rest .. ") end" .. final
    return oldStyle
end

function luaFFunction()
    function reader(n, text)
        local endLine = (Parser.match("([^()]*)[\n;]") * Parser.match("([^()]*)$")):map(function(a) return text .. a end)
        local badPar = Parser.match("([^()]*)([()])"):flatMap(function (data)
            local a, par = unpack(data)
            if par == ")" then
                if n == 0 then
                    return Parser.pure(text .. a .. par)
                else
                    return reader(n - 1, text .. a .. par)
                end
            else
                return reader(n+1, text .. a .. par)
            end
        end)
        return endLine * badPar
    end
    return Parser.match("()\\%a"):flatMap(function() return reader(0, "") end):map(transformLuaFunction)
end

function newLuaCode(text)
    text = text or ""

    local normalCode = Parser.match("\\?[^\\]+")
    local functionCode = luaFFunction()

    return (functionCode * normalCode * Parser.pure(nil)):flatMap(function(a)
        if not a then
            return Parser.pure(text)
        else
            return newLuaCode(text .. a)
        end
    end)
end

local filer = io.open(fileName..".luaf", "r")
local filew = io.open(fileName..".lua", "w")

local text = filer:read("*a")

newLuaCode():run(text):map(function (tup) return filew:write(tup[1]) end)

filer:close()
filew:close()
