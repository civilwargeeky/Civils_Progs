--Quarry Receiver Version 3.4.0
--Made by Civilwargeeky
--[[
Ideas:
For session persistence, you probably only need to save what monitor and what turtle to connect with.
]]

local debug = true

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

local function setTextColor(color)
  if mon.isColor() then
    return mon.setTextColor(color)
  end
end
local function setBackgroundColor(color)
  if mon.isColor() then
    return mon.setBackgroudnColor(color)
  end
end


--Temp:
setSize()
print(screenSize[1])
print(screenSize[2])
print(dim[1])
print(dim[2])

local items = {}
--Sizes are different screen sizes, priority says if it will be run when not enough screen size, variable is the variable it gets from table, if exclusion, don't run.
local function addItem(name, sizesTab, variablesTab, priority) --Add an item that can be displayed on screen. Priority is number, variable and exclusion are strings
  local toRet = {}

  items[#items+1] = toRet
  items[name] = toRet
end
local function removeItem(item)
  items[items[item].number] = nil
  items[item] = nil
end
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

local rec = {
label = "Pi",
percent = 55,
relXPos = 165,
zPos = 200,
layersDone = 111,
x = 200,
z = 201,
layers = 202,
openSlots = 14,
mined = 5000,
moved = 2500,
chestFull = true,

}




local function reset(color)
  setBackgroundColor(color)
  mon.clear()
  mon.setCursorPos(1,1)
end
local function say(text, color, inc)
  setTextColor(color)
  if debug and #text > sizes[screenSize[1]][1] then error("Tried printing: "..text..", but was too big") end
  mon.write(text)
  print(text)
  os.pullEvent "char"
  local pos = ({mon.getCursorPos()})[2]
  mon.setCursorPos(1, pos+1)
end

local toPrint = {}
local function tryAdd(text, color, ...) --This will try to add text if Y dimension is a certain size
  local doAdd = {...} --booleans for small, medium, and large
  local added = false
  text = text or "-"
  color = color or colors.white
  for i=1, 3 do
    if doAdd[i] and screenSize[2] == i then --If should add this text for this screen size and the monitor is this size
      table.insert(toPrint, {text = text, color = color})
      added = true
    end
  end
  if #text > sizes[screenSize[1]][1] then return false else return true end
end

function display()
  local str = tostring
  toPrint = {} --Reset table
  if screenSize[1] == sizesEnum.small then
    if not tryAdd(str(rec.label), nil, false, false, true) then --This will be a title, basically
      toPrint[#toPrint] = nil
      tryAdd("Quarry!", nil, false, false, true)
    end
    
    tryAdd("-Fuel-", nil, false, true, true)
    if not tryAdd(str(rec.fuel), nil, false, true, true) then --The fuel number may be bigger than the screen
      tryAdd("A lot", nil, false, true, true)
    end
    
    tryAdd("--%%%--", nil, false, true, true)
    tryAdd(str(rec.percent).."%", colors.blue, true, true, true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
    
    tryAdd("--Pos--", nil, false, true, true)
    tryAdd("X:"..str(rec.relXPos), colors.red, true, true, true)
    tryAdd("Z:"..str(rec.zPos), colors.red, true, true, true)
    tryAdd("Y:"..str(rec.layersDone), colors.red, true, true, true)
    
    if not tryAdd(str(rec.x).."x"..str(rec.z).."x"..str(rec.layers), nil , true) then --If you can't display the y, then don't
      print(toPrint[#toPrint.text])
      os.pullEvent "char"
      toPrint[#toPrint] = nil --Remove element
      tryAdd(str(rec.x).."x"..str(rec.z).."z", nil , true)
    end
    tryAdd("--Dim--", nil, false, true, true)
    tryAdd("X:"..str(rec.x), nil, false, true, true)
    tryAdd("Z:"..str(rec.z), nil, false, true, true)
    tryAdd("Y:"..str(rec.layers), nil, false, true, true)
    
    tryAdd("-Extra-", nil, false, false, true)
    tryAdd(textutils.formatTime(os.time()):gsub(" ","").."", nil, false, false, true) --Adds the current time, formatted, without spaces.
    tryAdd("Open:"..str(rec.openSlots), nil, false, false, true)
    tryAdd("Dug:"..str(rec.mined), nil, false, false, true)
    tryAdd("Mvd:"..str(rec.moved), nil, false, false, true)
    if rec.chestFull then
      tryAdd("ChstFll", nil, false, false, true)
    end
    
  end
  if screenSize[1] == sizesEnum.medium then
  
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
