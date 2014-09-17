--Version 1.0.0
--This program will act as a repeater between a turtle and a receiver computer
--[[ How it works
  First, it will startup, taking a list of channels to open in the argument
  Then it will begin waiting for messages.
  When it receives a message, it will check if the message is a table and has an id field.
  If does not have an id field it will create one, taking a random number from 1 to 2 billion.
  It checks if it has already sent this number.
  If it has not sent the number, it will add the id to two or one lists
    We could just have a list that is increasingly numbered with the ids, and go through all elements to check if sent
    Or we could have a list where [id] = true, and a numbered list. Lookups will be done on the first list, and the second will be used for periodic deletions.
  Then it will send the message along on the requested send channel.
  If it gets a char event instead of a message, it will prompt the user to add more channels to open.
  ]]
--expected message format: {message, id, distance}

--Config
local doDebug = true --...
local arbitraryNumber = 100 --How many messages to keep between deletions
local saveFile = "QuarryRepeaterSave"
local expectedFingerprint = "quarry"
local acceptLegacy = true --This will auto-format old messages that come along
--Init
local sentMessages = {} --Table of received message ids
local idMap = {} --List of random ids
local counter = 0
local channels = {} --List of channels to open listen on
local modem --The wireless modem


local function debug(...) if doDebug then return print(...) end end --Debug print

local function newID()
  return math.random(1,2000000) --1 through 2 billion; close enough 
end
local function addID(id)
    sentMessages[id] = true
    idMap[#idMap+1] =  id
    counter = counter + 1
end
local function save()
  debug("Saving File")
  local file = fs.open(saveFile, "w")
  file.write(textutils.unpack(channels))
  file.write(counter)
  return file.close()
end
local function openChannels(modem)
  for a,b in pairs(channels) do
    debug("Checking channel ",b)
    if not modem.isOpen(b) then
      debug("Opening channel ",b)
      modem.open(b)
    end
  end
end

if fs.exists(saveFile) then
  local file = fs.open(saveFile,"r")
  channels = textutils.unserialize(file:read()) or print("Channels could not be read") or {}
  counter = tonumber(file:read()) or print("Counter could not be read") or 0
  print("Done reading save file")
  file:close()
end

while not modem do
  modem = peripheral.find("modem")
  if modem then break end
  print("Please attach a modem")
  os.pullEvent("peripheral")
end

while true do
  print("\nHit 'q' to quit, 'r' to remove channels, or any other key to add channels")
  local event, key, receivedFreq, replyFreq, received, dist = os.pullEvent()
  term.clear()
  term.setCursorPos(1,1)
  if event == "modem_message" then
    print("Modem Message Received")
    if acceptLegacy and not type(received) == "table" then
      debug("Unformatted message, formatting for quarry")
      received = { message = received, id = newID(), distance = 0, fingerprint = expectedFingerprint}
    end
    
    debug("Message Properties")
    for a, b in pairs(received) do
      debug(a,"   ",b)
    end
    
    if received.fingerprint == expectedFingerprint then --Normal, expected message
      received.distance = received.distance + dist --Add on to repeater how far message had to go
      debug("Sending Return Message")
      modem.transmit(receivedFreq, replyFreq, received) --Send back exactly what we got
      addID(received.id)
    end

    if #idMap > arbitraryNumber then --Purge messages to save memory
      debug("Purging messages")
      for i=#idMap, 2, -1 do --Save one ID for most recent message
        sentMessages[idMap[i]] = nil
        idMap[i] = nil
      end
    end
    
    print("Messages Received: "..counter)
    
  elseif event == "char" then
    if key == "q" then --Quitting
      error("Quitting",0)
    elseif key == "c" then --Removing Channels
      print("Enter a comma seperated list of channels to remove")
      local str = "" --Concantenate all the channels into one, maybe restructure this for sorting?
      for i=1,#channels do
        str = str..tostring(channels[i])..", "
      end
      print("Channels: ",str:sub(1,-2)) --Sub for removing comma and space
      local input = io.read()
      local toRemove = {} --We have to use this table because user list will not be in reverse numerical order
      for num in input:gmatch("%d+") do
        for a, b in pairs(channels) do
          if b == tonumber(num) then
            debug("Removing ",b)
            table.insert(toRemove, a, 1) --This way it will go from the back of the table
            modem.close(b)
            break --No use checking the rest of the table for this number
          end
        end
      end
      for i=1, #toRemove do --So that we arent
        table.remove(channels, toRemove[i])
      end
    else  --Adding Channels
      print("What channels would you like to open. Enter a comma-separated list\n")
      local input = io.read()
      for num in input:gmatch("%d+") do
        if num >= 1 and num <= 65535 then
          table.insert(channels, tonumber(num))
        end
      end
    end
    save()
    openChannels()
    
  end
end