
local templ = "https://raw.githubusercontent.com/MSpreckels/cc-smartstorage/master/%s.lua"

local remote_addresses = {
    "gui",
    "element",
    "inputfield"
}

for _,name in pairs(remote_addresses) do
    print(string.format("loading %s...", name))
    local url = string.format(templ, name)
    local filename = string.format("%s.lua", name)
    if http.checkURL(url) then
        local res = http.get(url)
        res = res.readAll()
        
        fs.delete(filename)
        local file = fs.open(filename, "w")
        file.write(res)
        file.close()
        print(string.format("loading %s done.", name))

    else
        print("Cannot pull remote_address")
        return
    end
end

shell.run("gui")

