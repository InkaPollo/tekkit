-- CONFIGURATION
local channel = 55               
local reactorAName = "ic2:reactor chamber_1" 
local reactorBName = "ic2:reactor chamber_2" 

local modem = peripheral.find("modem", function(name, m) return m.isWireless() end) 
local chamberA = peripheral.wrap(reactorAName) or error("Reactor 1 disconnected")
local chamberB = peripheral.wrap(reactorBName) or error("Reactor 2 disconnected")

-- Your custom assumed max time (1h 23m 15s)
local assumedMaxSeconds = 4995 

print("Ender Transmitter Online. Broadcasting on Channel " .. channel)

-- Advanced Fuel Scanner
local function getFuelStats(chamber)
    if not chamber.size or not chamber.getItemMeta then return {best = nil, worst = nil} end
    
    local highestTime, highestPercent = -1, -1
    local lowestTime, lowestPercent = math.huge, math.huge
    local found = false

    for i = 1, chamber.size() do
        local item = chamber.getItemMeta(i)
        if item and item.displayName and string.find(string.lower(item.displayName), "enderpearl") then
            
            local durability = item.durability or 0
            local percentRemaining = 1.0 - durability
            local secondsRemaining = math.floor(percentRemaining * assumedMaxSeconds)
            
            if secondsRemaining > highestTime then
                highestTime = secondsRemaining
                highestPercent = percentRemaining
            end
            
            if secondsRemaining < lowestTime then
                lowestTime = secondsRemaining
                lowestPercent = percentRemaining
            end
            
            found = true
        end
    end

    if found then
        return {
            best = { percent = highestPercent, time = highestTime },
            worst = { percent = lowestPercent, time = lowestTime }
        }
    end
    return { best = nil, worst = nil }
end

local function extractStats(chamber)
    local core = chamber.getReactorCore()
    local rData = core.getMetadata().reactor or {}
    local currentEU = rData.euOutput or 0
    
    return {
        active = (currentEU > 0),
        heat = rData.heat or 0,
        maxHeat = rData.maxHeat or 10000,
        eu = currentEU,
        fuel = getFuelStats(chamber)
    }
end

while true do
    local payload = {
        type = "reactor_telemetry",
        coreA = extractStats(chamberA),
        coreB = extractStats(chamberB)
    }
    modem.transmit(channel, channel, payload)
    sleep(0.5) 
end
