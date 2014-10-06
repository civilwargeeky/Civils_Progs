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
screenClass.themeColors = { 
  addColor = function(self, name, text, back) --Background is optional. Will not change if nil
    self[name] = {text = text, background = back}
  end
}

do --This is how adding colors will work
  local tab = screenClass.themeColors
  tab:addColor("title", colors.green, colors.gray)
  tab:addColor("subtitle", colors.white)
  tab:addColor("pos", colors.green)
  tab:addColor("dim", colors.lightBlue)
  tab:addColor("extra", colors.lightGray)
  tab:addColor("error", colors.red, colors.white)
  tab:addColor("info", colors.blue, colors.lightGray)
  tab:addColor("inverse", colors.yellow, colors.lightGray)
  tab:addColor("command", colors.lightBlue)
  tab:addColor("help", colors.red, colors.white)
end

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
  self.toPrint = {}
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
  self:setSize() --Finish Initialization
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
screenClass.tryAdd = function(self, text, color, ...) --This will try to add text if Y dimension is a certain size
  local doAdd = {...} --booleans for small, medium, and large
  text = text or "-"
  color = color or {text = colors.white}
  for i=1, 3 do
    if doAdd[i] and screenSize[2] == i then --If should add this text for this screen size and the monitor is this size
      if #text <= self.dim[1] then
        table.insert(toPrint, {text = text, color = color})
        return true
      else
        debug("Tryed adding ",text," on line ",#self.toPrint+1," but was too long")
      end
    end
  end
  return false
end

--Copied from below, revise
screenClass.updateScreen = function(self, isDone)
  local str = tostring
  self.toPrint = {} --Reset table
  
  if not isDone then --Normally
    if self.size[1] == 1 then --Small Monitor
      if not self:tryAdd(self.rec.label, self.themeColors.title, false, false, true) then --This will be a title, basically
        self:tryAdd("Quarry!", self.themeColors.title, false, false, true)
      end
      
      self:tryAdd("-Fuel-", self.themeColors.subtitle , false, true, true)
      if not self:tryAdd(str(self.rec.fuel), nil, false, true, true) then --The fuel number may be bigger than the screen
        self:tryAdd("A lot", nil, false, true, true)
      end
      
      self:tryAdd("--%%%--", self.themeColors.subtitle, false, true, true)
      self:tryAdd(align(str(self.rec.percent).."%", 7), self.themeColors.pos , false, true, true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
      self:tryAdd(center(str(self.rec.percent).."%"), self.themeColors.pos, true) --I want it to be centered on 1x1
      
      self:tryAdd("--Pos--", self.themeColors.subtitle, false, true, true)
      self:tryAdd("X:"..align(str(self.rec.relxPos), 5), self.themeColors.pos, true, true, true)
      self:tryAdd("Z:"..align(str(self.rec.zPos), 5), self.themeColors.pos , true, true, true)
      self:tryAdd("Y:"..align(str(self.rec.layersDone), 5), self.themeColors.pos , true, true, true)
      
      if not self:tryAdd(str(self.rec.x).."x"..str(self.rec.z).."x"..str(self.rec.layers), self.themeColors.dim , true) then --If you can't display the y, then don't
        self:tryAdd(str(self.rec.x).."x"..str(self.rec.z), self.themeColors.dim , true)
      end
      self:tryAdd("--Dim--", self.themeColors.subtitle, false, true, true)
      self:tryAdd("X:"..align(str(self.rec.x), 5), self.themeColors.dim, false, true, true)
      self:tryAdd("Z:"..align(str(self.rec.z), 5), self.themeColors.dim, false, true, true)
      self:tryAdd("Y:"..align(str(self.rec.layers), 5), self.themeColors.dim, false, true, true)
      
      self:tryAdd("-Extra-", self.themeColors.subtitle, false, false, true)
      self:tryAdd(align(textutils.formatTime(os.time()):gsub(" ","").."", 7), self.themeColors.extra, false, false, true) --Adds the current time, formatted, without spaces.
      self:tryAdd("Open:"..align(str(self.rec.openSlots),2), self.themeColors.extra, false, false, true)
      self:tryAdd("Dug"..align(str(self.rec.mined), 4), self.themeColors.extra, false, false, true)
      self:tryAdd("Mvd"..align(str(self.rec.moved), 4), self.themeColors.extra, false, false, true)
      if self.rec.chestFull then
        self:tryAdd("ChstFll", self.themeColors.error, false, false, true)
      end
      
    end
    if self.size[1] == 2 then --Medium Monitor
      if not self:tryAdd(self.rec.label, self.themeColors.title, false, false, true) then --This will be a title, basically
        self:tryAdd("Quarry!", self.themeColors.title, false, false, true)
      end
      
      self:tryAdd("-------Fuel-------", self.themeColors.subtitle , false, true, true)
      if not self:tryAdd(str(self.rec.fuel), nil, false, true, true) then --The fuel number may be bigger than the screen
        toPrint[#toPrint] = nil
        self:tryAdd("A lot", nil, false, true, true)
      end
      
      self:tryAdd(str(self.rec.percent).."% Complete", self.themeColors.pos , true, true, true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
      
      self:tryAdd("-------Pos--------", self.themeColors.subtitle, false, true, true)
      self:tryAdd("X Coordinate:"..align(str(self.rec.relxPos), 5), self.themeColors.pos, true, true, true)
      self:tryAdd("Z Coordinate:"..align(str(self.rec.zPos), 5), self.themeColors.pos , true, true, true)
      self:tryAdd("On Layer:"..align(str(self.rec.layersDone), 9), self.themeColors.pos , true, true, true)
      
      if not self:tryAdd("Size: "..str(self.rec.x).."x"..str(self.rec.z).."x"..str(self.rec.layers), self.themeColors.dim , true) then --This is already here... I may as well give an alternative for those people with 1000^3quarries
        self:tryAdd(str(self.rec.x).."x"..str(self.rec.z).."x"..str(self.rec.layers), self.themeColors.dim , true)
      end
      self:tryAdd("-------Dim--------", self.themeColors.subtitle, false, true, true)
      self:tryAdd("Total X:"..align(str(self.rec.x), 10), self.themeColors.dim, false, true, true)
      self:tryAdd("Total Z:"..align(str(self.rec.z), 10), self.themeColors.dim, false, true, true)
      self:tryAdd("Total Layers:"..align(str(self.rec.layers), 5), self.themeColors.dim, false, true, true)
      self:tryAdd("Volume"..align(str(self.rec.volume),12), self.themeColors.dim, false, false, true)
      
      self:tryAdd("------Extras------", self.themeColors.subtitle, false, false, true)
      self:tryAdd("Time: "..align(textutils.formatTime(os.time()):gsub(" ","").."", 12), self.themeColors.extra, false, false, true) --Adds the current time, formatted, without spaces.
      self:tryAdd("Used Slots:"..align(str(16-self.rec.openSlots),7), self.themeColors.extra, false, false, true)
      self:tryAdd("Blocks Mined:"..align(str(self.rec.mined), 5), self.themeColors.extra, false, false, true)
      self:tryAdd("Spaces Moved:"..align(str(self.rec.moved), 5), self.themeColors.extra, false, false, true)
      if self.rec.chestFull then
        self:tryAdd("Chest Full, Fix It", self.themeColors.error, false, true, true)
      end
    end
    if self.size[1] >= 3 then --Large or larger screens
      if not self:tryAdd(self.rec.label..align(" Turtle #"..str(self.rec.id),dim[1]-#self.rec.label), self.themeColors.title, true, true, true) then
        self:tryAdd("Your turtle's name is long...", self.themeColors.title, true, true, true)
      end
      self:tryAdd("Fuel: "..align(str(self.rec.fuel),dim[1]-6), nil, true, true, true)
      
      self:tryAdd("Percentage Done: "..align(str(self.rec.percent).."%",dim[1]-17), self.themeColors.pos, true, true, true)
      
      local var1 = math.max(#str(self.rec.x), #str(self.rec.z), #str(self.rec.layers))
      local var2 = (dim[1]-5-var1+3)/3
      self:tryAdd("Pos: "..align(" X:"..align(str(self.rec.relxPos),var1),var2)..align(" Z:"..align(str(self.rec.zPos),var1),var2)..align(" Y:"..align(str(self.rec.layersDone),var1),var2), self.themeColors.pos, true, true, true)
      self:tryAdd("Size:"..align(" X:"..align(str(self.rec.x),var1),var2)..align(" Z:"..align(str(self.rec.z),var1),var2)..align(" Y:"..align(str(self.rec.layers),var1),var2), self.themeColors.dim, true, true, true)
      self:tryAdd("Volume: "..str(self.rec.volume), self.themeColors.dim, false, true, true)
      self:tryAdd("",nil, false, false, true)
      self:tryAdd(center("____---- EXTRAS ----____"), self.themeColors.subtitle, false, false, true)
      self:tryAdd(center("Time:"..align(textutils.formatTime(os.time()),8)), self.themeColors.extra, false, true, true)
      self:tryAdd(center("Current Day: "..str(os.day())), self.themeColors.extra, false, false, true)
      self:tryAdd("Used Inventory Slots: "..align(str(16-self.rec.openSlots),dim[1]-22), self.themeColors.extra, false, true, true)
      self:tryAdd("Blocks Mined: "..align(str(self.rec.mined),dim[1]-14), self.themeColors.extra, false, true, true)
      self:tryAdd("Blocks Moved: "..align(str(self.rec.moved),dim[1]-14), self.themeColors.extra, false, true, true)
      self:tryAdd("Distance to Turtle: "..align(str(self.rec.distance), dim[1]-20), self.themeColors.extra, false, false, true)
      self:tryAdd("Actual Y Pos (Not Layer): "..align(str(self.rec.yPos), dim[1]-26), self.themeColors.extra, false, false, true)
      
      if self.rec.chestFull then
        self:tryAdd("Dropoff is Full, Please Fix", self.themeColors.error, false, true, true)
      end
      if self.rec.foundBedrock then
        self:tryAdd("Found Bedrock! Please Check!!", self.themeColors.error, false, true, true)
      end
      if self.rec.isAtChest then
        self:tryAdd("Turtle is at home chest", self.themeColors.info, false, true, true)
      end
      if self.rec.isGoingToNextLayer then
        self:tryAdd("Turtle is going to next layer", self.themeColors.info, false, true, true)
      end
    end
  else --If is done
    if screenSize[1] == sizesEnum.small then --Special case for small monitors
      self:tryAdd("Done", self.themeColors.title, true, true, true)
      self:tryAdd("Dug"..align(str(self.rec.mined),4), self.themeColors.pos, true, true, true)
      self:tryAdd("Fuel"..align(str(self.rec.fuel),3), self.themeColors.pos, true, true, true)
      self:tryAdd("-------", self.themeColors.subtitle, false,true,true)
      self:tryAdd("Turtle", self.themeColors.subtitle, false, true, true)
      self:tryAdd(center("is"), self.themeColors.subtitle, false, true, true)
      self:tryAdd(center("Done!"), self.themeColors.subtitle, false, true, true)
    else
      self:tryAdd("Done!", self.themeColors.title, true, true, true)
      self:tryAdd("Blocks Dug: "..str(self.rec.mined), self.themeColors.inverse, true, true, true)
      self:tryAdd("Cobble Dug: "..str(self.rec.cobble), self.themeColors.pos, false, true, true)
      self:tryAdd("Fuel Dug: "..str(self.rec.fuelblocks), self.themeColors.pos, false, true, true)
      self:tryAdd("Others Dug: "..str(self.rec.other), self.themeColors.pos, false, true, true)
      self:tryAdd("Curr Fuel: "..str(self.rec.fuel), self.themeColors.inverse, true, true, true)
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