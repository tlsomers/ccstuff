local oldfs = _G.fs

local fs = {}

local mounts = {}

function clean(path)
  return oldfs.combine(path, "")
end

function fs.mount(path, mount)
  path = oldfs.combine(path, "")
  if not oldfs.isDir(path) then
    error("Must mount in dir")
  elseif oldfs.isReadOnly(path) then
    error("Cannot mountin read-only place")
  elseif getMount(path) then
    error("Cannot mount in mount")
  end
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

local function moveOut(mount, dest, totalPath)
  if mount.fs.moveOut then
    return mount.fs.moveOut(oldfs, mount.path, dest)
  else
    return oldfs.move(totalPath, dest)
  end
end

local function moveIn(mount, source, totalPath)
  if mount.fs.moveIn then
    return mount.fs.moveIn(oldfs, dest, mount.path)
  else
    return oldfs.move(source, totalPath)
  end
end

function fs.move(patha, pathb)
  patha = clean(patha)
  pathb = clean(pathb)
  local mounta = getMount(patha)
  local mountb = getMount(pathb)
  if not mounta and not mountb then
    return oldfs.move(patha, pathb)
  elseif mounta and mountb and mounta.fs == mountb.fs then
    if mounta.fs.move then
      return mounta.fs.move(oldfs, mounta.path, mountb.path)
    else
      return oldfs.move(patha, pathb)
    end
  elseif mounta and not mountb then
    return moveOut(mounta, pathb, patha)
  else if mountb and not mounta then
    return moveIn(mountb, patha, pathb)
  else
    local temp = makeTemp()
    return moveOut(mounta, temp, patha)
    return moveIn(mountb, temp, pathb)
  end
end

function fs.copy (patha, pathb)
  patha = clean(patha)
  pathb = clean(pathb)
  local mounta = getMount(patha)
  local mountb = getMount(pathb)
  if not mounta and not mountb then
    oldfs.copy(patha, pathb)
  elseif mounta and mountb and mounta.fs == mountb.fs then
    if mounta.fs.copy then
      return mounta.fs.copy(oldfs, mounta.path, mountb.path)
    else
      return oldfs.copy(patha, pathb)
    end
  else
    local instream = (mounta and mounta.fs.open(olfds, mounta.path, "r")) or oldfs.open(patha, "r")
    local attempt, outstream = pcall(function() return (mountb and mountb.fs.open(oldfs, mountb.path, "r")) or oldfs.open(pathb, "w") end)
    if attempt then
      outstream.write(instream.readAll())
      outstream.close()
    end
    instream.close()
end

fs.find = oldfs.find

fs.complete = oldfs.complete

_G.fs = fs
