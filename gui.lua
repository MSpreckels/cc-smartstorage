local GUI = {}
GUI.windows = {}
GUI.remote_address = "https://raw.githubusercontent.com/MSpreckels/cc-smartstorage/master/updater.lua"

function GUI.upgrade(self)
    if http.checkURL(GUI.remote_address) then
        local res = http.get(GUI.remote_address)
        res = res.readAll()
     
        local file = fs.open("updater.lua", "w")
        file.write(res)
        file.close()

        os.run("updater")
    else
        print("Cannot pull remote_address")
        return
    end
end

function GUI.init(self)
    local termW, termH = term.getSize()
    local root = window.create(term.current(), 1, 1, termW, termH)
    table.insert(self.windows, root)

    local rootW, rootH = root.getSize()
    local rootX, rootY = root.getPosition()

    local search = window.create(term.current(), rootX+1, rootY+1, rootW*0.5, 1)
    table.insert(self.windows, search)

    local searchX, searchY = search.getPosition()
    local list = window.create(term.current(), searchX, searchY+2, rootW*0.5, rootH*0.5)
    table.insert(self.windows, list)
end

function GUI.draw(self)

end

function GUI.run(self)
    local event = os.pullEvent()
    if event == "mouse_click" then
        
    end
end

-- GUI.upgrade()
GUI:init()

GUI:run()