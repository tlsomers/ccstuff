local user = "tlsomers"
local repo = "ccstuff"

local gitfs = {}



local cache = {}
function http.getJSON(link, ...)
  if cache[link] and cache[link].time > os.clock() - 5 then
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
  local link = "https://api.github.com/repos/"..user.."/"..repo.."/contents"

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

fs.mount("git", gitfs)
