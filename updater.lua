
local remote_address = "https://raw.githubusercontent.com/MSpreckels/cc-smartstorage/master/gui.lua"

if http.checkURL(remote_address) then
    local res = http.get(remote_address)
    res = res.readAll()
    
    os.remove("gui.lua")
    local file = fs.open("gui.lua", "w")
    file.write(res)
    file.close()

    shell.run("gui")
else
    print("Cannot pull remote_address")
    return
end