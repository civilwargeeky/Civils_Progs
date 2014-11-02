--Version 1.0.2
--This program will act as a repeater between a turtle and a receiver computer
--important options are doAcceptPing and arbitraryNumber
--expected message format: {message, id, distance, fingerprint}

--Config
local doDebug = false --...
local arbitraryNumber = 100 --How many messages to keep between deletions
local saveFile = "QuarryRepeaterSave"
local expectedFingerprints = {quarry = true, quarryReceiver = true}
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
  return math.random(1,2000000000) --1 through 2 billion; close enough 
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
  file.writeLine(textutils.serialize(channels):gsub("[\n\r]",""))
  file.writeLine(counter)
  return file.close()
end
local function openChannels()
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
  channels = textutils.unserialize(file.readLine()) or (print("Channels could not be read") and {})
  counter = tonumber(file.readLine()) or (print("Counter could not be read") and 0)
  print("Done reading save file")
  file.close()
end

while not modem do
  modem = peripheral.find("modem")
  if modem then break end
  print("Please attach a modem")
  os.pullEvent("peripheral")
end

for i=1, #channels do
  debug("Opening ",channels[i])
  modem.open(channels[i])
end

local continue = true
while continue do
  print("\nHit 'q' to quit, 'r' to remove channels, 'p' to ping or any other key to add channels")
  local event, key, receivedFreq, replyFreq, received, dist = os.pullEvent()
  term.clear()
  term.setCursorPos(1,1)
  if event == "modem_message" then
    print("Modem Message Received")
    if acceptLegacy and type(received) ~= "table" then
      debug("Unformatted message, formatting for quarry")
      received = { message = received, id = newID(), distance = 0, fingerprint = "quarry"}
    end
    
    debug("Message Properties")
    for a, b in pairs(received) do
      debug(a,"   ",b)
    end
    
    if expectedFingerprints[received.fingerprint] and not sentMessages[received.id] then --A regular expected message
      if received.distance then
        received.distance = received.distance + dist --Add on to repeater how far message had to go
      else
        received.distance = dist
      end
      debug("Sending Return Message")
      modem.transmit(receivedFreq, replyFreq, received) --Send back exactly what we got
      addID(received.id)
    elseif doAcceptPing and received.fingerprint == pingFingerprint then --We got a ping!
      debug("We got a ping!")
      redstone.setOutput(pingSide, true) --Just a toggle should be fine
      sleep(1)
      redstone.setOutput(pingSide, false)
    end

    if tempCounter > arbitraryNumber then --Purge messages to save memory
      debug("Purging messages")
      sleep(0.05) --Wait a tick for no good reason
      sentMessages = {} --Completely reset table
      sentMessages[recentID] = true --Reset last message (not sure if really needed. Oh well.
      tempCounter = 0
    end
    
    print("Messages Received: "..counter)
    
  elseif event == "char" then
    if key == "q" then --Quitting
      print("Quitting")
      continue = false
    elseif key == "p" then --Ping other channels
      for a,b in pairs(channels) do --Ping all open channels
        debug("Pinging channel ",b)
        modem.transmit(b,b,{message = "I am ping! Wrar!", fingerprint = "ping"})
        sleep(1)
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
        num = tonumber(num)
        if num >= 1 and num <= 65535 then
          table.insert(channels, tonumber(num))
        end
      end
    end
    save()
    openChannels()
    
  end
end

for i=1, #channels do
  modem.close(channels[i])
end