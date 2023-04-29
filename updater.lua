
local templ = "https://raw.githubusercontent.com/MSpreckels/cc-smartstorage/master/%s.lua"

local remote_addresses = {
    "gui",
    "element",
}

for _,name in remote_addresses do
    local url = string.format(templ, name)
    local filename = string.format("%s.lua", name)
    if http.checkURL(url) then
        local res = http.get(url)
        res = res.readAll()
        
        fs.delete(filename)
        local file = fs.open(filename, "w")
        file.write(res)
        file.close()

        shell.run("gui")
    else
        print("Cannot pull remote_address")
        return
    end
end
