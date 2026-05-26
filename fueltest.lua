local chamber = peripheral.wrap("ic2:reactor chamber_1")

-- 1 Hour, 23 Minutes, 15 Seconds
local assumedMaxSeconds = 4995 

local function formatTime(seconds)
    seconds = math.max(0, seconds) 
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%dh %02dm %02ds", h, m, s)
end

print("Scanning all rods for the longest remaining time...\n")

local longestSecondsRemaining = 0
local foundFuel = false
local bestDurability = 0
local bestSlot = 0

for i = 1, chamber.size() do
    local item = chamber.getItemMeta(i)
    
    if item and item.displayName then
        if string.find(string.lower(item.displayName), "enderpearl") then
            
            local currentDurability = item.durability or 0
            local percentRemaining = 1.0 - currentDurability
            local secondsRemaining = math.floor(percentRemaining * assumedMaxSeconds)
            
            -- If this rod has more time left than the previous ones we checked, save it!
            if secondsRemaining > longestSecondsRemaining then
                longestSecondsRemaining = secondsRemaining
                bestDurability = currentDurability
                bestSlot = i
            end
            
            foundFuel = true
        end
    end
end

if foundFuel then
    print("--- LONGEST LASTING ROD (Slot " .. bestSlot .. ") ---")
    print("Raw Durability: " .. bestDurability)
    print("Percentage:     " .. math.floor((1.0 - bestDurability) * 100) .. "% Remaining")
    print("Time Left:      " .. formatTime(longestSecondsRemaining))
else
    print("Could not find any EnderPearl cells.")
end
