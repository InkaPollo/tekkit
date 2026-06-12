-- Redirect to left monitor
local monitor = peripheral.wrap("left")
if not monitor then
    error("Left monitor not found!")
end
term.redirect(monitor)

-- Set text scale to 1
monitor.setTextScale(1)

-- Clear the monitor
term.clear()
term.setCursorPos(1, 1)

local args = { ... }
local input = tonumber(args[1])

if not input or (input ~= 1 and input ~= 3 and input ~= 4) then
    print("Usage: startup3 <1|3|4>")
    print("  1 - Shell only")
    print("  3 - Split 3 ways")
    print("  4 - Split 4 ways")
    return
end

if input == 1 then
    -- Option 1: Plain shell with text scale 1
    monitor.setTextScale(1)
    shell.run("shell")

elseif input == 3 then
    -- Option 3: Split 3 ways with programs
    monitor.setTextScale(0.5)
    shell.run("split_arg", "3", "clock_split", "iPod", "reactor")
    
elseif input == 4 then
    -- Option 4: Split 4 ways with programs
    monitor.setTextScale(0.5)
    shell.run("split_arg", "4", "clock_split", "iPod", "reactor")
end
