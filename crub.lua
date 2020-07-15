--[[
The Crub Bootloader

Allows you to run multiple os's on a single machine
]]

local json = require("json")
local kbui = require("kbui")

-- Load configuration
function loadConfig()
  if not fs.exists("crub.cfg") then
    return {}
  else
    local file = fs.open("crub.cfg", "r")
    local config = json.decode(file.readAll())
    file.close()
    return config
  end
end


local config = loadConfig()

-- UI code

kbui.createElement(function() term.setCursorPos(1,1); print("q to quit") end, {key = {[keys.q] = function() kbui.stop() end}})

kbui.run()
