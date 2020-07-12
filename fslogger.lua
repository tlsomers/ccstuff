
function fs.log(logFunction)

  local logfs = {}

  function inTarget(method)
    logfs[method] = function(fs,...)
      logFunction(fs, method, {...})
      return fs[method](...)
    end
  end

  inTarget("list")
  inTarget("getSize")
  inTarget("exists")
  inTarget("isDir")
  inTarget("isReadOnly")
  inTarget("makeDir")
  inTarget("delete")
  inTarget("open")
  inTarget("getDrive")
  inTarget("getFreeSpace")
  inTarget("getName")
  inTarget("getDir")
  inTarget("isDriveRoot")
  inTarget("getCapacity")
  inTarget("attributes")
  inTarget("find")
  inTarget("copy")
  inTarget("move")
  inTarget("moveOut")
  inTarget("moveIn")

  fs.mount("", logfs)
end

function fs.logFile(path)
  function log(fs, method, args)
    local file = fs.open(path, "w")
    file.writeLine("["..method.."] "..textutils.serialise(args))
    file.close()
  end
  fs.log(log)
end
