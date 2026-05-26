local chamber = peripheral.wrap("ic2:reactor chamber_1")

-- Check if the commands exist
if not chamber.size or not chamber.getItemMeta then
    print("Error: Missing inventory commands.")
    return
end

local foundFuel = false
print("Scanning Reactor Inventory...\n")

-- Loop through every slot in the reactor
for i = 1, chamber.size() do
    local item = chamber.getItemMeta(i)
    
    -- If there is an item, and it has durability stats
    if item and item.name and item.maxDamage and item.damage then
        local nameStr = string.lower(item.name)
        
        -- Check if the item name contains fuel keywords
        if string.find(nameStr, "uranium") or string.find(nameStr, "mox") or string.find(nameStr, "fuel") then
            local timeLeft = item.maxDamage - item.damage
            
            print("Found: " .. item.name .. " (Slot " .. i .. ")")
            print("Time Remaining: " .. timeLeft .. " seconds")
            print("-------------------------")
            
            foundFuel = true
        end
    end
end

if not foundFuel then
    print("No valid fuel rods found, or rods do not have durability stats.")
end