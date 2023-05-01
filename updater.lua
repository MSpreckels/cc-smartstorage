require("github")

local remote_addresses = {
    "storage",
}

for _,name in pairs(remote_addresses) do
    download(name)
end

-- shell.run("gui")

