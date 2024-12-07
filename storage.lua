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
-- add ability to attach furnaces or other machines
-- make storage chests configurable
-- smelt command

require("github")
require("history")
req_chest = peripheral.wrap("minecraft:chest_0")
items = {}
last_searched_items = {}
last_compiled = 0
keyset = {}
is_refreshing = false
max_slots = 0
available_slots = 0
input = ""

function update(self)
  download("updater")
  shell.run("updater")
end

function set_request_chest(name)
  req_chest = peripheral.wrap(name)
end

function get_max_slots()
   return max_slots
end

function get_available_slots()
  return available_slots
end

function set_loading_indicator(enabled)
  redstone.setOutput("bottom", enabled)
end

-- Adds an item to the storage, appends the items table
function add_item(peri, item, slot_index)
  if items[item.name] == nil then
    items[item.name] = {}
    items[item.name].name = item.name
    items[item.name].displayName = item.displayName
    items[item.name].total = item.count
    local inventory = {}
    inventory.peripheral = peri
    inventory.slot = slot_index
    inventory.count = item.count
    items[item.name].inventories = {}
    table.insert(items[item.name].inventories, inventory)
  else
    items[item.name].total = items[item.name].total + item.count
    local inventory = {}
    inventory.peripheral = peri
    inventory.slot = slot_index
    inventory.count = item.count
    table.insert(items[item.name].inventories, inventory)
  end
end

function get_item(item)
  return items[item.name]
end

function remove_item(item, amount)
  items[item.name].total = items[item.name].total - amount

  if items[item.name].total <= 0 then
    items[item.name] = nil
  end
end

-- Check if peripheral is a storage chest, meaning it has chest in the name and is not the request chest
function is_storage_chest(peri)
  return peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") and string.find(peri, "chest")
end

-- Initialises the Storage. Fetch all Items in the Network and build the items table. Calculate max slots and available slots
function init()
  history_print("Init Storage..")
  max_slots = 0
  available_slots = 0
  
  for i = 1, #peripheral.getNames(), 1 do
    local peri = peripheral.getNames()[i]
    if is_storage_chest(peri) then
      local list = peripheral.call(peri, "list")
      for k, v in pairs(list) do
        add_item(peri, peripheral.call(peri, "getItemDetail", k), k)
      end

      max_slots = max_slots + peripheral.call(peri, "size")
      available_slots = available_slots + #peripheral.call(peri, "list")
    end
  end
  draw_header()
  history_print("Init Done.")
end

-- Clears the request chest and puts all items into the storage
function flush()
  history_print("Flushing request chest...")
  for i = 1, #peripheral.getNames(), 1 do
    local peri = peripheral.getNames()[i]
    if is_storage_chest(peri) then
      for k, v in pairs(req_chest.list()) do
        req_chest.pushItems(peri, k)
        if v then
          add_item(peri, v, k)
        end
      end
    end
  end
  history_print("Flushing done.")
end

-- Lazy search an item
function search(name)
  results = {}
  for k in pairs(items) do
    if string.find(string.lower(items[k].displayName), string.lower(name)) then
      table.insert(results, { displayName = items[k].displayName, total = items[k].total })
    end
  end

  return results
end

-- Request an item with amount by name
function request(name, amount)
  set_loading_indicator(true)
  local item = nil
  local name = string.lower(name)
  if string.find(name, "_") then
    name = string.gsub(name, "_", " ")
  end
  history_print(name)
  for k, v in pairs(items) do
    if string.lower(v.displayName) == name then
      item = v
      break
    end
  end

  if not item then
    history_print(string.format("Could not find item with name %s", name))
    set_loading_indicator(false)
    return
  end

  local amount_to_pull = math.min(item.total, amount)
  for i = 1, #item.inventories, 1 do
    local inv = item.inventories[i]
    if amount_to_pull > 0 and #req_chest.list() < req_chest.size() then
      local pull_amount = math.min(inv.count, amount_to_pull)
      remove_item(item, pull_amount)
      req_chest.pullItems(inv.peripheral, inv.slot, pull_amount)
      amount_to_pull = amount_to_pull - pull_amount
    else
      break
    end
  end

  set_loading_indicator(false)
end

function clear()
  term.clear()
  term.setCursorPos(1, 1)
  draw_header()
  input = ""
  print_input("")
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
  end
}

commands.search = {
  description = "lazily search for an item with name.",
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

commands.update = {
  description = "updates the program",
  usage = "update",
  func = function()
    update()
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

commands.reinit = {
  description = "compiles the current storage system",
  usage = "compile",
  func = function(args)
    init()
  end
}

commands.list = {
  description = "Lists all items",
  usage = "list",
  func = function()
    for k, v in pairs(items) do
      history_print(string.format("%s: %s", k, v.total))
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

commands.request_chest = {
  description = "sets a chest as the request chest",
  usage = "request_chest",
  func = function(args)
    set_request_chest(args[2])
    history_print(string.format("Set request chest to %s", args[2]))
  end
}

commands.debug = {
  description = "output item table",
  usage = "debug",
  func = function(args)
    for k, v in pairs(items) do
      history_print(string.format("-- %s --", k))
      history_print(string.format("Name:%s",v.displayName))
      history_print(string.format("Total:%s",v.total))
      history_print(string.format("Inventories:%s",#v.inventories))
      history_print("--------")
    end
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

clear()

if #items == 0 then
  init()
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