local oldfs = _G.fs

local fs = {}

local mounts = {}

function clean(path)
  return oldfs.combine(path, "")
end

function oldfs.mount(path, mount)
  path = oldfs.combine(path, "")
  if not oldfs.isDir(path) then
    error("Must mount in dir")
  elseif oldfs.isReadOnly(path) then
    error("Cannot mountin read-only place")
  else
    mounts[path] = mount
  end
end

function getMount(path)
  path = clean(path)
  for i,v in pairs(mounts) do
    if path == i or path:sub(1,#i+1) == i .. "/" then
      return {fs = v, path = path:sub(#i + 1), mount = i}
    end
  end
  return false
end

function tryMount(func)
  function inner (path, ...)
    local mount = getMount(path)
    if mount and mount.fs[func] then
      return mount.fs[func](oldfs, mount.path, ...)
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

-- TODO

fs.find = oldfs.find

fs.complete = oldfs.complete

fs.move = oldfs.move

fs.copy = oldfs.copy

_G.fs = fs
