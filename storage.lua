require("github")
req_chest = peripheral.wrap("reinfchest:diamond_chest_11")

function upgrade(self)
    download("updater")
    shell.run("updater")
end

function pullAll()
    --print(#peripheral.getNames())
    for i = 1, #peripheral.getNames(), 1 do
        local peri = peripheral.getNames()[i]
        local type = peripheral.getType(peri)
        --    print(type)

        if peri ~= "left" and peri ~= peripheral.getName(req_chest) and peripheral.hasType(peri, "inventory") then
            local items = peripheral.call(peri, "list")
            if #items > 0 then
                for k, v in pairs(items) do
                    print(string.format("pulling %s from %s", v.name, peri))
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
                print(string.format("pushing %s to %s", v.name, peri))
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

while true do
    input = read()
    if input == "pullAll" then
        pullAll()
    elseif input == "flush" then
        flush()
    elseif input == "search" then
        local in_arr = string_split(input)   
        local res = search(in_arr[2])
        for k, v in pairs(res) do
            print(string.format("found %s in %s", in_arr[2], v.peripheral))
        end
    elseif input == "clear" then
        clear()
    elseif input == "request" then
        local in_arr = string_split(input)
        request(in_arr[2], in_arr[3])
    end
end
