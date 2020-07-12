
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
  local file = fs.open(path, "w")
  function log(fs, method, args)
    file.writeLine("["..method.."] "..textutils.serialise(args))
    file.flush()
  end
  fs.log(log)
end

function fs.screenLogger()
  local width = 15
  local w,h = term.getSize()
  local logWindow = window.create(term.current(), w - width + 1, 1, width, h)
  local mainWindow = window.create(term.current(), 1, 1, w - width, h)

  function log(fs, method, args)
    term.redirect(logWindow)
    print("["..method.."] "..textutils.serialise(args))
    term.redirect(mainWindow)
  end

  fs.log(log)
  term.redirect(mainWindow)
end
