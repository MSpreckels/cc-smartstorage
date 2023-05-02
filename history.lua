local history = {}
local texts = {}
local w,h = term.getSize()
local vh = h - 1

for i = 1, 10000, 1 do
    table.insert(texts, "Row" .. tostring(i))
end

for k,v in pairs(texts) do
    table.insert(history, v)
end

local yOff = #history - vh
local oldYOff = yOff

function draw()
    term.clear()
    for i = yOff, vh + yOff, 1 do
        print(history[i])
    end
end

draw()

while true do
    local eventData = {os.pullEvent()}
    local event = eventData[1]

    if event == "mouse_scroll" then
        yOff = yOff + eventData[2]
        if yOff < 0 then
            yOff = 0
        elseif yOff + vh > #history then
            yOff = #history - vh
        end
        
        if oldYOff ~= yOff then
            draw()
        end
        
        oldYOff = yOff
    end
end

