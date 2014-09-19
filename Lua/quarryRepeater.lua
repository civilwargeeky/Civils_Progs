--Version 1.0.0
--This program will act as a repeater between a turtle and a receiver computer
--important options are doAcceptPing and arbitraryNumber
--expected message format: {message, id, distance, fingerprint}

--Config
local doDebug = true --...
local arbitraryNumber = 100 --How many messages to keep between deletions
local saveFile = "QuarryRepeaterSave"
local expectedFingerprint = "quarry"
local acceptLegacy = true --This will auto-format old messages that come along
local doAcceptPing = true --Accept pings. Can be turned off for tight quarters
local pingFingerprint = "ping"
local pingSide = "top"
--Init
local sentMessages = {} --Table of received message ids
local counter = 0
local tempCounter = 0 --How many messages since last delete
local recentID = 1 --Most recent message ID received, used for restore in delete
local channels = {} --List of channels to open listen on
local modem --The wireless modem


--Function Declarations--
local function debug(...) if doDebug then return print(...) end end --Debug print

local function newID()
  return math.random(1,2000000) --1 through 2 billion; close enough 
end
local function addID(id)
    sentMessages[id] = true
    tempCounter = tempCounter + 1
    counter = counter + 1
    recentID = id
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

--Actual Program Part Starts Here--
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
  print("\nHit 'q' to quit, 'r' to remove channels, 'p' to ping or any other key to add channels")
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
    elseif doAcceptPing and received.fingerprint == pingFingerprint then --We got a ping!
      redstone.setOutput(pingSide, not redstone.getOutput(pingSide)) --Just a toggle should be fine
    end

    if tempCounter > arbitraryNumber then --Purge messages to save memory
      debug("Purging messages")
      sleep(0.05) --Wait a tick for no good reason
      sentMessages = {} --Completely reset table
      sentMessages[recentID] = true --Reset last message (not sure if really needed. Oh well.
    end
    
    print("Messages Received: "..counter)
    
  elseif event == "char" then
    if key == "q" then --Quitting
      error("Quitting",0)
    elseif key == "p" then --Ping other channels
      for a,b in pairs(channels) do --Ping all open channels
        modem.transmit(b,b,{message = "I am ping! Wrar!", fingerprint = "ping"})
      end
    elseif key == "c" then --Removing Channels
      print("Enter a comma seperated list of channels to remove")
      local str = "" --Concantenate all the channels into one, maybe restructure this for sorting?
      for i=1,#channels do
        str = str..tostring(channels[i])..", "
      end
      print("Channels: ",str:sub(1,-2)) --Sub for removing comma and space
      local input = io.read()
      local toRemove = {} --We have to use this table because user list will not be in reverse numerical order. Because modifying while iterating is bad...
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