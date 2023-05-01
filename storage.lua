req_chest = peripheral.wrap("reinfchest:diamond_chest_11")

-- for i = 1, req_chest.size(), 1 do
--    local item = req_chest.list()[i]
--    if item then
--      print(item.name .. " " .. item.count)
--    end
--end

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
    term.setCursorPos(1,1)
end

while true do
    input = read()
    if input == "pullAll" then
        pullAll()
    elseif input == "flush" then
        flush()
    elseif input == "search" then
        local res = search("cobble")
        for k, v in pairs(res) do
            print(string.format("found %s in %s", "cobble", v.peripheral))
        end
    elseif input == "clear" then
        clear()
    elseif input == "request" then
        request("cobble", 32)
    end
end
