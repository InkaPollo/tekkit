local programArgs = { ... }

--tape check (Initial check removed, moved to individual functions)
-- local tape = peripheral.find("tape_drive")
-- if not tape then
--   print("This program requires a tape drive to run.")
--   return
-- end

local function helpText()
	print("Usage:")
	print(" - 'recorder' to display this help text")
	print(" - 'recorder loop' to loop a cassette tape")
  	print(" - 'recorder dl [num files] [web dir]' to write web directory to tape")
  	print(" - 'recorder file [url]' to write a single .dfpwm file to tape and label it")
  	print(" - 'recorder clear' to clear the content of the tape")
  	print(" - 'recorder dl' to display full download utility help text")
  	return
end

local function helpTextDl()
	print("Usage:")
  	print(" - 'recorder dl' to display this help text")
  	print(" - 'recorder dl [num files] [web dir]' to write web directory to tape")
  	print("directory url must contain ending forward-slash.\nFiles must be named their order number .dfpwm, ex:\n'1.dfpwm', '2.dfpwm', etc")
end

--add helpText for loop util, when more features are added.





--TAPE LOOP CONTENT------------
--Program for looping tracks

-- (Initial tape check here also removed, moved to looper function)
-- local tape = peripheral.find("tape_drive")
-- if not tape then
-- -- 	print("This program requires a tape drive to run.")
-- -- 	return
-- end

--Returns true if position 1 away is zero
local function seekNCheck()
	--tape check (moved here)
	local tape = peripheral.find("tape_drive")
	if not tape then
	  print("This program requires a tape drive to run.")
	  return
	end
	--seek 1 and check
	tape.seek(1)
	print("Seeking 1...")
	if tape.read() == 0 then
		return true
	else return false
	end
end

--Checks multiple bits into distance to make sure it is actual end of track, and not just a quiet(?) part
local function seekNCheckMultiple()
	--tape check (moved here)
	local tape = peripheral.find("tape_drive")
	if not tape then
	  print("This program requires a tape drive to run.")
	  return
	end
	for i=1,10 do
		if seekNCheck() == false then
			return false
		end
	end
	return true
end
	
-- this could be made into a more efficient algo?
local function findTapeEnd( ... )
	--tape check (moved here)
	local tape = peripheral.find("tape_drive")
	if not tape then
	  print("This program requires a tape drive to run.")
	  return
	end

	local accuracy = 100
	print("Using accuracy of " .. accuracy)

	local tapeSize = tape.getSize()
	print("Tape has size of: " .. tapeSize)
	tape.seek(-tapeSize) -- rewind tape
	local runningEnd = 0

	for i=0,tapeSize do --for every piece of the tape
	
		os.queueEvent("randomEvent") -- timeout
		os.pullEvent()				 -- prevention


		tape.seek(accuracy) --seek forward one unit (One takes too long, bigger values not as accurate)
		if tape.read() ~= 0 then --if current location is not a zero
			runningEnd = i*accuracy --Update Running runningEnd var. i * accuracy gets current location in tape
			print("End Candidate: " .. runningEnd)
		elseif seekNCheckMultiple() then --check a few spots away to see if zero as well
			return runningEnd
		--else return runningEnd --otherwise, (if 0) return runningEnd
		end --end if
	end

end

--Main Function
local function looper( ... )
	--tape check (moved here)
	local tape = peripheral.find("tape_drive")
	if not tape then
	  print("This program requires a tape drive to run.")
	  return
	end
	print("Initializing...")
	--find tape end
	print("Locating end of song...")
	local endLoc = findTapeEnd()
	
	if not endLoc then -- Handle case where findTapeEnd might return nil due to error
		printError("Could not find end of song. Aborting loop.")
		return
	end

	print("End of song at position " .. endLoc .. ", or " .. endLoc/6000 .. " seconds in\n")

	print("Starting Loop! Hold Ctrl+T to Terminate")
	while true do
		tape.seek(-tape.getSize())
		tape.play()
		print("... Playing")
		sleep(endLoc/6000)
		print("Song Ended, Restarting...")
	end

	--play tape until 
end

--END TAPE LOOP CONTENT---------------------------------





--START TAPE DL CONTENT--------------------------------
--Credit to the writers of Computronics for the bulk of wrtieTapeModified() function, see README for more info.
local function writeTapeModified(relPath)
	--check for tape drive
	local tape = peripheral.find("tape_drive")
	if not tape then
		print("This program requires a tape drive to run.")		return
	end
  local file, msg, _, y, success
  local block = 8192 --How much to read at a time

  -- if not confirm("Are you sure you want to write to this tape?") then return end
  tape.stop()
  tape.seek(-tape.getSize()) -- RE-ENABLED: Ensure writing always starts from the beginning
  tape.stop() --Just making sure

  local path = shell.resolve(relPath)
  local bytery = 0 --For the progress indicator
  local filesize = fs.getSize(path)
  print("Path: " .. path)
  file, msg = fs.open(path, "rb")
  if not fs.exists(path) then msg = "file not found" end
  if not file then
    printError("Failed to open file " .. relPath .. (msg and ": " .. tostring(msg)) or "")
    return
  end

  print("Writing...")

  _, y = term.getCursorPos()

  if filesize > tape.getSize() then
    term.setCursorPos(1, y)
    printError("Error: File is too large for tape, shortening file")
    _, y = term.getCursorPos()
    filesize = tape.getSize()
  end

  repeat
    local bytes = {}
    for i = 1, block do
      local byte = file.read()
      if not byte then break end
      bytes[#bytes + 1] = byte
    end
    if #bytes > 0 then
      if not tape.isReady() then
        io.stderr:write("\nError: Tape was removed during writing.\n")
        file.close()
        return
      end
      term.setCursorPos(1, y)
      bytery = bytery + #bytes
      term.write("Read " .. tostring(math.min(bytery, filesize)) .. " of " .. tostring(filesize) .. " bytes...")
      for i = 1, #bytes do
        tape.write(bytes[i])
      end
      sleep(0)
    end
  until not bytes or #bytes <= 0 or bytery > filesize
  file.close()
  tape.stop()
  --tape.seek(-tape.getSize()) -- This is no longer needed here as we rewind at the start
  tape.stop() --Just making sure
  print("\nDone.")
end

local function tapeDl(numParts,url)
	--check for tape drive.
	local tape = peripheral.find("tape_drive")
	if not tape then
		print("This program requires a tape drive to run.")
		return
	end

	local i = 1 --iterator

	--Main Loop
	while i <= tonumber(numParts) do
		shell.run("rm", "/tmp/temp_dl.dfpwm") -- Ensure temp file is removed before download
		shell.run("wget", "" .. url .. i .. ".dfpwm", "/tmp/temp_dl.dfpwm") --wget file
		writeTapeModified("/tmp/temp_dl.dfpwm") --write to tape
		shell.run("rm", "/tmp/temp_dl.dfpwm") -- rm temp file after use
		i = i + 1 -- i++
	end
	tape.seek(-tape.getSize()) --rewind tape
end
--END TAPE DL CONTENT----------------------------------

--ADDITIONAL: Write single file from URL and label tape
local function tapeFile(url)
	local tape = peripheral.find("tape_drive")
	if not tape then
		print("This program requires a tape drive to run.")
		return
	end

	-- Extract filename for labeling
	local filename = url:match(".*/(.*%.dfpwm)$") or "unknown_song.dfpwm"
	local tapeLabel = filename:gsub("%.dfpwm$", "")

	print("Downloading file directly to tape from: " .. url)
	print("This may take a moment...")

	-- Instead of wget, we'll use http.fetch and pipe directly to tape.write
	-- This requires the http API which is standard in CC:Tweaked
	local success, response = http.fetch(url)
	if success then
		if response.success then
			print("Download stream opened. Writing to tape...")
	local bytesWritten = 0
	local _, y = term.getCursorPos()
			local fileSize = tonumber(response.headers["content-length"] or 0)

			tape.stop()
			tape.seek(-tape.getSize()) -- Rewind to beginning
			tape.stop() -- Ensure it's stopped

			local buffer = ""
			local bufferSize = 8192 -- Match the block size from writeTapeModified

			while true do
				local chunk = response.read(bufferSize)
				if not chunk then break end

				-- Write chunk directly to tape
				for i = 1, #chunk do
					tape.write(string.byte(chunk, i))
		bytesWritten = bytesWritten + 1

					-- Progress indicator
				if bytesWritten % 1024 == 0 or (fileSize > 0 and bytesWritten >= fileSize) then
			term.setCursorPos(1, y)
					local progress = ""
					if fileSize > 0 then
						progress = string.format("%.1f%%", (bytesWritten / fileSize) * 100)
	else
						progress = string.format("%d KB", math.floor(bytesWritten / 1024))
	end
					term.write("Streamed " .. progress .. " to tape...")
					sleep(0)
	end
end
			end

			tape.stop() -- Stop after writing
			tape.seek(-tape.getSize()) -- Rewind to end

			if tape.setLabel then
				tape.setLabel(tapeLabel)
				print("\nTape labeled: '" .. tapeLabel .. "'")
			else
				print("\nWarning: Tape drive does not support labeling. (Computronics v1.6.5+ required)")
			end
			print("Stream complete. Tape rewound. Done!")
		else
			printError("Download failed: Server responded with error: " .. tostring(response.status))
			printError("Check URL and network connection.")
		end
	else
		printError("Download failed: Could not open URL.")
		printError("Check URL and network connection. Ensure http API is available.")
	end
end

-- Function to clear the tape
local function clearTape()
	local tape = peripheral.find("tape_drive")
	if not tape then
		print("This program requires a tape drive to run.")
		return
	end

	print("Clearing entire tape content. This may take a while for large tapes...")
	tape.stop()
	tape.seek(-tape.getSize()) -- Rewind to the very beginning
	
	local tapeSize = tape.getSize()
	local bytesWritten = 0
	local _, y = term.getCursorPos()

	for i = 1, tapeSize do
		tape.write(0) -- Write a single zero-byte (silence)
		bytesWritten = bytesWritten + 1

		-- Update progress indicator
		if i % 1024 == 0 or i == tapeSize then -- Update every 1KB or at the end
			term.setCursorPos(1, y)
			term.write("Cleared " .. tostring(math.floor(bytesWritten / 1024)) .. "KB of " .. tostring(math.floor(tapeSize / 1024)) .. "KB")
			sleep(0) -- Yield to prevent timeout
		end
	
		if not tape.isReady() then
			io.stderr:write("\nError: Tape was removed during clearing.\n")
			return
		end
	end

	tape.seek(-tape.getSize()) -- Rewind again for a clean start
	print("\nEntire tape cleared and rewound. Done!")
end


--END TAPE LOOP CONTENT---------------------------------
if programArgs[1] == "loop" then
	looper()
elseif programArgs[1] == "file" then
	if programArgs[2] ~= nil then
		tapeFile(programArgs[2])
	else
		print("Usage: recorder file [url] - Please provide a URL to the .dfpwm file.")
		print("Example: recorder file https://raw.githubusercontent.com/User/Repo/main/MyCoolSong.dfpwm")
	end
elseif programArgs[1] == "dl" then
	if programArgs[2] ~= nil then
		print("running tapeDl")
		tapeDl(programArgs[2],programArgs[3])
	else helpTextDl()
	end
elseif programArgs[1] == "clear" then
	clearTape()
else
	helpText()
end

