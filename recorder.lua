local programArgs = { ... }

local function helpText()
	print("Usage:")
	print(" - 'recorder' to display this help text")
	print(" - 'recorder loop' to loop a cassette tape")
	print(" - 'recorder dl [num files] [web dir]' to write web directory to tape")
	print(" - 'recorder file [url]' to write a single .dfpwm file to tape and label it")
	print(" - 'recorder clear' to clear the content of the tape")
	print(" - 'recorder dl' to display full download utility help text")
end

local function helpTextDl()
	print("Usage:")
	print(" - 'recorder dl' to display this help text")
	print(" - 'recorder dl [num files] [web dir]' to write web directory to tape")
	directory url must contain ending forward-slash.\nFiles must be named their order number .dfpwm, ex:\n'1.dfpwm', '2.dfpwm', etc")
end

--TAPE LOOP CONTENT------------
--Program for looping tracks

--Returns true if position 1 away is zero
local function seekNCheck()
	--tape check
	local tape = peripheral.find("tape_drive")
	if not tape then
	  print("This program requires a tape drive to run.")
	  return
	end
	
	tape.seek(1)
	if tape.read() == 0 then
		return true
	else return false
	end
end

--Checks multiple bits into distance to make sure it is actual end of track, and not just a quiet(?) part
local function seekNCheckMultiple()
	--tape check
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
	--tape check
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
		end --end if
	end
end

--Main Function
local function looper( ... )
	--tape check
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
end

--END TAPE LOOP CONTENT---------------------------------

--START TAPE DL CONTENT--------------------------------
--Credit to the writers of Computronics for the bulk of writeTapeModified() function, see README for more info.
local function writeTapeModified(relPath)
	--check for tape drive
	local tape = peripheral.find("tape_drive")
	if not tape then
		print("This program requires a tape drive to run.")
		return
	end
	local file, msg, _, y, success
	local block = 8192 --How much to read at a time

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
		printError("Failed to open file " .. relPath .. (msg and ": " .. tostring(msg) or ""))
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
		-- Ensure temp file is removed before download, using a specific name to avoid conflicts
		local tempFilePath = "/tmp/temp_dl_chunk_" .. i .. ".dfpwm"
		if fs.exists(tempFilePath) then
			shell.run("rm", tempFilePath)
		end
		shell.run("wget", "" .. url .. i .. ".dfpwm", tempFilePath) --wget file
		
		-- Check if wget actually created the file and it has size
		if fs.exists(tempFilePath) and fs.getSize(tempFilePath) > 0 then
			writeTapeModified(tempFilePath) --write to tape
			shell.run("rm", tempFilePath) -- rm temp file after use
		else
			printError("Failed to download chunk " .. i .. ". Skipping.")
		end
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

	print("Attempting to download file from: " .. url)
	print("This may take a moment...")
	
	-- Use wget to download the file to temporary storage
	-- Use a filename that includes the original filename to avoid conflicts
	local tempFilePath = "/tmp/temp_dl_" .. filename 

	-- Clean up existing temp file first if it exists to prevent "file already exists" errors
	if fs.exists(tempFilePath) then
		print("Removing existing temporary file: " .. tempFilePath)
		shell.run("rm", tempFilePath)
	end

	local wget_success, wget_message = shell.run("wget", url, tempFilePath)

	if wget_success then
		-- Check if the file exists and has content
		if fs.exists(tempFilePath) and fs.getSize(tempFilePath) > 0 then
			print("Download appears successful. Writing to tape...")
			-- Now, use the existing writeTapeModified function
			writeTapeModified(tempFilePath)
			shell.run("rm", tempFilePath) -- Clean up temporary file
			tape.seek(-tape.getSize()) -- Rewind tape after writing

			if tape.setLabel then
				tape.setLabel(tapeLabel)
				print("Tape labeled: '" .. tapeLabel .. "'")
			else
				print("Warning: Tape drive does not support labeling. (Computronics v1.6.5+ required)")
			end
			print("Tape rewound. Done!")
		else
			-- File downloaded but is empty or missing after wget claimed success
			printError("Download failed: wget completed, but the downloaded file is empty or missing.")
			printError("Check the URL is a direct .dfpwm link and ensure your computer has enough free space.")
			print("Free space on computer: " .. fs.getFreeSpace(".") .. " bytes.")
			print("If space is low, try deleting files or use a computer with more storage.")
		end
	else
		-- wget itself failed
		printError("Download failed: wget command returned an error.")
		printError("Error message from wget: " .. tostring(wget_message or "unknown error"))
		printError("Possible reasons: Invalid URL, network issue, or 'wget' command not found.")
		print("Free space on computer: " .. fs.getFreeSpace(".") .. " bytes.")
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
	
	-- Reset the label
	if tape.setLabel then
		tape.setLabel("")
		print("Tape label cleared.")
	end
	
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
	print("\nDone.")
end

-- MAIN ENTRY
local arg1 = programArgs[1]
if arg1 == "loop" then
    looper()
elseif arg1 == "dl" then
    if not programArgs[2] then
        helpTextDl()
    else
        tapeDl(programArgs[2], programArgs[3])
    end
elseif arg1 == "file" then
    if not programArgs[2] then
        print("Usage: recorder file [url]")
    else
        tapeFile(programArgs[2])
    end
elseif arg1 == "clear" then
    clearTape()
else
    helpText()
end

