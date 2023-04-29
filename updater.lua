
local templ = "https://raw.githubusercontent.com/MSpreckels/cc-smartstorage/master/%s.lua"

local remote_addresses = {
    "gui",
    "element",
}

for addr in remote_addresses do
    local tmp = string.format(templ, addr)
    if http.checkURL(tmp) then
        local res = http.get(tmp)
        res = res.readAll()
        
        fs.delete(string.format("%s.lua", addr))
        local file = fs.open(string.format("%s.lua", addr), "w")
        file.write(res)
        file.close()

        shell.run("gui")
    else
        print("Cannot pull remote_address")
        return
    end
end
