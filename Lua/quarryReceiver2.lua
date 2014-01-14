--Quarry Receiver Version 3.4.0
--Made by Civilwargeeky
--[[
Ideas:
For session persistence, you probably only need to save what monitor and what turtle to connect with.
]]

local debug = true

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
--All UI and monitor finding go here.


--Temp:
mon = peripheral.wrap("right")

local sizes = {monitor = {51, 19}, turtle = {39,13}, {7, 5}, {18, 12}, {29, 19}, 39, 50} --Monitor dimensions
local sizesEnum = {small = 1, medium = 2, large = 3, monitor = 4, turtle = 5} --For reference
local dim, screenSize
local function setSize()
  screenSize = {}
  dim = {mon.getSize()}
  if dim[1] == sizes.monitor[1] and dim[2] == sizes.monitor[2] then
    screenSize.isComputer = true
  end
  if dim[1] == sizes.turtle[1] and dim[2] == sizes.turtle[2] then
    screenSize.isTurtle = true
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
end




--Temp:
setSize()
print(screenSize[1])
print(screenSize[2])
print(dim[1])
print(dim[2])

--[[
Items to add:
-Title with computer name and number
+Dimensions of quarry
+Open space
+Current Fuel
+Percent Done
+Current position x
+Current position z
+Current number of layers done
+Number of blocks mined
+Number of blocks moved
-If going to next layer, if going back to start, if it home position.
-Any errors, like chest is full or something.
]]
--[[
Needed Fields:
label
percent
relXPos,zPos,layersDone
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
local rec = {
label = "Quarry Bot",
percent = 55,
relXPos = 165,
zPos = 200,
layersDone = 111,
x = 200,
z = 201,
layers = 202,
openSlots = 4,
mined = 50,
moved = 20,
chestFull = true,
fuel = 5000000000001515,
volume = 200*201*202
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


local function reset(color)
  setBackgroundColor(color)
  mon.clear()
  mon.setCursorPos(1,1)
end
local function say(text, color, inc)
  local currColor = currBackgroundColor
  setTextColor(color.text)
  if debug and #text > sizes[screenSize[1]][1] then error("Tried printing: "..text..", but was too big") end
  if color.background then setBackgroundColor(color.background) end
  for i=1, dim[1]-#text do --This is so the whole line's background gets filled.
    text = text.." "
  end
  mon.write(text)
  setBackgroundColor(currColor)
  local pos = ({mon.getCursorPos()})[2]
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
  if #text > sizes[screenSize[1]][1] then return false else return true end
end
local function align(text, number)
  if #text >= number then return text end
  for i=1, number-#text do
    text = " "..text
  end
  return text
end

function display()
  local str = tostring
  toPrint = {} --Reset table
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
    tryAdd(align(str(rec.percent).."%", 7), typeColors.pos , true, true, true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
    
    tryAdd("--Pos--", typeColors.subtitle, false, true, true)
    tryAdd("X:"..align(str(rec.relXPos), 5), typeColors.pos, true, true, true)
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
    tryAdd("X Coordinate:"..align(str(rec.relXPos), 5), typeColors.pos, true, true, true)
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
    tryAdd("Open Slots:"..align(str(rec.openSlots),7), typeColors.extra, false, false, true)
    tryAdd("Blocks Mined:"..align(str(rec.mined), 5), typeColors.extra, false, false, true)
    tryAdd("Spaces Moved:"..align(str(rec.moved), 5), typeColors.extra, false, false, true)
    if rec.chestFull then
      tryAdd("Chest Full, Fix It", typeColors.error, false, true, true)
    end
  end
  if screenSize[1] == sizesEnum.large then
  
  end

  reset(colors.black)
  for a, b in ipairs(toPrint) do
    say(b.text, b.color)
  end
  
end

display()

function rednet()
--Will send rednet message to send if it exists, otherwise sends default message.
end

local rednetMessageToSend --This will be a command string sent to turtle

function commandSender()

end
