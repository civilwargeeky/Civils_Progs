--Quarry Receiver Version 3.5.4
--Made by Civilwargeeky
--[[
Ideas:
For session persistence, you probably only need to save what monitor and what turtle to connect with.
Command sender will just be passed key or char events since it is only 1 line. That makes printing and re-printing easy
Planned layout:
  Options, General Functions and sich
  Arguments checking
  Monitor Class
    new object
    setColors
    updateScreen
    screenObject (mon.clear etc.)
    
  updateDisplay
    waits for a screen update event, then updates the respective screen.
  eventHandler
    waits for all events, queues screen events. Also queues screenChanged events for display to adjust accordingly
  commandSender
    waits for key events, prints only in caps to make life easy.
    
  Maybe just have the event handler as the only real part of the program, then have it call updateDisplay on whichever object needs to be updated with a table of values. It will also take the
    place of command sender by keeping track of characters on the home screen.
  
    
]]
--[[
Recent Changes:
  Made from scratch!
]]

local commandHelpParagraph = [[
Stop: Stops the turtle where it is
Return: The turtle will return to its starting point, drop off its load, and stop
Drop: Turtle will immediately go and drop its inventory
Pause: Pauses the turtle
Resume: Resumes paused turtles
Help: This :D
]]


--Config
local doDebug = true --For testing purposes



--Generic Functions--
local function debug(...)
  if doDebug then return print(...) end
end
local function setTextColor(color, obj)
  obj = obj or mon
  if color and obj.isColor() then
    currTextColor = color
    return obj.setTextColor(color)
  end
end
local function setBackgroundColor(color, obj)
  obj = obj or mon
  if color and obj.isColor() then
    currBackgroundColor = color
    return obj.setBackgroundColor(color)
  end
end
local function swapKeyValue(tab)
  for a,b in pairs(tab) do
    tab[b] = a
  end
  return tab
end
local function copyTable(tab)
  local toRet = {}
  for a,b in pairs(tab) do
    toRet[a] = b
  end
  return toRet
end
local function checkChannel(num)
  num = tonumber(num)
  if 1 <= num and num <= 65535 then
    return num
  end
end
local function align(text, xDim)
  text = tostring(text) or ""
  if #text >= xDim then return text end
  for i=1, xDim-#text do
    text = " "..text
  end
  return text
end
local function center(text, xDim)
  xDim = xDim or dim[1] --Temp fix
  local a = (xDim-#text)/2
  for i=1, a do
    text = " "..text.." "
  end
  return text  
end


local screenClass = {} --This is the class for all monitor/screen objects
screenClass.screens = {} --A simply numbered list of screens
screenClass.sides = {} --A mapping of screens by their side attached
screenClass.channels = {} --A mapping of receiving channels that have screens attached. Used for the receiver part
screenClass.sizes = {{7,18,29,39,50}, (5,12,19} , computer = {51, 19}, turtle = {39,13}, pocket = {26,20}}

screenClass.new = function(side, receive, send)
  local self = {}
  setmetatable(obj, {__index = screenClass}) --Establish Hierarchy
  self.side = side
  self.term = peripheral.wrap(side)
  if not (self.term and peripheral.getType(side) == "monitor") then
    error("No monitor on side "..tostring(side))
  end
  --Channels and ids
  self.receive = receive --Receive Channel
  self.send = send --Reply Channel
  self.id = #screenClass.screens+1
  --Colors
  self.textColor = colors.white
  self.backColor = colors.black
  self.isColor = self.term.isColor() --Just for convenience
  --Other Screen Properties
  self.dim = {self.term.getSize()} --Raw dimensions
  --Initializations
  self.isDone = false --Flag for when the turtle is done transmitting
  self.size = {} --Screen Size, assigned in setSize
  self.isComputer = false
  self.isTurtle = false
  self.isPocket = false
  self.acceptsInput = false
  self.rec = { --Initial values for all displayed numbers
    label = "Quarry Bot",
    id = 1, 
    percent = 0,
    relxPos = 0,
    zPos = 0,
    layersDone = 0,
    x = 0,
    z = 0,
    layers = 0,
    openSlots = 0,
    mined = 0,
    moved = 0,
    chestFull = false,
    isAtChest = false,
    isGoingToNextLayer = false,
    foundBedrock = false,
    fuel = 0,
    volume = 0,
    distance = 0,
    yPos = 0
    --Maybe add in some things like if going to then add a field
  }
  
  screenClass.screens[self.id] = self
  screenClass.sides[self.side] = self
  screenClass.channels[self.receive] = self --If anyone ever asked, you could have multiple screens per channel, but its silly if no one ever needs it
  self.setSize() --Finish Initialization
  return self
end

screenClass.removeEntry = function(tab) --Cleanup function
  if type(id) == "number" then --Expects table, can take id
    tab = screenClass.screens[id]
  end
  screenClass.screens[tab.id] = "REMOVED" --Not nil because screw up len()
  screenClass.sides[tab.side] = nil
  screenClass.channels[tab.receive] = nil
end

screenClass.setSize = function(self)
  if not self.term.setCursorPos() then --If peripheral is having problems/not there
    self.updateScreen = function() end --Do nothing on screen update, overrides class
  else --This just allows for class inheritance
    self.updateScreen = nil --Remove function in case it exists, defaults to super
  end
  local tab = screenClass.sizes
  for a=1, 2 do --Want x and y dim
    for b=1, #tab[a] do --Go through all normal sizes, x and y individually
      if tab[a][b] <= self.dim[a] then --This will set size higher until false
        self.size[a] = b
      end
    end
  end
  local function isThing(toCheck, thing) --E.G. isThing(self.dim,"computer")
    return toCheck[1] == tab[thing][1] and toCheck[2] == tab[thing][2]
  end
  self.isComputer = isThing(self.dim, "computer")
  self.isTurtle = isThing(self.dim, "turtle")
  self.isPocket = isThing(self.dim, "pocket")
  self.acceptsInput = self.isComputer or self.isTurtle or self.isPocket
end

--Copied from below, revise
screenClass.tryAdd = function(text, color, ...) --This will try to add text if Y dimension is a certain size
  local doAdd = {...} --booleans for small, medium, and large
  local added = false
  text = text or "-"
  color = color or {text = colors.white}
  for i=1, 3 do
    if doAdd[i] and screenSize[2] == i then --If should add this text for this screen size and the monitor is this size
      table.insert(toPrint, {text = text, color = color})
      added = true
    end
  end
  if not added then return true end --This is so I won't remove elements that haven't been added.
  if #text > dim[1] then return false else return true end
end

screenClass.updateScreen = function(self)
  
  local str = tostring
  local pos = {self.term.getCursorPos()}--Record pos so it can be reset
  local toPrint = {} --Reset table
  if not isDone then --Normally
    if screenSize[1] == sizesEnum.small then
      if not tryAdd(rec.label, typeColors.title, false, false, true) then --This will be a title, basically
        toPrint[#toPrint] = nil
        tryAdd("Quarry!", typeColors.title, false, false, true)
      end
      
      tryAdd("-Fuel-", typeColors.subtitle , false, true, true)
      if not tryAdd(str(rec.fuel), nil, false, true, true) then --The fuel number may be bigger than the screen
        toPrint[#toPrint] = nil
        tryAdd("A lot", nil, false, true, true)
      end
      
      tryAdd("--%%%--", typeColors.subtitle, false, true, true)
      tryAdd(align(str(rec.percent).."%", 7), typeColors.pos , false, true, true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
      tryAdd(center(str(rec.percent).."%"), typeColors.pos, true) --I want it to be centered on 1x1
      
      tryAdd("--Pos--", typeColors.subtitle, false, true, true)
      tryAdd("X:"..align(str(rec.relxPos), 5), typeColors.pos, true, true, true)
      tryAdd("Z:"..align(str(rec.zPos), 5), typeColors.pos , true, true, true)
      tryAdd("Y:"..align(str(rec.layersDone), 5), typeColors.pos , true, true, true)
      
      if not tryAdd(str(rec.x).."x"..str(rec.z).."x"..str(rec.layers), typeColors.dim , true) then --If you can't display the y, then don't
        toPrint[#toPrint] = nil --Remove element
        tryAdd(str(rec.x).."x"..str(rec.z), typeColors.dim , true)
      end
      tryAdd("--Dim--", typeColors.subtitle, false, true, true)
      tryAdd("X:"..align(str(rec.x), 5), typeColors.dim, false, true, true)
      tryAdd("Z:"..align(str(rec.z), 5), typeColors.dim, false, true, true)
      tryAdd("Y:"..align(str(rec.layers), 5), typeColors.dim, false, true, true)
      
      tryAdd("-Extra-", typeColors.subtitle, false, false, true)
      tryAdd(align(textutils.formatTime(os.time()):gsub(" ","").."", 7), typeColors.extra, false, false, true) --Adds the current time, formatted, without spaces.
      tryAdd("Open:"..align(str(rec.openSlots),2), typeColors.extra, false, false, true)
      tryAdd("Dug"..align(str(rec.mined), 4), typeColors.extra, false, false, true)
      tryAdd("Mvd"..align(str(rec.moved), 4), typeColors.extra, false, false, true)
      if rec.chestFull then
        tryAdd("ChstFll", typeColors.error, false, false, true)
      end
      
    end
    if screenSize[1] == sizesEnum.medium then
      if not tryAdd(rec.label, typeColors.title, false, false, true) then --This will be a title, basically
        toPrint[#toPrint] = nil
        tryAdd("Quarry!", typeColors.title, false, false, true)
      end
      
      tryAdd("-------Fuel-------", typeColors.subtitle , false, true, true)
      if not tryAdd(str(rec.fuel), nil, false, true, true) then --The fuel number may be bigger than the screen
        toPrint[#toPrint] = nil
        tryAdd("A lot", nil, false, true, true)
      end
      
      tryAdd(str(rec.percent).."% Complete", typeColors.pos , true, true, true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
      
      tryAdd("-------Pos--------", typeColors.subtitle, false, true, true)
      tryAdd("X Coordinate:"..align(str(rec.relxPos), 5), typeColors.pos, true, true, true)
      tryAdd("Z Coordinate:"..align(str(rec.zPos), 5), typeColors.pos , true, true, true)
      tryAdd("On Layer:"..align(str(rec.layersDone), 9), typeColors.pos , true, true, true)
      
      if not tryAdd("Size: "..str(rec.x).."x"..str(rec.z).."x"..str(rec.layers), typeColors.dim , true) then --This is already here... I may as well give an alternative for those people with 1000^3quarries
        toPrint[#toPrint] = nil --Remove element
        tryAdd(str(rec.x).."x"..str(rec.z).."x"..str(rec.layers), typeColors.dim , true)
      end
      tryAdd("-------Dim--------", typeColors.subtitle, false, true, true)
      tryAdd("Total X:"..align(str(rec.x), 10), typeColors.dim, false, true, true)
      tryAdd("Total Z:"..align(str(rec.z), 10), typeColors.dim, false, true, true)
      tryAdd("Total Layers:"..align(str(rec.layers), 5), typeColors.dim, false, true, true)
      tryAdd("Volume"..align(str(rec.volume),12), typeColors.dim, false, false, true)
      
      tryAdd("------Extras------", typeColors.subtitle, false, false, true)
      tryAdd("Time: "..align(textutils.formatTime(os.time()):gsub(" ","").."", 12), typeColors.extra, false, false, true) --Adds the current time, formatted, without spaces.
      tryAdd("Used Slots:"..align(str(16-rec.openSlots),7), typeColors.extra, false, false, true)
      tryAdd("Blocks Mined:"..align(str(rec.mined), 5), typeColors.extra, false, false, true)
      tryAdd("Spaces Moved:"..align(str(rec.moved), 5), typeColors.extra, false, false, true)
      if rec.chestFull then
        tryAdd("Chest Full, Fix It", typeColors.error, false, true, true)
      end
    end
    if screenSize[1] == sizesEnum.large then
      if not tryAdd(rec.label..align(" Turtle #"..str(rec.id),dim[1]-#rec.label), typeColors.title, true, true, true) then
        toPrint[#toPrint] = nil
        tryAdd("Your turtle's name is long...", typeColors.title, true, true, true)
      end
      tryAdd("Fuel: "..align(str(rec.fuel),dim[1]-6), nil, true, true, true)
      
      tryAdd("Percentage Done: "..align(str(rec.percent).."%",dim[1]-17), typeColors.pos, true, true, true)
      
      local var1 = math.max(#str(rec.x), #str(rec.z), #str(rec.layers))
      local var2 = (dim[1]-5-var1+3)/3
      tryAdd("Pos: "..align(" X:"..align(str(rec.relxPos),var1),var2)..align(" Z:"..align(str(rec.zPos),var1),var2)..align(" Y:"..align(str(rec.layersDone),var1),var2), typeColors.pos, true, true, true)
      tryAdd("Size:"..align(" X:"..align(str(rec.x),var1),var2)..align(" Z:"..align(str(rec.z),var1),var2)..align(" Y:"..align(str(rec.layers),var1),var2), typeColors.dim, true, true, true)
      tryAdd("Volume: "..str(rec.volume), typeColors.dim, false, true, true)
      tryAdd("",nil, false, false, true)
      tryAdd(center("____---- EXTRAS ----____"), typeColors.subtitle, false, false, true)
      tryAdd(center("Time:"..align(textutils.formatTime(os.time()),8)), typeColors.extra, false, true, true)
      tryAdd(center("Current Day: "..str(os.day())), typeColors.extra, false, false, true)
      tryAdd("Used Inventory Slots: "..align(str(16-rec.openSlots),dim[1]-22), typeColors.extra, false, true, true)
      tryAdd("Blocks Mined: "..align(str(rec.mined),dim[1]-14), typeColors.extra, false, true, true)
      tryAdd("Blocks Moved: "..align(str(rec.moved),dim[1]-14), typeColors.extra, false, true, true)
      tryAdd("Distance to Turtle: "..align(str(rec.distance), dim[1]-20), typeColors.extra, false, false, true)
      tryAdd("Actual Y Pos (Not Layer): "..align(str(rec.yPos), dim[1]-26), typeColors.extra, false, false, true)
      
      if rec.chestFull then
        tryAdd("Dropoff is Full, Please Fix", typeColors.error, false, true, true)
      end
      if rec.foundBedrock then
        tryAdd("Found Bedrock! Please Check!!", typeColors.error, false, true, true)
      end
      if rec.isAtChest then
        tryAdd("Turtle is at home chest", typeColors.info, false, true, true)
      end
      if rec.isGoingToNextLayer then
        tryAdd("Turtle is going to next layer", typeColors.info, false, true, true)
      end
    end
  else --If is done
    if screenSize[1] == sizesEnum.small then --Special case for small monitors
      tryAdd("Done", typeColors.title, true, true, true)
      tryAdd("Dug"..align(str(rec.mined),4), typeColors.pos, true, true, true)
      tryAdd("Fuel"..align(str(rec.fuel),3), typeColors.pos, true, true, true)
      tryAdd("-------", typeColors.subtitle, false,true,true)
      tryAdd("Turtle", typeColors.subtitle, false, true, true)
      tryAdd(center("is"), typeColors.subtitle, false, true, true)
      tryAdd(center("Done!"), typeColors.subtitle, false, true, true)
    else
      tryAdd("Done!", typeColors.title, true, true, true)
      tryAdd("Blocks Dug: "..str(rec.mined), typeColors.inverse, true, true, true)
      tryAdd("Cobble Dug: "..str(rec.cobble), typeColors.pos, false, true, true)
      tryAdd("Fuel Dug: "..str(rec.fuelblocks), typeColors.pos, false, true, true)
      tryAdd("Others Dug: "..str(rec.other), typeColors.pos, false, true, true)
      tryAdd("Curr Fuel: "..str(rec.fuel), typeColors.inverse, true, true, true)
    end
  end

  reset(colors.black)
  for a, b in ipairs(toPrint) do
    say(b.text, b.color)
  end
  if extraLine then
    self.term.setCursorPos(1,dim[2])
    say(extraLine[1],extraLine[2])
  end
  
end


--Initializing Variables
local sendChannel, receiveChannel
local periphSides = {monitor = nil, modem = nil}
local expectedMessage = "Civil's Quarry" --Expected initial message
local respondMessage = "Turtle Quarry Receiver" --Message to respond to  handshake with
local stopMessage = "stop"
local sides = swapKeyValue({"top","bottom","right","left","front","back"}) --This allows sides[1] and sides.front
--tArgs and peripheral list init
local tArgs = {...}
local tArgsWithUpper = swapKeyValue(copyTable(tArgs))
for a, b in pairs(tArgs) do --Lower arguments
  tArgs[a] = string.lower(b)
end
tArgs = swapKeyValue(tArgs)
local foundSides = {}
for a, b in pairs(sides) do
  if type(a) == "string" then
    foundSides[a] = peripheral.getType(a)
  end
end
foundSides = swapKeyValue(foundSides)

--Size functions
local sizes = {{7, 5}, {18, 12}, {29, 19}, 39, 50, computer = {51, 19}, turtle = {39,13}, pocket = {26,20}} --Monitor dimensions
local sizesEnum = {small = 1, medium = 2, large = 3, computer = 4, turtle = 5} --For reference
local dim, screenSize
local function setSize()
  if mon == term or not mon.getCursorPos() then --You should be able to swap out screens
    local a = peripheral.wrap(periphSides.monitor or "")
    if a then --If a is a valid monitor then
      mon = a --Monitor variable is a
    else
      mon = term --Monitor variable is just the screen variable
    end
  end
  screenSize = {}
  dim = {mon.getSize()} --Just pretend its large if it doesn't exist
  local function isX(dim, what)
    return dim[1] == sizes[what][1] and dim[2] == sizes[what][2]
  end
  screenSize.isComputer = isX(dim, "computer")
  screenSize.isTurtle = isX(dim, "turtle")
  screenSize.isPocket = isX(dim, "pocket")

  for a=1, 2 do --X and Y
    for i=3, 1, -1 do --Different sizes 1 - 3
      if dim[a] >= sizes[i][a] then --This will get decrementing screen sizes. Can even be adjusted later!
        screenSize[a] = i
        break
      end
    end
  end
  if not (screenSize[1] and screenSize[2]) then error("Screen Size was not set properly") end
  if debug then
    print("Screen Size Reset:")
    print("Size X: ",screenSize[1]," Size Y: ",screenSize[2])
    print("Dim X: ",dim[1]," Dim Y: ",dim[2])
  end
  if screenSize.isComputer or screenSize.isTurtle or screenSize.isPocket then
    screenSize.acceptsInput = true
  else
    screenSize.acceptsInput = false
  end
end

--Arguments and such
local function getNext(str)
  return tArgs[tArgs[str]+1]
end


if tArgs["-modem"] then
  if sides[getNext("-modem")] then
    periphSides["modem"] = getNext("-modem")
  end
else --This will check for a modem only if argument isn't specified
  periphSides["modem"] = foundSides["modem"]
end
for _, a in pairs({"-monitor","-screen"}) do
  if tArgs[a] then
    if sides[getNext(a)] then --Checks if the argument following monitor is a valid side
      periphSides.monitor = getNext(a)
    else
      periphSides.monitor = foundSides.monitor --This differs from above so if no argument, will default to screen.
    end
  elseif defaultCheckScreen then
    periphSides.monitor = foundSides.monitor
  end
end

if tArgs["-channel"] then
  receiveChannel = checkChannel(getNext("-channel")) --This will be nil if it doesn't exist
end

if doDebug then
  print(textutils.serialize(foundSides))
  print("Screen Side: ",periphSides.monitor)
  print("Modem Side: ",periphSides.modem)
  os.pullEvent("char")
end


--All UI, handshaking, and monitor finding go here.
term.clear()
term.setCursorPos(1,1)
print("Welcome to Quarry Receiver!")
while peripheral.getType(periphSides["modem"]) ~= "modem" do
  write("Which side is the modem on? " )
  local temp = read()
  if peripheral.getType(temp:lower()) == "modem" then --If the input side is a modem
    periphSides.modem = temp
  else print("That side does not have a modem on it \n") end
end
while not receiveChannel do
  write("What channel? (Check turtle) ")
  local temp = tonumber(read()) or 0
  if checkChannel(temp) then
    receiveChannel = temp
  end
end

--Init
local a = peripheral.wrap(periphSides.monitor or "")
if a then --If a is a valid monitor then
  mon = a --Monitor variable is a
else
  mon = term --Monitor variable is just the screen variable
end
setSize()
modem = peripheral.wrap(periphSides.modem)

if debug then
  print("Accepts Input: ",screenSize.acceptsInput)
  os.pullEvent("char")
end


--Handshake
print("Opening channel ",receiveChannel)
modem.open(receiveChannel)
print("Waiting for turtle message")
repeat
  local event, modemSide, recCheck, sendCheck, message, distance = os.pullEvent("modem_message")
  if debug then print("Message Received") end
  if (message == expectedMessage or (sloppyHandshake and textutils.unserialize(message))) and recCheck == receiveChannel and modemSide == periphSides.modem then
    sendChannel = sendCheck
    sleep(0.5) --Give it a second to catch up?
    modem.transmit(sendChannel, receiveChannel, respondMessage)
    print("Successfully paired, sending back on channel ",sendChannel)
  else
    if debug then print("Invalid message received: ",message) end
  end
  
until sendChannel --This will be assigned when message is received


--This is for testing purposes. Rec will be "receivedMessage"
--Nevermind, I actually need a default thing with keys in it.
local rec = {
  label = "Quarry Bot",
  id = 1, 
  percent = 0,
  relxPos = 0,
  zPos = 0,
  layersDone = 0,
  x = 0,
  z = 0,
  layers = 0,
  openSlots = 0,
  mined = 0,
  moved = 0,
  chestFull = false,
  isAtChest = false,
  isGoingToNextLayer = false,
  foundBedrock = false,
  fuel = 0,
  volume = 0,
  distance = 0,
  yPos = 0
--Maybe add in some things like if going to then add a field
}

--####MORE REVISIONS STARTING HERE, ABOVE IS DEAD####

local typeColors = {}
local function addColor(name, text, back) --Background is optional. Will not change if nil
  typeColors[name] = {text = text, background = back}
end

addColor("title", colors.green, colors.gray)
addColor("subtitle", colors.white)
addColor("pos", colors.green)
addColor("dim", colors.lightBlue)
addColor("extra", colors.lightGray)
addColor("error", colors.red, colors.white)
addColor("info", colors.blue, colors.lightGray)
addColor("inverse", colors.yellow, colors.lightGray)
addColor("command", colors.lightBlue)
addColor("help", colors.red, colors.white)


local function reset(color)
  setBackgroundColor(color)
  mon.clear()
  mon.setCursorPos(1,1)
end
local function say(text, color, obj)
  local currColor = currBackgroundColor
  obj, color = obj or mon, color or {}
  setTextColor(color.text, obj)
  if debug and #text > dim[1] then error("Tried printing: "..text..", but was too big") end
  setBackgroundColor(color.background, obj)
  for i=1, dim[1]-#text do --This is so the whole line's background gets filled.
    text = text.." "
  end
  obj.write(text)
  setBackgroundColor(currColor, obj)
  local pos = ({obj.getCursorPos()})[2] or setSize() or 1
  obj.setCursorPos(1, pos+1)
end

local messageToSend --This will be a command string sent to turtle

function rednetHandler() while true do sleep(0)--Super sneaky loop
--Will send rednet message to send if it exists, otherwise sends default message.
  local event, sideCheck, receiveCheck, sendCheck, message, distance
  repeat
    event, sideCheck, receiveCheck, sendCheck, message, distance = os.pullEvent()
  until (event == "modem_message" and periphSides.modem == sideCheck and receiveCheck == receiveChannel and sendCheck == sendChannel) or (event == "send_message")
  if message == stopMessage then isDone = true end --Flag for other programs
  if event == "modem_message" then
    if not isDone then --Normally
      rec = textutils.unserialize(message) or {}
      rec.distance = math.floor(distance)
      rec.label = rec.label or "Quarry!"
      if rec then
        os.queueEvent("updateScreen") --Tell display that there is new information
      else
        print("IMPROPER MESSAGE RECEIVED")
        if debug then error("expected Table, got "..message) end
      end
      
    elseif message ~= stopMessage then --If is done
      if debug then print("Received final final message") end
      modem.close(receiveChannel)
      rec = textutils.unserialize(message)
      extraLine = nil
      if rec then
        os.queueEvent("updateScreen")
      else
        error("Finished with program, but received bad message", 0)
      end
      
      print("\nDone with program")
    else --If is done, before final message
      if debug then print("Received final: ", message) end
    end
  elseif event == "send_message" then
    --pass
  end
  if not isDone then --Return message sending
    local toSend
    if messageToSend then
      toSend = messageToSend
      messageToSend = nil
    else
      toSend = respondMessage
    end
    modem.transmit(sendChannel, receiveChannel, toSend)
  end
  
end end



function commandSender() 
  local text = "Command: "
  while true do sleep(0)
    if screenSize.acceptsInput then
      extraLine = {text, typeColors.command}
      mon.setCursorPos(#extraLine[1]+1, dim[2])
    else
      extraLine = nil
      local mainDim = {term.getSize()} --Of computer
      term.setCursorPos(1, mainDim[2])
      say(text, typeColors.command, term)
      term.setCursorPos(#text+1,mainDim[2])
    end    
    messageToSend = read():lower()
    if messageToSend == "help" then
      setTextColor(typeColors.help[1], term)
      setBackgroundColor(typeColors.help[2], term)
      write(commandHelpParagraph)
      os.pullEvent("key")
    elseif messageToSend == "resume" then
     os.queueEvent("send_message")
    else  
      os.queueEvent("updateScreen")
    end
  end 
end

------------------------------------------
sleep(0.5)
parallel.waitForAny( commandSender, display, rednetHandler)