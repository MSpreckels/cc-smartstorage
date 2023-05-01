local filename_templ = "%s.lua"
local github_url = "https://raw.githubusercontent.com/MSpreckels/cc-smartstorage/master/"

function download(name)
    local filename = string.format("%s.lua", name)
    local url = github_url .. string.format(filename_templ, name)

    print(string.format("downloading %s...", name))
    local res = http.get(url)
    res = res.readAll()
 
    fs.delete(filename)
    local file = fs.open(filename, "w")
    file.write(res)
    file.close()
end