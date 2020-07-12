
local File = {isDir = false}

function File.create(name)
  return setmetatable({name = name, content = ""}, {__index = File})
end

function File:size()
  return #self.content
end


function File:openRead()

  local index = 1
  local handle = {}

  function handle.read(n)
    local startpos = index
    local endpos = index + n - 1
    local res = self.content:sub(startpos, endpos)
    index = endpos + 1
    if res == "" then return nil else return res end
  end

  function handle.readLine()
    local line, newline = self.content:sub(index):match("([^\n]*)(\n?)")
    index = index + #line + #newline
    if line == "" and newline == "" then
      return nil
    else
      return line
    end
  end

  function handle.readAll()
    local rest = self.content:sub(index)
    index = #self.content + 1
  end

  function handle.close()
    function errorClosed() error("Closed handle") end
    handle.read =  errorClosed
    handle.readLine = errorClosed
    handle.readAll = errorClosed
    handle.close = errorClosed
  end

  return handle

end

function File:openAppend()

  local buffer = ""
  local handle = {}

  function handle.write(text)
    buffer = buffer .. text
  end

  function handle.writeLine(text)
    buffer = buffer .. text .. "\n"
  end

  function handle.flush()
    self.content = self.content .. buffer
    buffer = ""
  end

  function handle.close()
    function errorClosed() error("Closed handle") end
    handle.write =  errorClosed
    handle.writeLine = errorClosed
    handle.flush = errorClosed
    handle.close = errorClosed
  end

  return handle
end

function File:openWrite()
  self.content = ""
  return self:openAppend()
end

function File:open(mode)
  if mode == "r" then
    return self:openRead()
  elseif mode == "w" then
    return self:openWrite()
  elseif mode == "a" then
    return self:openAppend()
  else
    error("Cannot open ramdisk file in mode (" .. tostring(mode) .. ")")
  end
end

local Directory = {isDir = true}

function Directory.create(name)
  return setmetatable({name = name}, {__index = Directory})
end

function Directory:list(path)
  if path == "" or path == nil then
    return _.map(self.children, function(c) return c.name end)
  else
    local first, rest = subpath:match("([^/]+)/(.*)")

    for _,v in pairs(self.children) do
      if v.name == first then
        if v.isDir then
          return v:list(rest)
        else
          error("Is not a directory")
        end
      end
    end

    error("Not found")
  end
end

function Directory:exists(subpath)
  subpath = fs.combine(subpath or "", "")
  if subpath == "" then
    return true
  else
    local first, rest = subpath:match("([^/]+)/(.*)")
    for _,v in pairs(self.children) do
      if v.name == first then
        if rest == "" then
          return true
        elseif v.isDir then
          return v:exists(rest)
        else
          return false
        end
      end
    end
  end
end

function Directory:makeDir(subpath)
  subpath = fs.combine(subpath, "")
  if subpath == "" then
    return self
  else
    local first, rest = subpath:match("([^/]+)/(.*)")
    local directory = Directory.create(first)
    return directory:makeDir(rest)
  end
end

function Directory:delete(subpath)
  subpath = fs.combine(subpath or "" "")
  if subpath == "" then
    error("Cannot delete directory itself")
  else
    local first, rest = subpath:match("([^/]+)/(.*)")
    if rest == "" then
      self.children = _.filter(self.children, function(c) return c.name ~= first end)
    else
      for _,v in pairs(self.children) do
        if v.name == first then
          return v:delete(rest)
        end
      end
      error("Not found")
    end
  end
end

function Directory:getFile(subpath, create)
  subpath = fs.combine(subpath or "" "")
  if subpath == "" then
    error("Not a file")
  else
    local first, rest = subpath:match("([^/]+)/(.*)")
    for _,v in pairs(self.children) do
      if v.name == first then
        if v.isDir then
          return v:getFile(rest)
        elseif rest == "" then
          return v
        else
          error("Not found")
        end
      end
    end
    if create and rest == "" then
      local file = File.create(first)
      _.push(self.children, file)
      return file
    else
      error("Not found")
    end
  end
end

function Directory:get(subpath, create)
  subpath = fs.combine(subpath or "" "")
  if subpath == "" then
    return self
  else
    local first, rest = subpath:match("([^/]+)/(.*)")
    for _,v in pairs(self.children) do
      if v.name == first then
        if v.isDir then
          return v:get(rest)
        elseif rest == "" then
          return v
        else
          error("Not found")
        end
      end
    end
    error("Not found")
  end
end

function Directory:getOrCreateFile(subpath)
  return self:getFile(subpath, true)
end

function Directory:size()
  return 0
end

function fs.ramdisk(location)

  local disk = Directory.create("ramdisk")

  local ramfs = {}

  function ramfs.list(fs, path)
    return disk:list(path)
  end

  function ramfs.getSize(fs, path)
    local thing = disk:get(path)
    if thing.isDir then
      return 0
    else
      return #thing.content
    end
  end

  function ramfs.exists(fs, path)
    return disk:exists(path)
  end

  function ramfs.isReadOnly()
    return false
  end

  function ramfs.isDir(fs, path)
    return disk:get(path).isDir
  end

  function ramfs.makeDir(fs, path)
    return disk:makeDir(path)
  end

  function ramfs.delete(fs, path)
    return disk:delete(path)
  end

  function ramfs.open(fs, path, mode)
    local file = disk:getFile(path, mode ~= "r")
    return file:open(mode)
  end

  function ramfs.getDrive(fs, path)
    return "ramdisk"
  end

  function ramfs.getFreeSpace(fs, path)
    return math.pow(2, 16)
  end

  function ramfs.attributes(fs, path)
    local thing = disk:get(path)
    return {
      size = thing:size(),
      isDir = thing.isDir,
      created = 0,
      modified = 0
    }
  end

  function symfs.find(fs, name)
    if disk:exists(name) then return {name} else return {} end
  end

  fs.mount(location, ramfs)
end
