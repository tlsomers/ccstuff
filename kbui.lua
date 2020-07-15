
local kbui = {}

kbui.elements = {}

function kbui.createElement(render, events)
  local el = {render = render}
  if type(events) == "function" then
    el.events = events(el)
  else
    el.events = events
  end
  kbui.addElement(el)
  return el
end


function kbui.handleEvent(event)
  function handleEventFor(element, event)
    if not element.events then
      return
    elseif type(element.events) == "function" then
      element.events(unpack(event))
    elseif type(element.events) == "table" then
      local events1 = element.events[event[1]]
      if type(events1) == "function" then
        events1(unpack(event))
      elseif type(events1) == "table" then
        local events2 = events1[event[2]]
        if type(events2) == "function" then
          events2(unpack(event))
        elseif type(events1['all']) == "function" then
          events1['all'](unpack(event))
        elseif type(element.events['all']) == "function" then
          element.events['all'](unpack(event))
        end
      elseif type(element.events['all']) == "function" then
        element.events['all'](unpack(event))
      end
    end
  end

  if kbui.selected then
    return handleEventFor(kbui.selected, event)
  end

  for _,v in pairs(kbui.elements) do
    handleEventFor(v, event)
  end
end

function kbui.redraw()
  term.clear()
  for _,v in pairs(kbui.elements) do
    if v.render then v.render(v == kbui.selected) end
  end
end

function kbui.select(el)
  kbui.selected = el
end

function kbui.unselect(el)
  if kbui.selected == el then kbui.selected = nil end
end

function kbui.addElement(el)
  kbui.elements[#kbui.elements + 1] = el
end

local running = false
function kbui.run()
  running = true
  while running do
    kbui.redraw()
    local event = {os.pullEvent()
    kbui.handleEvent(event)
  end
end

function kbui.stop()
  running = false
end

--- UI elements

kbui.components = {}

function kbui.components.textCenter(y, text, textColor, bgColor)
  local comp = {}
  comp.y = y or 1
  comp.text = text or "unknown"
  comp.textColor = textColor or colors.white
  comp.bgColor = bgColor or colors.white
  comp.x = 1
  comp.width = "term"

  function comp.render()
    local width = comp.width
    if not width or width == "term" then
      -- Fill up remaining space
      width = term.getSize() - comp.x + 1
    end
    local pad = (width - #comp.text) / 2
    local fulltext = string.rep(" ", math.floor(pad)) .. comp.text .. string.ceil(" ", math.floor(pad))
    term.setCursorPos(comp.x, comp.y)
    term.write(fulltext)
  end

  return comp
end




















return kbui,
