
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

local function getRawFile(link, path)
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
  getRawFile("https://raw.githubusercontent.com/tlsomers/ccstuff/master/symlink.lua", ".multiboot/symlink.lua")

  print("Downloading bios")
  getRawFile("https://raw.githubusercontent.com/SquidDev-CC/CC-Tweaked/7b2d4823879a6db77bb99fc2e8605e9e54a0d361/src/main/resources/data/computercraft/lua/bios.lua", ".multiboot/bios.lua")

  print("Downloading LuaDash")
  getRawFile("https://raw.githubusercontent.com/tmpim/luadash/master/library.lua", ".multiboot/luadash.lua")

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

_G._ = dofile(".multiboot/luadash.lua")
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
      osses[#osses + 1] = v
    end
  end
  return osses
end

function readOption(options)
  for i,v in pairs(options) do
    print(tostring(i) .. ": " .. tostring(v.name))
  end
  local _, y = term.getCursorPos()
  while true do
    term.setCursorPos(1, y)
    term.clearLine()
    term.write("> ")
    local i = read()
    local i2 = tonumber(i)
    if options[i] then
      return options[i]
    elseif options[i2] then
      return options[i2]
    end
  end
end

function loadOS(name)
  print("Mounting rom")

  local path = fs.combine("dev", name)

  if not fs.exists(fs.combine(path,"rom")) then
    fs.makeDir(fs.combine(path, "rom"))
  end
  fs.symlink(fs.combine(path, "rom"), "rom")

  print("Loading virtual file system")
  fs.symlink("/", path, true)

  print("Booting OS")
  bios()
end

function createBoot()
  local name = fs.getName(fs.combine(read(), ""))
  while name == "" or fs.exists(fs.combine("dev", name)) do
    name = fs.getName(fs.combine(read(), ""))
  end
  fs.makeDir(fs.combine("dev", name))
  loadOS(name)
end

function update()
  fs.delete(".multiboot")
  print("Downloading MultiBoot Installer")
  getRawFile("https://raw.githubusercontent.com/tlsomers/ccstuff/master/MultiBoot.lua", "MultiBoot.lua")
  dofile("MultiBoot.lua")
end

local options = setmetatable({}, {__index = _})
options:push({name = "Update", func = update})
options:push({name = "New Boot", func = createBoot})

for i,v in pairs(listOS()) do
  options:push({name = v, func = function() loadOS(v) end})
end

readOption(options).func()
