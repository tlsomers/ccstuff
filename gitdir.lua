local user = "tlsomers"
local repo = "ccstuff"
local cacheTime = 10

local gitfs = {}



local cache = {}
function http.getJSON(link, ...)
  if cache[link] and cache[link].time > os.clock() - cacheTime then
    return cache[link].response
  else
    local req, err = http.get(link, ...)
    if req then
      local result = textutils.unserializeJSON(req.readAll())
      req.close()
      cache[link] = {response = result, time = os.clock()}
      return result, err
    else
      return req, err
    end
  end
end

function gitfs.isReadOnly(fs)
  return true
end

function gitfs.list(_, path)
  local link = "https://api.github.com/repos/"..user.."/"..repo.."/contents/"+path

  local req, err = http.getJSON(link)
  if not req then
    return {}
  else
    local items = {}
    for _,v in pairs(req) do
      items[#items+1] = v.path
    end
    return items
  end
end

function gitfs.isDir(fs, path)
  local parent = fs.getDir(path)
  local link = "https://api.github.com/repos/"..user.."/"..repo.."/contents/"+parent
  local req, err = http.getJSON(link)
  for _,v in pairs(req) do
    if v.name == fs.getName(path) then
      return v.type == "dir"
    end
  end
  return false
end

function gitfs.getSize(fs, path)
  local parent = fs.getDir(path)
  local link = "https://api.github.com/repos/"..user.."/"..repo.."/contents/"+parent
  local req, err = http.getJSON(link)
  for _,v in pairs(req) do
    if v.name == fs.getName(path) then
      return v.size
    end
  end
  return 0
end

function gitfs.getDrive()
  return "git"
end

function gitfs.getAttibutes(fs, path)
  local parent = fs.getDir(path)
  local link = "https://api.github.com/repos/"..user.."/"..repo.."/contents/"+parent
  local req, err = http.getJSON(link)
  for _,v in pairs(req) do
    if v.name == fs.getName(path) then
      return {
        size = v.size,
        isDir = v.type == "dir",
        created = 0,
        modified = 0
      }
    end
  end
  return {}}
end

function gitfs.open(fs, path, mode)fs.
  if mode ~= "r" then
    error("Cannot write to read only files")
  else
    local link = "https://api.github.com/repos/"..user.."/"..repo.."/contents/"+path
    local r1, err = http.getJSON(link)
    if not r1 then
      return nil, path..": No such file"
    else
      local r2, err = http.get(r1.download_url)
      if not r2 then
        return nil, path..": Cannot open file"
      else
        return r2
      end
    end
  end
end

fs.mount("git", gitfs)
