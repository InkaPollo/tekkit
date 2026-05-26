local chamber = peripheral.wrap("ic2:reactor chamber_1")

print("Hunting for a fuel rod...")

-- Scan every slot in the reactor
for i = 1, chamber.size() do
    local item = chamber.getItemMeta(i)
    
    if item and item.name then
        local nameStr = string.lower(item.name)
        
        -- ONLY trigger if the item's name contains uranium, mox, or fuel
        if string.find(nameStr, "uranium") or string.find(nameStr, "mox") or string.find(nameStr, "fuel") then
            print("--- FUEL ROD FOUND IN SLOT " .. i .. " ---")
            textutils.pagedPrint(textutils.serialize(item))
            break -- Stop after we print the first fuel rod
        end
    end
end
