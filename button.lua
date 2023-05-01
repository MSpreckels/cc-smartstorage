local button = {}
button.x = 0
button.y = 0
button.w = 0
button.h = 0

function button.new(self, x, y, w, h)
    local b = self or {}
    b.x = x
    b.y = y
    b.w = w
    b.h = h
    
    return b
end

function button.draw(self)
    for y = self.y, self.y + self.h, 1 do
        term.setCursorPos(self.x, y)
        term.setBackgroundColor(colors.red)
        term.write(string.rep(" ",self.x+self.w))
    end
end

function button.intersect(self, x,y)
    return x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h
end

return button