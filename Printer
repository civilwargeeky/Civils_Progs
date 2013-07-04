--Printer Program
--Made by Civilwargeeky
--Version 0.1.0

--Because Locals make life difficult
_G.civil = {}; setmetatable(_G.civil,{__index = _G}); setfenv(1,_G.civil)
--[[ Put stuff for setting printer side, choosing text and background color, etc. ]]
margin = {
top = "-",
bottom = "-",
left = "|",
right = "|",
}

function readChar()
local exceptTable = { [14] = "backspace", [15] = "tab", [26] = "[", [27] = "]",  [39] = ";", [40] = "'",
    [43] = [[\]], [51] = ",", [52] = ".", [53] = "/", [59] = "print", [28] = "enter", [200] = "up", [203] = "left",
    [205] = "right", [208] = "down" }
local exceptTableUpper = { [26] = "{", [27] = "}", [39] = ":", [40] = "\"",
    [43] = "|", [51] = "<", [52] = ">", [53] = "?" }
local lastKey, key, shiftPressed
repeat
   _, key = os.pullEvent("key")
   if lastKey == "shift" then lastKey = nil; shiftPressed = true end
   if key == 42 or key == 54 then lastKey = "shift" end
until (#(keys.getName(key) or "MultChars") == 1) or exceptTable[key]
if shiftPressed then return exceptTableUpper[key] or exceptTable[key] or string.upper(keys.getName(key))
else return exceptTable[key] or keys.getName(key) end

end


--[[How this will work:
  Have an array containing all the lines. Each element of the array will contain a string of the line.
  Use functions to move words to next lines, and change cursor when arrow keys pressed. Maybe change
  font color with pageUp and pageDown to scroll through, have an indicator in the top right]]
currPos = {x = 1, y = 1 }
scroll = 0
getX, getY = function() local a = term.getCursorPos(); return a end, function() local _,a = term.getCursorPos() return a end
pageX, pageY = 25, 21
startX, startY = 2, 2
screenX,screenY = term.getSize()
function drawMargin()
  local function writeInside(word) if getX() <= screenX and getY() <= screenY then term.write(word) end end
local returnX,returnY = getX(),getY()
local x, y = startX-1, startY-1
for i=0, pageY+1 do
term.setCursorPos(x,y+i)
writeInside(margin.left)
term.setCursorPos(x+pageX+1,y+i)
writeInside(margin.right)
end
for i=0, pageX+1 do
term.setCursorPos(x+i,y)
writeInside(margin.top)
term.setCursorPos(x+i,y+pageY+1)
writeInside(margin.bottom)
end
term.setCursorPos(returnX,returnY)
end

function string.insert(input, letter, pos)
  local before,after 
  if type(input) ~= "string" or type(letter) ~= "string" then error("string, string expected, got "..type(input)..", "..type(letter),2) end
  pos = pos or #input+1
  if pos == 1 then before = "" else before = string.sub(input,1,pos-1) end
  if pos == #input+1 then after = "" else after = string.sub(input,pos) end
  input = before..letter..after
  return input, #input
end
function string.remove(input, posStart, posEnd)
  if type(input) ~= "string" or type(posStart) ~= "number" or type(posEnd) ~= "number" then
    error("string, number, number expected, got "..type(input)..", "..type(posStart)..", "..type(posEnd),2) end
  local before, after
  if posStart == 1 then before = "" else before = string.sub(input,1,startPos-1) end
  if posEnd == #input then after = "" else after = string.sub(input,posEnd+1) end
  input = before..after
  return input, #input
end
local all = {
init = function(pos)
  table.insert(all,pos,"")
  return pos+1
end
setPos = function(x,y) --This is for the onscreen cursor position
  if not (x and y) then x, y = currPos.x, currPos.y end
  term.setCursorPos(startX+x-1,startY+y-scroll)
end
moveUp = function()
  if not currPos.y == 1 then
    currPos.y = currPos.y - 1
    all.setPos()
    return true
  else
    return false
  end
end
moveDown = function()
  if not currPos.y == #all then
    currPos.y = currPos.y + 1
    all.setPos()
    return true
  else
    return false
  end
end
moveLeft = function()
  if currPos.x == 1 then
    if all.moveUp() then currPos.x = (#all[currPos.y]+1) else return false end
  else
    currPos.x = currPos.x - 1
  end
  all.setPos()
  return true
end
moveRight = function()
  if currPos.x == #all[currPos.y] then
    if all.moveDown() then currPos.x = 1 else return false end
  else
    currPos.x = currPos.x + 1
  end
  all.setPos()
  return true
end
moveEndWord = function(pos) --Definitely Needs Testing
  local start = string.find(all[pos],"[%s%-][%w']*$")
  local toMove = string.sub(all[pos],start+1)
  string.remove(all[pos], start, #all[pos])
  string.insert(all[pos]+1, toMove, 1)
  currPos.y = currPos.y + 1
  all.setPos(#toMove+1,currPos.y)
end
insert = function(letter)
  if #letter > 1 then
    for i=1, #letter do
      all.insert(string.sub(letter,i,i))
    end
  end
  all[currPos.y] = string.insert(all[currPos.y],letter,currPos.x)
  if currPos.x > pageX then
    currPos.y = all.init(currPos.y+1)
    all.setPos()
    all.moveEndWord(currPos.y)
    all.insert(letter)
  end
end
}

--Text Input Section
term.setCursorPos(startX,startY)
drawMargin()
repeat
local letter = readChar()
if letter == "left" then all.moveLeft()
elseif letter == "right" then all.moveRight()
elseif letter == "up" then all.moveUp()
elseif letter == "down" then all.moveDown()
elseif letter == "home" then
  repeat all.moveLeft() until getX() == startX
elseif letter == "end" then
  repeat all.moveRight() until getX() >= #all[currPos.y]
elseif letter == "enter" then
  table.insert(all, currPos.y+1, "")
  all.setPos(1,currPos.y+1)
  all.draw()
elseif letter == "backspace" then
  all.remove()
elseif letter == "tab" then
  for i=1, 5 do all.insert(" ") end
else all.insert(letter) end 

until letter == "print"