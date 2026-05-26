-- CONFIGURATION
local channel = 55             
local modem = peripheral.find("modem", function(name, m) return m.isWireless() end)
if not modem then error("Ender Modem missing!") end

modem.open(channel)

local running = true
local latestData = nil 

-- DYNAMIC MULTIPLEXER MATH
local function getScreen() return term.getSize() end

local function formatTime(seconds)
    seconds = math.max(0, seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%dh %02dm %02ds", h, m, s)
end

-- Custom bar drawing function supporting adjusted visual scales
local function drawProgressBar(x, y, totalWidth, current, visualMax, labelText)
    local textSpace = #labelText + 1 
    local barW = totalWidth - textSpace
    if barW < 2 then barW = 2 end 

    -- Calculate fill based on the adjusted visual maximum
    local progress = math.min(1, math.max(0, current / visualMax))
    local fillAmount = math.floor(progress * barW)
    
    -- Ensure at least 1 block of red if there is any value at all
    if current > 0 and fillAmount == 0 then fillAmount = 1 end

    term.setCursorPos(x, y)
    term.setBackgroundColor(colors.red)
    term.write(string.rep(" ", fillAmount))
    term.setBackgroundColor(colors.gray)
    term.write(string.rep(" ", barW - fillAmount))
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.write(" " .. labelText)
end

-- MAIN UI DRAWING
local function drawDashboard()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local w, h = getScreen()
    local mid = math.floor(w / 2)
    local colW = mid - 2 
    
    if not latestData then
        local txt = "Waiting for Ender Signal..."
        term.setCursorPos(math.floor(w/2 - #txt/2), math.floor(h/2))
        term.setTextColor(colors.gray)
        term.write(txt)
    else
        local a = latestData.coreA
        local b = latestData.coreB
        
        local maxEU = 8000 
        -- Visual scale adjustment for the heat bar (makes low temps visible)
        local heatVisualMax = 2500 

        -- ================= REACTOR 1 (LEFT) =================
        local startX = 2
        term.setTextColor(colors.yellow)
        term.setCursorPos(startX, 2) term.write("REACTOR 1")
        
        term.setCursorPos(startX, 3) 
        term.setTextColor(colors.white)
        term.write("Status: ")
        term.setTextColor(a.active and colors.green or colors.red)
        term.write(a.active and "ONLINE" or "OFFLINE")

        -- Heat Bar (Red)
        term.setTextColor(colors.lightGray)
        term.setCursorPos(startX, 5) term.write("Temperature:")
        local heatStrA = string.format("%d/%d C", a.heat, a.maxHeat)
        drawProgressBar(startX, 6, colW, a.heat, heatVisualMax, heatStrA)

        -- EU Bar (Red)
        term.setTextColor(colors.lightGray)
        term.setCursorPos(startX, 8) term.write("EU Output:")
        local euStrA = string.format("%d/%d", a.eu, maxEU)
        drawProgressBar(startX, 9, colW, a.eu, maxEU, euStrA)
        
        -- Fuel Timers
        if a.fuel and a.fuel.best then
            local bPct = math.floor(a.fuel.best.percent * 100)
            local wPct = math.floor(a.fuel.worst.percent * 100)
            
            -- Highest Rod (Bright White / "Bold")
            term.setCursorPos(startX, 11)
            term.setTextColor(colors.white)
            term.write(string.format("Best Rod:  %d%% | %s", bPct, formatTime(a.fuel.best.time)))
            
            -- Lowest Rod (Dim Gray)
            term.setCursorPos(startX, 12)
            term.setTextColor(colors.gray)
            term.write(string.format("Worst Rod: %d%% | %s", wPct, formatTime(a.fuel.worst.time)))
        else
            term.setCursorPos(startX, 11)
            term.setTextColor(colors.gray)
            term.write("No fuel data available.")
        end

        -- ================= REACTOR 2 (RIGHT) =================
        local rightX = mid + 2
        term.setTextColor(colors.yellow)
        term.setCursorPos(rightX, 2) term.write("REACTOR 2")
        
        term.setCursorPos(rightX, 3) 
        term.setTextColor(colors.white)
        term.write("Status: ")
        term.setTextColor(b.active and colors.green or colors.red)
        term.write(b.active and "ONLINE" or "OFFLINE")

        -- Heat Bar (Red)
        term.setTextColor(colors.lightGray)
        term.setCursorPos(rightX, 5) term.write("Temperature:")
        local heatStrB = string.format("%d/%d C", b.heat, b.maxHeat)
        drawProgressBar(rightX, 6, colW, b.heat, heatVisualMax, heatStrB)

        -- EU Bar (Red)
        term.setTextColor(colors.lightGray)
        term.setCursorPos(rightX, 8) term.write("EU Output:")
        local euStrB = string.format("%d/%d", b.eu, maxEU)
        drawProgressBar(rightX, 9, colW, b.eu, maxEU, euStrB)
        
        -- Fuel Timers
        if b.fuel and b.fuel.best then
            local bPct = math.floor(b.fuel.best.percent * 100)
            local wPct = math.floor(b.fuel.worst.percent * 100)
            
            -- Highest Rod (Bright White / "Bold")
            term.setCursorPos(rightX, 11)
            term.setTextColor(colors.white)
            term.write(string.format("Best Rod:  %d%% | %s", bPct, formatTime(b.fuel.best.time)))
            
            -- Lowest Rod (Dim Gray)
            term.setCursorPos(rightX, 12)
            term.setTextColor(colors.gray)
            term.write(string.format("Worst Rod: %d%% | %s", wPct, formatTime(b.fuel.worst.time)))
        else
            term.setCursorPos(rightX, 11)
            term.setTextColor(colors.gray)
            term.write("No fuel data available.")
        end
    end
    
    -- Draw Exit Button
    local btnTxt = "[Exit]"
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.setCursorPos(w - #btnTxt + 1, h)
    term.write(btnTxt)
    term.setBackgroundColor(colors.black)
end

drawDashboard()

-- MULTIPLEXER-SAFE EVENT LOOP
while running do
    local eventData = { os.pullEvent() }
    local event = eventData[1]
    
    if event == "modem_message" then
        local message = eventData[5]
        if type(message) == "table" and message.type == "reactor_telemetry" then
            latestData = message
            drawDashboard()
        end
        
    elseif event == "mouse_click" or event == "monitor_touch" then
        local mx, my = eventData[3], eventData[4]
        local w, h = getScreen()
        local btnTxt = "[Exit]"
        local bx = w - #btnTxt + 1
        
        if mx >= bx and mx <= w and my == h then
            running = false
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1,1)
            print("Dashboard closed.")
            break
        end
        
    elseif event == "key" and eventData[2] == keys.q then
        running = false
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        print("Dashboard closed.")
        break
    end
end
