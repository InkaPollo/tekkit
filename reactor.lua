-- CONFIGURATION
local channel = 55             
local modem = peripheral.find("modem", function(name, m) return m.isWireless() end)
if not modem then error("Ender Modem missing!") end

modem.open(channel)

local running = true
local latestData = nil 

-- DYNAMIC MULTIPLEXER MATH
local function getScreen() return term.getSize() end

local function drawProgressBar(x, y, width, current, max, safeColor, dangerColor)
    local progress = math.min(1, math.max(0, current / max))
    local fillAmount = math.floor(progress * width)
    
    local barColor = (progress > 0.75) and dangerColor or safeColor
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(barColor)
    term.write(string.rep(" ", fillAmount))
    term.setBackgroundColor(colors.gray)
    term.write(string.rep(" ", width - fillAmount))
    term.setBackgroundColor(colors.black)
end

-- MAIN UI DRAWING
local function drawDashboard()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local w, h = getScreen()
    local mid = math.floor(w / 2)
    local colW = mid - 2 
    
    -- 1. Draw Data or Waiting Screen
    if not latestData then
        local txt = "Waiting for Ender Signal..."
        term.setCursorPos(math.floor(w/2 - #txt/2), math.floor(h/2))
        term.setTextColor(colors.gray)
        term.write(txt)
    else
        local a = latestData.coreA
        local b = latestData.coreB

        -- CORE A (LEFT)
        term.setTextColor(colors.yellow)
        term.setCursorPos(2, 2) term.write("CORE A")
        
        term.setCursorPos(2, 3) 
        term.setTextColor(a.active and colors.green or colors.red)
        term.write(a.active and "ONLINE" or "OFFLINE")

        term.setTextColor(colors.white)
        term.setCursorPos(2, 5) term.write(string.format("Heat: %d C", a.heat))
        drawProgressBar(2, 6, colW, a.heat, a.maxHeat, colors.green, colors.red)

        term.setCursorPos(2, 8) term.write(string.format("Out: %d EU", a.eu))
        drawProgressBar(2, 9, colW, a.eu, 8000, colors.cyan, colors.cyan)

        -- CORE B (RIGHT)
        local rightX = mid + 2
        term.setTextColor(colors.yellow)
        term.setCursorPos(rightX, 2) term.write("CORE B")
        
        term.setCursorPos(rightX, 3) 
        term.setTextColor(b.active and colors.green or colors.red)
        term.write(b.active and "ONLINE" or "OFFLINE")

        term.setTextColor(colors.white)
        term.setCursorPos(rightX, 5) term.write(string.format("Heat: %d C", b.heat))
        drawProgressBar(rightX, 6, colW, b.heat, b.maxHeat, colors.green, colors.red)

        term.setCursorPos(rightX, 8) term.write(string.format("Out: %d EU", b.eu))
        drawProgressBar(rightX, 9, colW, b.eu, 8000, colors.cyan, colors.cyan)
    end
    
    -- 2. Draw Exit Button (Pinned to Bottom Right)
    local btnTxt = "[Exit]"
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.setCursorPos(w - #btnTxt + 1, h)
    term.write(btnTxt)
    
    -- Reset colors for safe terminal background
    term.setBackgroundColor(colors.black)
end

-- INITIAL DRAW
drawDashboard()

-- MULTIPLEXER-SAFE EVENT LOOP
while running do
    local eventData = { os.pullEvent() }
    local event = eventData[1]
    
    -- Listen for Wireless Data
    if event == "modem_message" then
        local message = eventData[5]
        
        -- Verify this is the dual-reactor packet
        if type(message) == "table" and message.type == "reactor_telemetry" then
            latestData = message
            drawDashboard()
        end
        
    -- Listen for Screen Taps / Clicks
    elseif event == "mouse_click" or event == "monitor_touch" then
        local mx, my = eventData[3], eventData[4]
        local w, h = getScreen()
        local btnTxt = "[Exit]"
        local bx = w - #btnTxt + 1
        local by = h
        
        -- Check if the click hit the exact coordinates of the Exit button
        if mx >= bx and mx <= w and my == by then
            running = false
            -- Safe Multiplexer Cleanup
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1,1)
            print("Dashboard closed.")
            break
        end
        
    -- Listen for Keyboard fallback (Q to quit)
    elseif event == "key" then
        local key = eventData[2]
        if key == keys.q then
            running = false
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1,1)
            print("Dashboard closed.")
            break
        end
    end
end