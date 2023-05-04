local history = {}
local texts = {}
local w,h = term.getSize()
local vh = h - 1

local yOff = #history - vh
local oldYOff = yOff

function history_print(v)
    table.insert(history, v)
    yOff = #history - vh
    draw()
end

function draw()
    term.clear()
    for i = yOff, vh + yOff, 1 do
        if history[i] then
            print(history[i])
        end
    end
end

-- draw()

-- while true do
--     local eventData = {os.pullEvent()}
--     local event = eventData[1]

--     if event == "mouse_scroll" then
--         yOff = yOff + eventData[2]
--         if yOff < 0 then
--             yOff = 0
--         elseif yOff + vh > #history then
--             yOff = #history - vh
--         end
        
--         if oldYOff ~= yOff then
--             draw()
--         end
        
--         oldYOff = yOff
--     end
-- end

