local Smelter = {}
smelter.furnaces = {}

function Smelter.is_furnace(self)
    return peripheral.hasType(peri, "inventory") and string.find(peri, "furnace")
end

function Smelter.init(self)
    for i = 1, #peripheral.getNames(), 1 do
        local peri = peripheral.getNames()[i]
        if self.is_furnace(peri) then
            table.insert(self.furnaces, peri)
        end
    end
end