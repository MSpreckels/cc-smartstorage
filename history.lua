local history = {}
local texts = {}
local w, h = term.getSize()
local vh = h - 1

local outputMin = 2
local outputMax = vh

local yOff = #history - vh
local oldYOff = yOff

function print_input(input)
  term.setTextColor(colors.purple)
  term.setCursorPos(1, h)
  term.clearLine()
  term.write("> " .. input)
end

function history_print(v)
  table.insert(history, v)
  yOff = #history - vh
  draw()
end

function draw_header()
  term.setTextColor(colors.purple)
  term.setCursorPos(1, 1)
  term.clearLine()
  term.write("Storage")

  local num = string.format("%s / %s", available_slots(), max_slots())

  term.setCursorPos(w - string.len(num), 1)
  term.write(num)
end

function draw()
  term.setTextColor(colors.white)
  for i = outputMin, outputMax, 1 do
    term.setCursorPos(1, i)
    term.clearLine()

    if history[yOff + i] then
      term.write(history[yOff + i])
    end
  end

  -- for i = yOff, vh + yOff, 1 do
  --   term.setCursorPos(1, i)
  --   term.clearLine()
  --   if history[i] then
  --     term.write(history[i])
  --   end
  -- end
end

function scroll(amount)
  yOff = yOff + amount
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
