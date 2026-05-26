-- CONFIGURATION
local channel = 55               
local reactorAName = "ic2:reactor chamber_1" 
local reactorBName = "ic2:reactor chamber_2" -- Update to match your second reactor!

-- INITIALIZATION
local modem = peripheral.find("modem", function(name, m) return m.isWireless() end) 
local chamberA = peripheral.wrap(reactorAName) or error("Reactor 1 disconnected")
local chamberB = peripheral.wrap(reactorBName) or error("Reactor 2 disconnected")

print("Ender Transmitter Online. Broadcasting on Channel " .. channel)

-- THE EXTRACTION FUNCTION
local function extractStats(chamber)
    -- Reach through the chamber to get the actual reactor core
    local core = chamber.getReactorCore()
    
    -- Pull the core's massive metadata dictionary
    local fullData = core.getMetadata()
    
    -- Isolate the 'reactor' table you found
    local rData = fullData.reactor or {}
    
    -- Grab the exact variables
    local currentEU = rData.euOutput or 0
    
    return {
        active = (currentEU > 0),
        heat = rData.heat or 0,
        maxHeat = rData.maxHeat or 10000,
        eu = currentEU
    }
end

-- THE BROADCAST LOOP
while true do
    local payload = {
        type = "reactor_telemetry",
        coreA = extractStats(chamberA),
        coreB = extractStats(chamberB)
    }
    
    modem.transmit(channel, channel, payload)
    sleep(0.5) 
end
