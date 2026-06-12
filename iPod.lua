-- WRAP PERIPHERALS
local tape = peripheral.wrap("bottom") or error("No tape drive found on bottom.")
local speaker = peripheral.find("speaker") -- optional

-- STATE
local isPlaying = false
local isRewinding = false
local isFastForwarding = false
local running = true
local volume = 10
local lastTapeReady = false

-- BUTTON DEFINITIONS
local BUTTONS = {
    {label=">||",  w=5, id="playpause", row=1},
    {label="<<",   w=4, id="rewind",    row=1},
    {label=">>",   w=4, id="forward",   row=1},
    {label="V-",   w=4, id="vol_down",  row=2},
    {label="V+",   w=4, id="vol_up",    row=2},
    {label="Exit", w=6, id="quit",      row=2}
}

-- DYNAMIC MATH HELPERS
local function getScreen()
    return term.getSize()
end

local function getOffsetY()
    local tw, th = getScreen()
    local uiHeight = 11
    local offset = math.floor((th - uiHeight) / 2) + 2
    return offset < 1 and 1 or offset 
end

local function getCenteredX(totalW) 
    local tw, th = getScreen()
    local x = math.floor((tw - totalW) / 2) 
    return x < 1 and 1 or x
end

local function clearLine(y)
    local tw, th = getScreen()
    if y >= 1 and y <= th then
        term.setCursorPos(1, y)
        term.write(string.rep(" ", tw))
    end
end

local function updateAllVolume()
    local v = volume / 20
    if speaker and speaker.setVolume then speaker.setVolume(v) end
    if tape.setVolume then pcall(tape.setVolume, v) end
end

local lastClickAction = nil
local lastClickTime = 0

local function whichButton(x, y)
    for _, btn in ipairs(BUTTONS) do
        if x >= btn.x and x < btn.x + btn.w and y == btn.y then
            return btn.id
        end
    end
    return nil
end

local function getTapeState()
    if tape.isReady and tape.isReady() and tape.getState then
        return tape.getState()
    end
    return "STOPPED"
end

local function getCurrentTitle()
    local isReady = tape.isReady and tape.isReady()
    if isReady and tape.getLabel then
        local label = tape.getLabel()
        return label and label ~= "" and label or "play sumn bruh"
    end
    return "play sumn bruh"
end

-- DYNAMIC UI (Updates progress bar and time text)
local function updateDynamicUI()
    term.setBackgroundColor(colors.red)
    local tw, th = getScreen()
    local isReady = tape.isReady and tape.isReady()
    local oy = getOffsetY()
    
    -- Progress Bar Math
    local barWidth = tw - 4
    if barWidth < 10 then barWidth = 10 end
    local pos = isReady and tape.getPosition() or 0
    local len = isReady and tape.getSize() or 1
    if len <= 0 then len = 1 end
    
    local progress = math.min(1, math.max(0, pos / len))
    local fill = math.floor(progress * barWidth)
    
    if oy + 8 <= th then
        term.setCursorPos(3, oy + 8)
        term.setTextColor(colors.orange)
        term.write("[" .. string.rep("=", fill) .. string.rep(" ", barWidth - fill) .. "]")
    end
    
    -- Time Text
    if oy + 9 <= th then
        clearLine(oy + 9)
        local posSec = pos / 4096
        local lenSec = len / 4096
        local timeText = string.format("Time: %.1fs / %.1fs", posSec, lenSec)
        term.setCursorPos(getCenteredX(#timeText), oy + 9)
        term.setTextColor(colors.white)
        term.write(timeText)
    end
    
    -- Vertical Volume Bar positioned right of buttons and title
    local barHeight = 8  -- rows for vertical bar segments (reduced to fit above progress bar)
    local volFilledRows = math.ceil((volume / 20) * barHeight)
    local volX = getCenteredX(24) + 26  -- to right of title with space
    local volStartY = oy - 4  -- start above title, both dashes visible
    
    -- Top dash
    if volStartY <= th then
        term.setCursorPos(volX, volStartY)
        term.setTextColor(colors.yellow)
        term.write("-")
    end
    
    -- Vertical bar segments (fill upwards)
    for i = 1, barHeight do
        if volStartY + i <= th then
            term.setCursorPos(volX, volStartY + i)
            term.setTextColor(colors.yellow)
            if i > (barHeight - volFilledRows) then
                term.write("=")
            else
                term.write(" ")
            end
        end
    end
    
    -- Bottom dash
    if volStartY + barHeight + 1 <= th then
        term.setCursorPos(volX, volStartY + barHeight + 1)
        term.setTextColor(colors.yellow)
        term.write("-")
    end
end

-- STATIC UI (Draws titles and buttons)
local function redrawUI()
    term.setBackgroundColor(colors.red)
    term.clear()
    
    local tw, th = getScreen()
    local title2 = getCurrentTitle()
    local oy = getOffsetY()
    
    -- Titles
    if oy + 1 <= th then
        term.setTextColor(colors.yellow)
        term.setCursorPos(getCenteredX(24), oy + 1)
        term.write("InkaPollo's Media Player")
    end
    
    if oy + 2 <= th then
        term.setTextColor(colors.cyan)
        term.setCursorPos(getCenteredX(#title2), oy + 2)
        term.write(title2)
    end
    
    -- Button Layout Math
    local startX1 = getCenteredX(15) 
    local startX2 = getCenteredX(16) 
    local x1, x2 = startX1, startX2
    
    for _, btn in ipairs(BUTTONS) do
        if btn.row == 1 then
            btn.x = x1
            btn.y = oy + 4
            x1 = x1 + btn.w + 1
        else
            btn.x = x2
            btn.y = oy + 6
            x2 = x2 + btn.w + 1
        end
        
        if btn.y <= th then
            local highlight = (btn.id == "playpause" and isPlaying) or
                              (btn.id == "rewind" and isRewinding) or
                              (btn.id == "forward" and isFastForwarding)
                              
            term.setBackgroundColor(highlight and colors.orange or colors.gray)
            term.setTextColor(colors.black)
            term.setCursorPos(btn.x, btn.y)
            
            local padL = math.floor((btn.w - #btn.label) / 2)
            local padR = btn.w - #btn.label - padL
            term.write(string.rep(" ", padL) .. btn.label .. string.rep(" ", padR))
        end
    end
    
    updateDynamicUI()
end

-- ACTIONS
local function handleAction(action)
    if action == "playpause" then
        -- Toggle play state locally for immediate button feedback
        isPlaying = not isPlaying
        isRewinding = false
        isFastForwarding = false
        
        -- Send command to tape using tape methods
        if isPlaying then
            pcall(function() tape.play() end)
        else
            pcall(function() tape.stop() end)
        end

    elseif action == "rewind" then
        isRewinding = not isRewinding
        isFastForwarding = false
        pcall(function() tape.seek(-49152) end)

    elseif action == "forward" then
        isFastForwarding = not isFastForwarding
        isRewinding = false
        pcall(function() tape.seek(49152) end)

    elseif action == "vol_up" then
        volume = math.min(20, volume + 1)
        updateAllVolume()

    elseif action == "vol_down" then
        volume = math.max(1, volume - 1)
        updateAllVolume()

    elseif action == "quit" then
        running = false
        tape.stop()
        
        -- Safe cleanup
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        print("Media player exited.")
        return 
    end
    redrawUI()
end

local function handleClick(x, y)
    local action = whichButton(x, y)
    -- Debounce: ignore repeated clicks of same button within 200ms
    local currentTime = os.clock()
    if action == lastClickAction and (currentTime - lastClickTime) < 0.2 then
        return
    end
    lastClickAction = action
    lastClickTime = currentTime
    
    if action then handleAction(action) end
end

local function handleKey(key)
    if key == keys.space then handleAction("playpause")
    elseif key == keys.left then handleAction("rewind")
    elseif key == keys.right then handleAction("forward")
    elseif key == keys.up then handleAction("vol_up")
    elseif key == keys.down then handleAction("vol_down")
    end
end

local function handleChar(char)
    if char == "q" then handleAction("quit") end
end

-- INIT
updateAllVolume()
redrawUI()

-- MAIN SINGLE EVENT LOOP (compatible with split.lua multiplexer)
local updateTimer = os.startTimer(0.5)
local seekTimer = os.startTimer(0.1)
local lastState = "STOPPED"

while running do
    local ok, event, p1, p2, p3 = pcall(os.pullEvent)
    if not ok then break end  -- Graceful exit if terminated
    
    if event == "timer" then
        if p1 == updateTimer then
            -- UI update timer - refresh progress bar and time display
            local isReady = tape.isReady and tape.isReady()
            
            -- Redraw if tape ready state changed
            if isReady ~= lastTapeReady then
                lastTapeReady = isReady
                redrawUI()
            else
                -- Check if music naturally finished
                if isPlaying and isReady then
                    local pos = tape.getPosition()
                    local len = tape.getSize()
                    if pos >= len - 100 then  -- Allow small margin at the end
                        isPlaying = false
                        redrawUI()
                    else
                        updateDynamicUI()
                    end
                else
                    updateDynamicUI()
                end
            end
            updateTimer = os.startTimer(0.5)
            
        elseif p1 == seekTimer then
            -- Continuous seeking timer - handle rewind/forward
            if tape.isReady and tape.isReady() then
                if isRewinding then 
                    if tape.getPosition() > 0 then
                        tape.seek(-24576) -- Continuous rewind speed
                        updateDynamicUI() 
                    else
                        isRewinding = false
                        redrawUI()
                    end
                elseif isFastForwarding then 
                    if tape.getPosition() < tape.getSize() then
                        tape.seek(24576) -- Continuous forward speed
                        updateDynamicUI() 
                    else
                        isFastForwarding = false
                        redrawUI()
                    end
                end
            end
            seekTimer = os.startTimer(0.1)
        end
    
    elseif event == "mouse_click" or event == "monitor_touch" then
        handleClick(p2, p3)
    
    elseif event == "key" then
        handleKey(p1)
    
    elseif event == "char" and p1 == "q" then
        handleAction("quit")
    end
end
