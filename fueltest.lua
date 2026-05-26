local chamber = peripheral.wrap("ic2:reactor chamber_1")

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%dh %02dm %02ds", h, m, s)
end

print("Testing Fuel Time Extraction...")
local foundFuel = false

for i = 1, chamber.size() do
    local item = chamber.getItemMeta(i)
    
    if item and item.displayName then
        local nameStr = string.lower(item.displayName)
        
        -- Specifically target your EnderPearl quad cells
        if string.find(nameStr, "enderpearl") then
            local currentDamage = item.damage or 0
            local maxDamage = item.maxDamage or 0
            
            -- If the mod reports max as 0, assume 10000 seconds
            if maxDamage == 0 then 
                maxDamage = 10000 
            end
            
            local timeLeft = maxDamage - currentDamage
            
            print("\n--- FOUND FUEL (Slot " .. i .. ") ---")
            print("Name: " .. item.displayName)
            print("Raw Damage: " .. currentDamage .. " / " .. maxDamage)
            print("Time Remaining: " .. formatTime(timeLeft))
            
            foundFuel = true
        end
    end
end

if not foundFuel then
    print("Could not find the EnderPearl cell.")
end
