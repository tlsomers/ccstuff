
local base64 = dofile("/rom/modules/main/base64.lua")

local appId = "14629d23-c110-4719-961c-e64aace2dfd5"
local appRedirect = "https://login.microsoftonline.com/common/oauth2/nativeclient"
local appScope = "Files.ReadWrite.AppFolder offline_access"
local refreshtokenfile = ".onedrive.refresh_token"

local http = setmetatable({}, {__index = http})

--- Replace the native get/post with fakely 'non blocking' ones
--[[
local oldget = http.get
function http.get(url, headers, binary)

  local result = nil
  local events = {}

  parallel.waitForAny(function()
    result = {oldget(url, headers, binary)}
  end, function() while true do _.push(events, {os.pullEvent()}) end end)

  for _,v in pairs(events) do
    os.queueEvent(unpack(v))
  end
  return unpack(result)
end
]]


function encodeOptions(options)
    if type(options) == "string" then return options end
    local opt = nil
    for i,v in pairs(options) do
        if opt then opt = opt .. "&" else opt = "" end
        opt = opt .. textutils.urlEncode(i) .. "=" .. textutils.urlEncode(v)
    end
    return opt
end

function http.postString(options)
    return encodeOptions(options)
end

function http.getString(link, options)
    if not options then
        return link
    else
        return link .. "?" .. encodeOptions(options)
    end
end

-- Request a json response using a table as post data
function http.postJSON(link, data, headers)
    local poststr = http.postString(data)
    local resp, err, errresp = http.post(link, poststr, headers)
    if not resp then
        return false, err, textutils.unserialiseJSON(errresp.readAll())
    else
        return textutils.unserialiseJSON(resp.readAll())
    end
end

-- Request a json response using a table as post data
function http.getJSON(link, data, headers)
    local link = http.getString(link, data)
    local resp, err, errresp = http.get(link, headers)
    if not resp then
        return false, err
    else
        return textutils.unserialiseJSON(resp.readAll())
    end
end



function retrieveCode()
  local link = http.getString("https://login.microsoftonline.com/common/oauth2/v2.0/authorize", {
    client_id = appId,
    response_type = "code",
    redirect_uri = appRedirect,
    response_mode = "query",
    scope = appScope
  })
  print("Login Link: "..link)
  if chatbox and chatbox.tell then
      chatbox.tell("Tomtrein", link)
  end
  term.write("Code: >")
  local code = read()
  return code
end

function retrieveToken()
    local link = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
    local response, err, errresp = nil, nil, nil
    if fs.exists(refreshtokenfile) then
        local file = fs.open(refreshtokenfile, "r")
        local refresh_token = file.readAll()
        file.close()
        response, err, errresp = http.postJSON(link, {
            client_id = appId,
            scope = appScope,
            refresh_token = refresh_token,
            redirect_uri = appRedirect,
            grant_type = "refresh_token"
        })
    else
        local code = retrieveCode()
        response, err, errresp = http.postJSON(link, {
            client_id = appId,
            scope = appScope,
            code = code,
            grant_type = "authorization_code",
            redirect_uri = appRedirect
        })
    end
    if not response then error(errresp.error) end

    local file = fs.open(refreshtokenfile, "w")
    file.write(response.refresh_token)
    file.close()

    return response.access_token
end

local access_token = "bearer " .. retrieveToken()
local headers = {Authorization = access_token}

_G.onedrive = {}
onedrive.token = access_token


local onedriveRequestCache = {}

function clearCache()
    onedriveRequestCache = {}
end
function onedriveGetJSON(endpoint, data)
    if onedriveRequestCache[endpoint] then
        return unpack(onedriveRequestCache[endpoint])
    else
        local result = {http.getJSON("https://graph.microsoft.com/v1.0" .. endpoint, data, headers)}
        onedriveRequestCache[endpoint] = result
        return unpack(result)
    end
end

function onedriveGetText(endpoint, data)
    local link = http.getString("https://graph.microsoft.com/v1.0" .. endpoint, data)
    local resp, err, errresp = http.get(link, headers)
    if not resp then
        return nil, err, textutils.unserialiseJSON(errresp.readAll())
    else
        return resp.readAll()
    end
end

function onedrivePostJSON(endpoint, data)
    return http.postJSON("https://graph.microsoft.com/v1.0" .. endpoint, data, headers)
end

function onedrivePutJSON(endpoint, jsonData)
    local jsonText = json.encode(jsonData)
    local headers = _.clone(headers)
    headers["Content-Type"] = "application/json"
    headers["Content-Length"] = string.len(jsonText)
    return http.postJSON("https://graph.microsoft.com/v1.0" .. endpoint, jsonText, headers)
end

function onedrivePut(endpoint, textData)
    local headers = _.clone(headers)
    headers["Content-Type"] = "text/plain"
    headers["Content-Length"] = tostring(string.len(textData))
    local _url = "https://graph.microsoft.com/v1.0" .. endpoint
    local ok, err = http.request({url= _url, method = "PUT", headers = headers, body = textData})
    if ok then
        while true do
            local event, param1, param2, param3 = os.pullEvent()
            if event == "http_success" and param1 == _url then
                return param2
            elseif event == "http_failure" and param1 == _url then
                return nil, param2, param3
            end
        end
    end
    return nil, err
end

function onedrivePatch(endpoint, jsonData)
    local headers = _.clone(headers)
    local textData = textutils.serialiseJSON(jsonData)
    headers["Content-Type"] = "application/json"
    headers["Content-Length"] = tostring(string.len(textData))
    local _url = "https://graph.microsoft.com/v1.0" .. endpoint
    local ok, err = http.request({url= _url, method = "PATCH", headers = headers, body = textData})
    if ok then
        while true do
            local event, param1, param2, param3 = os.pullEvent()
            if event == "http_success" and param1 == _url then
                return param2
            elseif event == "http_failure" and param1 == _url then
                return nil, param2, param3
            end
        end
    end
    return nil, err
end

function onedriveDelete(endpoint)
    local _url = "https://graph.microsoft.com/v1.0" .. endpoint
    local ok, err = http.request({url= _url, method = "DELETE", headers = headers})
    if ok then
        while true do
            local event, param1, param2, param3 = os.pullEvent()
            if event == "http_success" and param1 == _url then
                return param2
            elseif event == "http_failure" and param1 == _url then
                return nil, param2, param3
            end
        end
    end
    return nil, err
end

onedrive.getJSON = onedriveGetJSON
onedrive.postJSON = onedrivePostJSON
onedrive.putJSON = onedrivePutJSON
onedrive.put = onedrivePut
onedrive.getText = onedriveGetText
onedrive.delete = onedriveDelete
onedrive.patch = onedrivePatch


--- Start working on file system stuff
-- Read only first

function tempFile(fs)
    if not fs.exists(".tmp") then fs.makeDir(".tmp") end
    local time = os.time()
    while true do
        local name = fs.combine(".tmp", base64.encode(tostring(time)))
        if not fs.exists(name) then
            return name
        end
        time = time + 0.0001
    end
end

local onedrivefs = {}

function onedrivefs.isReadOnly(fs)
    return false
end

function onedrivefs.list(_, path)
    local endpoint = "/drive/special/approot:/" .. path .. ":/children"
    if path == "" then endpoint = "/drive/special/approot/children" end
    local res, err, errres = onedrive.getJSON(endpoint)
    if res then
        return dash.map(res.value, function(item) return item.name end)
    else
        error(err)
    end
end

function onedrivefs.isDir(_, path)
    local endpoint = "/drive/special/approot:/" .. path
    if path == "" then endpoint = "/drive/special/approot" end
    local res, err, errres = onedrive.getJSON(endpoint)
    if res then
        return res.folder ~= nil
    else
        error(err)
    end
end

function onedrivefs.exists(fs, path)
    if path == "" or path == "/" then
        return true
    else
        local parentPath = fs.getDir(path)
        if not onedrivefs.exists(fs, parentPath) then return false end
        local name = fs.getName(path)
        for _,v in pairs(onedrivefs.list(fs, parentPath)) do
            if v == name then return true end
        end
        return false
    end
end

function onedrivefs.getSize(_, path)
    local endpoint = "/drive/special/approot:/" .. path
    if path == "" then endpoint = "/drive/special/approot" end
    local res, err, errres = onedrive.getJSON(endpoint)
    if res then
        return res.size
    else
        error(err)
    end
end

function onedrivefs.getDrive()
  return "onedrive"
end

function onedrivefs.getAttibutes(_, path)
    local endpoint = "/drive/special/approot:/" .. path
    if path == "" then endpoint = "/drive/special/approot" end
    local res, err, errres = onedrive.getJSON(endpoint)
    if res then
        return {
            size = res.size,
            isDir = res.folder ~= nil,
            created = 0,
            modified = 0
      }
    else
        error(err)
    end
end

function onedrivefs.makeDir(fs, path)
    if onedrivefs.exists(fs, path) then
        if onedrivefs.isDir(fs,path) then
            return
        else
            error("File exists")
        end
    elseif onedrivefs.isReadOnly(fs, path) then
        error("Read only")
    else
        local parent = fs.getDir(path)
        local name = fs.getName(path)
        onedrivefs.makeDir(fs, parent)

        local endpoint = "/drive/special/approot:/" .. parent .. ":/children"
        if parent == "" then endpoint = "/drive/special/approot/children" end

        onedrive.putJSON(endpoint, {name=name, folder={}})

        clearCache()
    end
end

function uploadFile(fs, foreignpath, localpath)
    local file = fs.open(localpath, "r")
    local text = file.readAll()
    file.close()

    local endpoint = "/drive/special/approot:/" .. foreignpath .. ":/content"
    if path == "" then endpoint = "/drive/special/approot/content" end

    onedrive.put(endpoint, text)

    clearCache()

end

function onedrivefs.open(fs, path, mode)
    local tempfile = tempFile(fs)
    if mode == "r" or mode == "a" then
        local endpoint = "/drive/special/approot:/" .. path .. ":/content"
        if path == "" then endpoint = "/drive/special/approot/content" end
        local res, err, errres = onedrive.getText(endpoint)
        if res then
            local file = fs.open(tempfile, "w")
            file.write(res)
            file.close()
        else
            fs.delete(tempfile)
            error(err)
        end
    end

    if mode == "a" or mode == "w" then
        -- Open and delete file on close
        local filer = fs.open(tempfile, mode)

        local oldflush = filer.flush
        function filer.flush()
          oldflush()
          uploadFile(fs, path, tempfile)
        end

        local oldclose = filer.close
        filer.close = function()
            oldclose()
            uploadFile(fs, path, tempfile)
            fs.delete(tempfile)
        end
        return filer
    elseif mode == "r" then
        -- Open and delete file on close
        local filer = fs.open(tempfile, mode)
        local oldclose = filer.close
        filer.close = function()
            oldclose()
            fs.delete(tempfile)
        end
        return filer
    end
end

function onedrivefs.delete(fs, path)
    if path == "" or path == "/" or path == nil then
        error("Cannot delete root directory")
    end
    local endpoint = "/drive/special/approot:/" .. path
    onedrive.delete(endpoint)

    clearCache()
end

function onedrivefs.find(fs, path)
    if onedrivefs.exists(fs, path) then
        return {path}
    else
        return {}
    end
end

function onedrivefs.move(fs, pa, pb)
  local endpoint = "/drive/special/approot:/" .. pa
  local parent = fs.getDir(pb)
  local name = fs.getName(pb)
  local newInfo = {name = name}
  local res, err, errres = onedrive.patch(endpoint, newInfo)
  if not res then
    error(errres and errres.readAll() or err)
  end
  clearCache()
end

_G.onedrivefs = onedrivefs

if not fs.exists("onedrive") then fs.makeDir("onedrive") end

fs.mount("onedrive", onedrivefs)
