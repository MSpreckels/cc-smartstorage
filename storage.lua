-- TODO
-- [x] help
-- [x] commands structure
-- request exact
-- group blocks with amount
-- [x] cache items for faster delivery
-- item sort
-- smart sorting (put new items where old items already are)
-- mark storage for only output and no input
-- filled percentage
-- free slots

require("github")
require("history")
req_chest = peripheral.wrap("minecraft:chest_0")
items = {}
last_searched_items = {}
last_compiled = 0

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

function compile_items()
  history_print("Recompiling items...")
  redstone.setOutput("bottom", true)
  -- compile a list of all items currently in the network
  -- later: group by name and add chests with amount to it
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
          location.count = detail.count
          items[detail.name].locations = {}
          table.insert(items[detail.name].locations, location)
        else
          items[detail.name].total = items[detail.name].total + detail.count
          local location = {}
          location.peripheral = peri
          location.count = detail.count
          table.insert(items[detail.name].locations, location)
        end
      end
    end
  end

  last_compiled = os.epoch("local")

  history_print("Recompiling done.")
  redstone.setOutput("bottom", false)
end

function flush()
  for i = 1, #peripheral.getNames(), 1 do
    local peri = peripheral.getNames()[i]
    local type = peripheral.getType(peri)
    if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
      list = peripheral.call(peri, "list")
      size = peripheral.call(peri, "size")
      for k, v in pairs(req_chest.list()) do
        history_print(string.format("pushing %s to %s", v.name, peri))
        req_chest.pushItems(peri, k)
      end
    end
  end
end

function search(name)
  results = {}
  for k in pairs(items) do
    if string.find(string.lower(items[k].displayName), string.lower(name)) then
      -- print(string.format("found %s in %s amount %s", name, peri, v.count))
      table.insert(results, { displayName = items[k].displayName, total = items[k].total })
    end
  end

  return results
end

function request(name, amount)
  local items_pulled = 0
  for k, v in pairs(last_searched_items) do
    local detail = peripheral.call(v.peripheral, "getItemDetail", v.slot)

    items_pulled = items_pulled + detail.count
    req_chest.pullItems(v.peripheral, v.slot, amount)

    if items_pulled >= amount then
      break
    end
  end
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
        history_print(string.format("found %s: %s", v.displayName, v.total))
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

-- TODO: change this to request exact
commands.request = {
  description = "request an item lazily",
  usage = "clear",
  func = function(args)
    request(args[2], tonumber(args[3]))
    compile_items()
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
    for k in pairs(items) do
      history_print(string.format("%s: %s", items[k].displayName, items[k].total))
    end
  end
}

commands.list = {
  -- TODO: create command to list all items in items table
  description = "Lists all items",
  usage = "list",
  func = function()
    for k in pairs(items) do
      history_print(string.format("%s: %s", items[k].displayName, items[k].total))
    end
  end
}

commands.slots = {
  description = "shows available slots and max slots",
  usage = "slots",
  func = function(args)
    local max = max_slots()
    local avail = available_slots()
    history_print(string.format("%s / %s", avail, max))
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

if #items == 0 then
  compile_items()
end

print_input("")
local input = ""
while true do
  local eventData = { os.pullEvent() }
  local event = eventData[1]

  if event == "char" then
    input = input .. eventData[2]

    print_input(input)
  elseif event == "key" then
    if keys.getName(eventData[2]) == "enter" then
      handle_input(input)
      input = ""
      print_input(input)
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
