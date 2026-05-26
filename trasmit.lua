-- CONFIGURATION
local channel = 55               
local reactorAName = "ic2:reactor chamber_1" 
local reactorBName = "ic2:reactor chamber_2" -- Update this to match your second reactor!

-- WRAP PERIPHERALS
local modem = peripheral.find("modem", function(name, m) return m.isWireless() end) 
local chamberA = peripheral.wrap(reactorAName) or error("Reactor A cable disconnected")
local chamberB = peripheral.wrap(reactorBName) or error("Reactor B cable disconnected")

print("Ender Modem Transmitter Online.")
print("Broadcasting Dual-Core Data on Channel " .. channel)

-- Helper function to dig into the hidden Metadata table
local function extractStats(chamber)
    -- 1. Ask the chamber for the main core object
    local core = chamber.getReactorCore()
    -- 2. Ask the core for its hidden metadata table
    local data = core.getMetadata()
    -- 3. Isolate the specific reactor stats
    local stats = data.reactor or data
    
    return {
        active = stats.active or false,
        heat = stats.heat or 0,
        maxHeat = stats.maxHeat or 10000,
        -- The API uses euOut or energyOutput depending on the exact sub-version
        eu = stats.euOut or stats.energyOutput or 0
    }
end

while true do
    -- Package the extracted data into our standard payload
    local payload = {
        type = "reactor_telemetry",
        coreA = extractStats(chamberA),
        coreB = extractStats(chamberB)
    }
    
    -- Transmit the payload across dimensions
    modem.transmit(channel, channel, payload)
    
    -- Send fresh data twice a second
    sleep(0.5) 
end
