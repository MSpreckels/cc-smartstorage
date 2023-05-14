-- TODO
-- [x] help
-- [x] commands structure
-- [x] request exact
-- [x] group blocks with amount
-- [x] cache items for faster delivery
-- [x] item sort: show items sorted by amount
-- smart sorting (put new items where old items already are)
-- mark storage for only output and no input
-- [x] filled percentage
-- [x] free slots
-- boost performance by only updating the moved items instead of reloading the storage

require("github")
require("history")
req_chest = peripheral.wrap("minecraft:chest_0")
items = {}
last_searched_items = {}
last_compiled = 0
keyset = {}

function upgrade(self)
  download("updater")
  shell.run("updater")
end

function max_slots()
  local slots = 0
  for i = 1, #peripheral.getNames(), 1 do
    local peri = peripheral.getNames()[i]
    if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
      slots = slots + peripheral.call(peri, "size")
    end
  end

  return slots
end

function available_slots()
  local slots = 0
  for i = 1, #peripheral.getNames(), 1 do
    local peri = peripheral.getNames()[i]
    if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
      slots = slots + #peripheral.call(peri, "list")
    end
  end
  return slots
end

function set_loading_indicator(enabled)
  redstone.setOutput("bottom", enabled)
end

function compile_items()
  history_print("Recompiling items...")
  set_loading_indicator(true)
  items = {}
  for i = 1, #peripheral.getNames(), 1 do
    local peri = peripheral.getNames()[i]
    if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
      local list = peripheral.call(peri, "list")
      for k, v in pairs(list) do
        local detail = peripheral.call(peri, "getItemDetail", k)
        if items[detail.name] == nil then
          items[detail.name] = {}
          items[detail.name].displayName = detail.displayName
          items[detail.name].total = detail.count
          local location = {}
          location.peripheral = peri
          location.slot = k
          location.count = detail.count
          items[detail.name].locations = {}
          table.insert(items[detail.name].locations, location)
        else
          items[detail.name].total = items[detail.name].total + detail.count
          local location = {}
          location.peripheral = peri
          location.slot = k
          location.count = detail.count
          table.insert(items[detail.name].locations, location)
        end
      end
    end
  end

  sort()
  draw_header()
  last_compiled = os.epoch("local")

  history_print("Recompiling done.")
  set_loading_indicator(false)
end

function flush()
  -- TODO: rather iterate through the request chest list instead of all other chests
  history_print("Flushing request chest...")
  set_loading_indicator(true)
  for i = 1, #peripheral.getNames(), 1 do
    local peri = peripheral.getNames()[i]
    local type = peripheral.getType(peri)
    if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
      list = peripheral.call(peri, "list")
      size = peripheral.call(peri, "size")
      for k, v in pairs(req_chest.list()) do
        req_chest.pushItems(peri, k)
      end
    end
  end
  set_loading_indicator(false)
  history_print("Flushing done.")
end

function search(name)
  results = {}
  for k in pairs(items) do
    if string.find(string.lower(items[k].displayName), string.lower(name)) then
      table.insert(results, { displayName = items[k].displayName, total = items[k].total })
    end
  end

  return results
end

function request(name, amount)
  set_loading_indicator(true)
  local item = nil
  local name = string.lower(name)
  if string.find(name, "_") then
    name = string.gsub(name, "_", " ")
  end
  history_print(name)
  for k in pairs(items) do
    if string.lower(items[k].displayName) == name then
      item = items[k]
      break
    end
  end

  if not item then
    history_print(string.format("Could not find item with name %s", name))
    set_loading_indicator(false)
    return
  end

  local amount_to_pull = math.min(item.total, amount)
  for i = 1, #item.locations, 1 do
    local loc = item.locations[i]
    if amount_to_pull > 0 and #req_chest.list() < req_chest.size() then
      local pull_amount = math.min(loc.count, amount_to_pull)
      req_chest.pullItems(loc.peripheral, loc.slot, pull_amount)
      amount_to_pull = amount_to_pull - pull_amount
    else
      break
    end
  end

  set_loading_indicator(false)
  compile_items()
end

function clear()
  term.clear()
  term.setCursorPos(1, 1)
end

function string_split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

function sort()
  keyset = {}

  for k, v in pairs(items) do
    table.insert(keyset, { key = k, total = v.total })
  end

  table.sort(keyset, function(t1, t2)
    return t1.total < t2.total
  end)
end

local commands = {}

commands.flush = {
  description = "Sends all item from the request chest to the storage",
  usage = "flush",
  func = function()
    flush()
    compile_items()
  end
}

commands.search = {
  description = "searched lazily for an item name.",
  usage = "search <name>",
  func = function(args)
    local res = search(args[2])
    if #res == 0 then
      history_print("No items found with name " .. args[2])
    else
      for _, v in pairs(res) do
        history_print(string.format("%s: %s", v.displayName, v.total))
      end
      last_searched_items = res
    end
  end
}

commands.help = {
  description = "shows all commands",
  usage = "help",
  func = function()
    for k, v in pairs(commands) do
      history_print(k .. " - " .. v.description .. "\nUsage: " .. v.usage .. "\n")
    end
  end
}

commands.upgrade = {
  description = "upgrades the program",
  usage = "upgrade",
  func = function()
    upgrade()
  end
}

commands.clear = {
  description = "clears the terminal",
  usage = "clear",
  func = function()
    clear()
  end
}

commands.request = {
  description = "request an item lazily",
  usage = "clear",
  func = function(args)
    request(args[2], tonumber(args[3]))
  end
}

commands.print = {
  description = "prints a message",
  usage = "print",
  func = function(args)
    history_print(args[2])
  end
}

commands.compile = {
  description = "compiles the current storage system",
  usage = "compile",
  func = function(args)
    compile_items()
  end
}

commands.list = {
  description = "Lists all items",
  usage = "list",
  func = function()
    for _, v in pairs(keyset) do
      history_print(string.format("%s: %s", items[v.key].displayName, items[v.key].total))
    end
  end
}

commands.slots = {
  description = "shows available slots and max slots",
  usage = "slots",
  func = function(args)
    local max = max_slots()
    local avail = available_slots()
    history_print(string.format("%s / %s (%.2f %%)", avail, max, (avail / max) * 100))
  end
}

function handle_input(input)
  local args = string_split(input)
  history_print("> " .. input)

  local found = false
  for k, v in pairs(commands) do
    if args[1] == k then
      -- TODO: remove first element
      v.func(args)
      found = true
    end
  end

  if not found then
    commands.help.func()
  end
end

draw_header()
local input = ""
print_input("")

if #items == 0 then
  compile_items()
end

while true do
  local eventData = { os.pullEvent() }
  local event = eventData[1]

  if event == "char" then
    input = input .. eventData[2]

    print_input(input)
  elseif event == "key" then
    if keys.getName(eventData[2]) == "enter" then
      local a = input
      input = ""
      print_input(input)
      handle_input(a)
    elseif keys.getName(eventData[2]) == "backspace" then
      input = input:sub(1, -2)
      print_input(input)
    elseif keys.getName(eventData[2]) == "up" then
      scroll(-1)
    elseif keys.getName(eventData[2]) == "down" then
      scroll(1)
    elseif keys.getName(eventData[2]) == "end" then
      term.exit()
    end
  elseif event == "mouse_scroll" then
    scroll(eventData[2])
  end
end
