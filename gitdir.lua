local user = "tlsomers"
local repo = "ccstuff"

local gitfs = {}

function http.getJSON(...)
  local req, err = http.get(...)
  if req then
    local result = textutils.unserializeJSON(req.readAll())
    req.close()
    return result, err
  else
    return req, err
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
