local chamber = peripheral.wrap("ic2:reactor chamber_1")

-- Assuming a standard 10,000 second fuel cycle. 
-- If Quad cells take 20,000s or 40,000s in your pack, we just change this one number!
local assumedMaxSeconds = 10000 

local function formatTime(seconds)
    -- Ensure it doesn't drop below 0 if math gets weird
    seconds = math.max(0, seconds) 
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%dh %02dm %02ds", h, m, s)
end

print("Testing live countdown math...")
local foundFuel = false

for i = 1, chamber.size() do
    local item = chamber.getItemMeta(i)
    
    if item and item.displayName then
        if string.find(string.lower(item.displayName), "enderpearl") then
            
            -- Grab the live percentage (e.g., 0.3766)
            local currentDurability = item.durability or 0
            
            -- If 0.37 is used, then 1.0 - 0.37 = 0.63 (63% remaining)
            local percentRemaining = 1.0 - currentDurability
            
            -- Multiply remaining percentage by total lifespan
            local secondsRemaining = math.floor(percentRemaining * assumedMaxSeconds)
            
            print("\n--- FUEL STATUS (Slot " .. i .. ") ---")
            print("Raw Durability: " .. currentDurability)
            print("Percentage:     " .. math.floor(percentRemaining * 100) .. "% Remaining")
            print("Time Left:      " .. formatTime(secondsRemaining))
            
            foundFuel = true
            break -- We only need to check the first one we find
        end
    end
end

if not foundFuel then
    print("Could not find the EnderPearl cell.")
end
