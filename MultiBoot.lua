
dofile("pluggablefs.lua")
dofile("symlink")

term.clear()
term.setCursorPos(1,1)

print("MultiBoot boot menu")

if not fs.exists("dev") then
  fs.makeDir("dev")
end

function listOS()
  local dirs = fs.list("dev")
  local osses = {}
  for _,v in pairs(dirs) do
    if fs.isDir(fs.combine("dev", v)) then
      osses[#osses + 1] = fs.combine("dev", v)
    end
  end
end

local osses = listOS()

print("0: new")
for i,v in pairs(osses) do
  print(tostring(i)..": "..fs.getName(v))
end

local choice = -1
while choice < 0 or choice > #osses do
  term.write("> ")
  term.setCursorBlink(true)
  choice = tonumber(read()) or choice
end
term.setCursorBlink(false)

if choice == 0 then
  local name = fs.getName(fs.combine(read(), ""))
  while name == ""c or fs.exists(fs.combine("dev", name)) do
    name = fs.getName(fs.combine(read(), ""))
  end
  fs.makeDir(fs.combine("dev", name))
  osses[#osses + 1] = fs.combine("dev", name)
  choice = #osses
end

print("Mounting rom")
local path = osses[choice]
if not fs.exists(fs.combine(path,"rom")) then
  fs.makeDir(path, "rom")
end
fs.symlink(fs.combine(path, "rom"), "rom")

print("Loading virtual file system")
dofile("pluggablefs.lua")
dofile("symlink")
fs.symlink("/", path)

print("Booting os")
if fs.exists("startup.lua") then
  dofile("startup.lua")
end
