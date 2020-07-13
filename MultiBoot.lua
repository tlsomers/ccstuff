
--- The first method run in the guest fs environment
local function bios()

  --- Allow custom bios and rom override
  if fs.exists("rom/bios.lua") then
    --- Note, normal bios remains loaded, we do not (yet) unload the current bios.
    os.run({}, "rom/bios.lua")
  else
    --- The normal bios is already loaded, just need to run shell
    local sShell
    if term.isColour() and settings.get("bios.use_multishell") then
        sShell = "rom/programs/advanced/multishell.lua"
    else
        sShell = "rom/programs/shell.lua"
    end
    os.run({}, sShell)
    os.run({}, "rom/programs/shutdown.lua")
  end
end



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

  print("Downloading LuaDash")
  getRawFile("https://raw.githubusercontent.com/tmpim/luadash/master/library.lua", ".multiboot/luadash.lua")

  print("Downloading OneDrive fs")
  getRawFile("https://raw.githubusercontent.com/tlsomers/ccstuff/master/onedrive.lua", ".multiboot/onedrive.lua")

  print("Downloading RamDisk")
  getRawFile("https://raw.githubusercontent.com/tlsomers/ccstuff/master/ramdisk.lua", ".multiboot/ramdisk.lua")

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


--Plugins? Why
function loadPlugins()
  local fsopen = fs.open
  local fsexists = fs.exists

  fs.makeDir(".multibootplugins/")

  function setupPlugin(name)
    local configuration = {}
    local pluginFile = ".multibootplugins/"..name
    local confFile = ".multibootplugins/"..(name:sub(1,-5))..".config"
    if fsexists(confFile) then
      local file = fsopen(confFile, "r")
      configuration = textutils.unserialise(file.readAll())
      file.close()
    end

    local config = {}
    function config.get(key)
      return configuration[key]
    end

    function config.getOrElse(key, default)
      return configuration[key] or default
    end

    function config.set(key, value)
      configuration[key] = value
      local file = fsopen(confFile, "w")
      file.write(textutils.serialise(configuration))
      file.close()
    end

    return function(osconfig)
      os.run({config = config, osconfig = osconfig}, pluginFile)
    end
  end

  local plugins = {}

  for _,v in pairs(fs.list(".multibootplugins")) do
    if v:sub(-4) == ".lua" then
      _.push(plugins, setupPlugin(v))
    end
  end

  return plugins
end

_G._ = dofile(".multiboot/luadash.lua")

local plugins = loadPlugins()

dofile(".multiboot/pluggablefs.lua")
dofile(".multiboot/symlink.lua")
dofile(".multiboot/ramdisk.lua")

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

function loadOneDrive()

  print("Creating RamDisk")
  if not fs.exists(".tmp") then fs.makeDir(".tmp") end
  fs.ramdisk(".tmp")

  print("Mounting OneDrive")
  if not fs.exists("onedrive") then fs.makeDir("onedrive") end
  dofile(".multiboot/onedrive.lua")

  print("Mounting rom")
  if not fs.exists("onedrive/rom") then fs.makeDir("onedrive/rom") end
  fs.symlink("onedrive/rom", "rom")

  print("Loading virtual file system")
  fs.symlink("/", "onedrive", true)

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
options:push({name = "OneDrive", func = loadOneDrive})

for i,v in pairs(listOS()) do
  options:push({name = v, func = function() loadOS(v) end})
end

local option = readOption(options)
_.map(plugins, function(plugin) plugin(option.name) end)
option.func()
