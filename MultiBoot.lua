
function promptYN(text)
  term.write(text .. " (y/n)")
  while true do
    local event, key = os.pullEvent( "key" )
    if key == keys.y then
      print()
      return true
    elseif key == keys.n then
      print()
      return false
    end
  end
end

local funtion getRawFile(link, path)
  local file = fs.open(path, "w")
  local handle, err = http.get(link)
  if handle then
    file.write(handle.readAll())
    file.close()
    handle.close()
  else
    error(err)
  end
end

if not fs.exists(".multiboot") then
  print("Multiboot is not installed")
  if not promptYN("Install") then
    return
  end

  fs.makeDir(".multiboot")

  print("Downloading PluggableFs")
  getRawFile("https://raw.githubusercontent.com/tlsomers/ccstuff/master/pluggablefs.lua", ".multiboot/pluggablefs.lua")

  print("Downloading Symlink")
  getRawFile("https://raw.githubusercontent.com/tlsomers/ccstuff/master/symlink", ".multiboot/symlink.lua")

  print("Downloading bios")
  getRawFile("https://raw.githubusercontent.com/SquidDev-CC/CC-Tweaked/7b2d4823879a6db77bb99fc2e8605e9e54a0d361/src/main/resources/data/computercraft/lua/bios.lua", ".multiboot/bios.lua")

  print("Downloading MultiBoot")
  getRawFile("https://raw.githubusercontent.com/tlsomers/ccstuff/master/MultiBoot.lua", "MultiBoot.lua")


  print("Download completed")
  if promptYN("Run at startup? (y/n)") then
    if fs.exists("startup.lua") then
      fs.copy("startup.lua", "startup_backup.lua")
      print("Old startup saved as startup_backup.lua")
    end
    local file = fs.open("startup.lua", "w")
    file.write("dofile('MultiBoot.lua')")
    file.close()
  end
  if not promptYN("Run MultiBoot now?") then
    return
  end
end

local bios = loadfile(".multiboot/bios.lua")

dofile(".multiboot/pluggablefs.lua")
dofile(".multiboot/symlink.lua")

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
  return osses
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
  while name == "" or fs.exists(fs.combine("dev", name)) do
    name = fs.getName(fs.combine(read(), ""))
  end
  fs.makeDir(fs.combine("dev", name))
  osses[#osses + 1] = fs.combine("dev", name)
  choice = #osses
end

print("Mounting rom")
local path = osses[choice]
if not fs.exists(fs.combine(path,"rom")) then
  fs.makeDir(fs.combine(path, "rom"))
end
fs.symlink(fs.combine(path, "rom"), "rom")

print("Loading virtual file system")
fs.symlink("/", path)

print("Booting OS")
bios()
