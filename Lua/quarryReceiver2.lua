--Quarry Receiver Version 3.4.0
--Made by Civilwargeeky
--[[
Ideas:
For session persistence, you probably only need to save what monitor and what turtle to connect with.
]]
--[[
Recent Changes:
  Made from scratch!
]]

local debug = false
local sloppyHandshake = true --If receiver can pick back up in the middle w/o handshake
local defaultCheckScreen = false --If this is true, it will automatically check for a screen around it.

local mon, modem, sendChannel, receiveChannel, isDone
local currBackgroundColor = colors.black
local currTextColor = colors.white
local function setTextColor(color)
  if mon.isColor() then
    currTextColor = color
    return mon.setTextColor(color)
  end
end
local function setBackgroundColor(color)
  if mon.isColor() then
    currBackgroundColor = color
    return mon.setBackgroundColor(color)
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

--Initializing Variables
local sendChannel, receiveChannel
local periphSides = {monitor = nil, modem = nil}
local expectedMessage = "Civil's Quarry"
local respondMessage = "Turtle Quarry Receiver"
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
local sizes = {monitor = {51, 19}, turtle = {39,13}, {7, 5}, {18, 12}, {29, 19}, 39, 50} --Monitor dimensions
local sizesEnum = {small = 1, medium = 2, large = 3, monitor = 4, turtle = 5} --For reference
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
  if dim[1] == sizes.monitor[1] and dim[2] == sizes.monitor[2] then
    screenSize.isComputer = true
  else
    screenSize.isComputer = false
  end
  if dim[1] == sizes.turtle[1] and dim[2] == sizes.turtle[2] then
    screenSize.isTurtle = true
  else 
    screenSize.isTurtle = false
  end
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

if debug then
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
  print("Is computer: ",screenSize.isComputer)
  print("Is turtle: ",screenSize.isTurtle)
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



--[[
Items to add:
+Title with computer name and number
+Dimensions of quarry
+Open space
+Current Fuel
+Percent Done
+Current position x
+Current position z
+Current number of layers done
+Number of blocks mined
+Number of blocks moved
+If going to next layer, if going back to start, if it home position.
+Any errors, like chest is full or something.
Distance to turtle might be cool
]]
--[[
Needed Fields:
label
percent
relxPos,zPos,layersDone
x, z, layers
openSlots
mined
moved
atHome
chestFull
fuel
volume
]]
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


local function reset(color)
  setBackgroundColor(color)
  mon.clear()
  mon.setCursorPos(1,1)
end
local function say(text, color, inc)
  local currColor = currBackgroundColor
  setTextColor(color.text)
  if debug and #text > dim[1] then error("Tried printing: "..text..", but was too big") end
  if color.background then setBackgroundColor(color.background) end
  for i=1, dim[1]-#text do --This is so the whole line's background gets filled.
    text = text.." "
  end
  mon.write(text)
  setBackgroundColor(currColor)
  local pos = ({mon.getCursorPos()})[2] or setSize() or 1
  mon.setCursorPos(1, pos+1)
end

local toPrint = {}
local function tryAdd(text, color, ...) --This will try to add text if Y dimension is a certain size
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
local function align(text, number)
  if #text >= number then return text end
  for i=1, number-#text do
    text = " "..text
  end
  return text
end
local function center(text)
  local a = (dim[1]-#text)/2
  for i=1, a do
    text = " "..text.." "
  end
  return text  
end

local extraLine --This is used in display and set in commandSender
function display() while true do sleep(0)
  local str = tostring
  local pos = {mon.getCursorPos()}--Record pos so it can be reset
  toPrint = {} --Reset table
  if not isDone then --Normally
    if screenSize[1] == sizesEnum.small then
      if not tryAdd(rec.label or "Quarry!", typeColors.title, false, false, true) then --This will be a title, basically
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
      if not tryAdd(rec.label or "Quarry!", typeColors.title, false, false, true) then --This will be a title, basically
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
    mon.setCursorPos(1,dim[2])
    say(extraLine[1],extraLine[2])
  end
  mon.setCursorPos(pos[1], pos[2]) --Reset pos for command sender
  
  if isDone then --Is done :D
    return true
  end
  
  while true do --I want specific events
    event = os.pullEvent() --This should wait for any event to update. Function rednet queues an event once info is set
    if event == "monitor_resize" or event == "peripheral" or event == "peripheral_detach" then
      setSize(); extraLine = nil; break
    elseif event == "updateScreen" or (debug and event == "char") then
      break
    end
  end

end end

local messageToSend --This will be a command string sent to turtle

function rednetHandler() while true do sleep(0)--Super sneaky loop
--Will send rednet message to send if it exists, otherwise sends default message.
  local event, sideCheck, receiveCheck, sendCheck, message, distance = os.pullEvent("modem_message")
  if periphSides.modem == sideCheck and receiveCheck == receiveChannel and sendCheck == sendChannel and message == stopMessage then isDone = true end --Flag for other programs
  if not isDone then --Normally
    if periphSides.modem == sideCheck and receiveCheck == receiveChannel and sendCheck == sendChannel then
      rec = textutils.unserialize(message) or {}
      rec.distance = math.floor(distance)
      if rec then
        os.queueEvent("updateScreen") --Tell display that there is new information
      else
        print("IMPROPER MESSAGE RECEIVED")
        if debug then error("expected Table, got "..message) end
      end
      
      local toSend
      if messageToSend then
        toSend = messageToSend
        messageToSend = nil
      else
        toSend = respondMessage
      end
      modem.transmit(sendChannel, receiveChannel, toSend)
    else
      print("Message was not sent on proper channel/ modem") --Maybe here do something about other channels?
      if debug then
        print("ReceiveCheck: ",receiveCheck," ReceiveChannel: ",receiveChannel)
        print("SendCheck: ",sendCheck," SendChannel: ",sendChannel)
        print("Side: ",periphSides.modem, " SideCheck: ",sideCheck)
        error("improper message received") end
    end
  elseif message ~= stopMessage then --If is done
    if debug then print("Received final final message") end
    modem.close(receiveChannel)
    rec = textutils.unserialize(message)
    if rec then
      os.queueEvent("updateScreen")
    else
      error("Finished with program, but received bad message", 0)
    end
    print("Done with program")
  else --If is done, before final message
    if debug then print("Received final: ", message) end
  end
end end



function commandSender() while true do sleep(0)
  if screenSize.isComputer or screenSize.isTurtle then
    extraLine = {"Command: ", {text = colors.lightBlue}}
    mon.setCursorPos(#extraLine[1]+1, dim[2])
    messageToSend = read()
    os.queueEvent("updateScreen") --Update Screen
  else
    extraLine = nil
  end
end end

------------------------------------------
sleep(0.5)
parallel.waitForAny( commandSender, display, rednetHandler)