local function copyTable(a, b)
  for i,v in pairs(a) do
    b[i] = v
  end
  return b
end

local oldfs = copyTable(_G.fs, {})

function clean(path)
  return oldfs.combine(path, "")
end

local function getMount(mounts, path)
  path = clean(path)
  if #mounts == 0 then
    return false
  else
    local initial = _.initial(mounts)
    local last = _.last(mounts)
    if last.path == "" or path == last.path or path:sub(1,#(last.path)+1) == last.path .. "/" then
      return {fs = last.fs, path = path:sub(#(last.path) + 1), mount = last.path}, initial
    else
      return getMounts(initial, path)
    end
  end
end

local function fsWithMounts(mounts)
  local fs = {}

  function tryMount(func)
    function inner (path, ...)
      local mount, rest = getMount(mounts, path)
      if mount then
        local innerfs = fsWithMounts(rest)
        if mount.fs[func] then
          return mount.fs[func](innerfs, mount.path, ...)
        else
          return fsWithMounts(rest)[func](path, ...)
        end
      else
        return oldfs[func](path, ...)
      end
    end
    return inner
  end

  fs.list = tryMount("list")

  fs.getName = tryMount("getName")

  fs.getSize = tryMount("getSize")

  fs.exists = tryMount("exists")

  fs.isDir = tryMount("isDir")

  fs.isReadOnly = tryMount("isReadOnly")

  fs.makeDir = tryMount("makeDir")

  fs.delete = tryMount("delete")

  fs.open = tryMount("open")

  fs.getDrive = tryMount("getDrive")

  fs.getFreeSpace = tryMount("getFreeSpace")

  fs.getDir = tryMount("getDir")

  fs.isDriveRoot = tryMount("isDriveRoot")

  fs.getCapacity = tryMount("getCapacity")

  fs.attibutes = tryMount("attributes")

  function fs.combine(a,b)
    return oldfs.combine(a,b)
  end

  fs.copy = oldfs.copy

  fs.move = oldfs.move

  fs.find = oldfs.find

  fs.complete = oldfs.complete

  return fs
end

local allMounts = {}
local fs = fsWithMounts(allMounts)


function fs.mount(path, mount)
  path = clean(path)
  if not fs.isDir(path) then
    error("Must mount in dir")
  elseif fs.isReadOnly(path) then
    error("Cannot mount in read-only place")
  else
    allMounts[#allMounts + 1] = {fs = mount, path = path}
  end
end

copyTable(fs, _G.fs)
