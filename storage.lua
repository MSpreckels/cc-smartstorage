-- TODO
-- [x] help
-- [x] commands structure
-- request exact
-- group blocks with amount
-- cache items for faster delivery
-- item sort
-- smart storage (put new items where old items already are)
-- mark storage for only output and no input


require("github")
require("history")
req_chest = peripheral.wrap("minecraft:chest_0")
items = {}
last_compiled = 0

function upgrade(self)
    download("updater")
    shell.run("updater")
end

function compile_items()
    -- compile a list of all items currently in the network
    -- later: group by name and add chests with amount to it  
    for i = 1, #peripheral.getNames(), 1 do
        local peri = peripheral.getNames()[i]
        local type = peripheral.getType(peri)
        if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
            local list = peripheral.call(peri, "list")
            for k, v in pairs(list) do
                local detail = peripheral.call(peri, "getItemDetail", k)
                table.insert(items, v)
            end
        end
    end

    last_compiled = os.epoch("local")
end

function pullAll()
    --print(#peripheral.getNames())
    for i = 1, #peripheral.getNames(), 1 do
        local peri = peripheral.getNames()[i]
        local type = peripheral.getType(peri)
        --    print(type)

        if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
            local list = peripheral.call(peri, "list")
            if #list > 0 then
                for k, v in pairs(list) do
                    history_print(string.format("pulling %s from %s", v.name, peri))
                    req_chest.pullItems(peri, k)
                end
                --     print(peripheral.call(peri, "list"))
            end
        end
    end
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
    result = {}
    for i = 1, #peripheral.getNames(), 1 do
        local peri = peripheral.getNames()[i]
        local type = peripheral.getType(peri)
        if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
            local list = peripheral.call(peri, "list")
            for k, v in pairs(list) do
                local detail = peripheral.call(peri, "getItemDetail", k)
                --               print(k .. " " .. detail.displayName .. " " .. " " .. peri)
                if string.find(string.lower(detail.displayName), string.lower(name)) then
                    -- print(string.format("found %s in %s amount %s", name, peri, v.count))
                    table.insert(result, { peripheral = peri, slot = k })
                end
            end
        end
    end
    return result
end

function request(name, amount)
    local list = search(name)
    local items_pulled = 0
    for k, v in pairs(list) do
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
commands.pullAll = {
    description = "Pulls all items to the request chest",
    usage = "pullAll",
    func = function ()
        pullAll()
    end
}

commands.flush = {
    description = "Sends all item from the request chest to the storage",
    usage = "flush",
    func = function ()
        flush()
    end
}

commands.search = {
    description = "searched lazily for an item name.",
    usage = "search <name>",
    func = function (args)
        local res = search(args[2])
        for k, v in pairs(res) do
            history_print(string.format("found %s in %s", args[2], v.peripheral))
        end
    end
}

commands.help = {
    description = "shows all commands",
    usage = "help",
    func = function ()
        for k,v in pairs(commands) do
            history_print(k .. " - " .. v.description .. "\nUsage: " .. v.usage .. "\n")
        end
    end
}

commands.upgrade = {
    description = "upgrades the program",
    usage = "upgrade",
    func = function ()
        upgrade()
    end
}

commands.clear = {
    description = "clears the terminal",
    usage = "clear",
    func = function ()
        clear()
    end
}

-- TODO: change this to request exact
commands.request = {
    description = "request an item lazily",
    usage = "clear",
    func = function (args)
        request(args[2], tonumber(args[3]))
    end
}

commands.print = {
    description = "prints a message",
    usage = "print",
    func = function (args)
        history_print(args[2])
    end
}

function handle_input(input)
    local args = string_split(input)
    history_print("> " .. input)

    local found = false
    for k,v in pairs(commands) do
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

function handle_event(eventData)
    local event = eventData[1]

    if event == "mouse_scroll" then
        history_print(eventData[2])
        -- yOff = yOff + eventData[2]
        -- if yOff < 0 then
        --     yOff = 0
        -- elseif yOff + vh > #history then
        --     yOff = #history - vh
        -- end
        
        -- if oldYOff ~= yOff then
        --     draw()
        -- end
        
        -- oldYOff = yOff
    end
end

while true do
    -- parallel.waitForAny(
    --     function ()
    --         input = read()
    --         handle_input(input)
    --     end,
    --     function ()
    --         local eventData = {os.pullEvent()}
    --         handle_event(eventData)
    --     end
    -- )
    local eventData = {os.pullEvent()}
    handle_event(eventData)

end
