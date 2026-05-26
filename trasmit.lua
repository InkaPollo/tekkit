-- CONFIGURATION
local channel = 55               
-- Check your terminal to ensure these names match what printed when you clicked the wired modems!
local reactorAName = "nuclear_reactor_0" 
local reactorBName = "nuclear_reactor_1" 

-- WRAP PERIPHERALS
-- This automatically finds the Ender Modem regardless of what side it is on
local modem = peripheral.find("modem", function(name, m) return m.isWireless() end) 
local reactorA = peripheral.wrap(reactorAName) or error("Reactor A cable disconnected")
local reactorB = peripheral.wrap(reactorBName) or error("Reactor B cable disconnected")

print("Ender Modem Transmitter Online.")
print("Broadcasting Dual-Core Data on Channel " .. channel)

while true do
    -- Package all data into a single payload
    local payload = {
        type = "reactor_telemetry",
        coreA = {
            active = reactorA.producesEnergy(),
            heat = reactorA.getHeat(),
            maxHeat = reactorA.getMaxHeat(),
            eu = reactorA.getEUOutput()
        },
        coreB = {
            active = reactorB.producesEnergy(),
            heat = reactorB.getHeat(),
            maxHeat = reactorB.getMaxHeat(),
            eu = reactorB.getEUOutput()
        }
    }
    
    -- Transmit the payload
    modem.transmit(channel, channel, payload)
    
    -- Send fresh data twice a second
    sleep(0.5) 
end