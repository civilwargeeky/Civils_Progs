--Floor/Ceiling Maker
--Made by Civilwargeeky
--Version 1.0.0

local tArgs = {...}
s = (tArgs[1] or ""):lower():sub(1,1)
p = (tArgs[2] or ""):lower():sub(1,1)
if #tArgs < 2 then --Print help
  print("Usage: floorMaker <left/right> <up/down> [x dist] [z dist]")
  print()
  print("left/right is turn direction at end of first row")
  print("up/down places blocks above or below the turtle")
  error("",0)
end
local dir, func = (s == "r" and "right") or "left"
local placeDir = (p == "u" and "up") or "down"
local xDist = tonumber(tArgs[3]) --Want it to be nil if not there
if xDist then xDist = math.abs(math.floor(xDist))-1 end
local zDist = tonumber(tArgs[4])
if zDist then zDist = math.abs(math.floor(zDist)) end
local rows = 0
placeFunc = placeDir == "up" and turtle.placeUp or turtle.placeDown

local function change()
  if dir == "left" then
    dir = "right"
    func = turtle.turnRight
  else
    dir = "left"
    func = turtle.turnLeft
  end
end
change() --Assigns func, need default
change()

local slot = 1
turtle.select(slot)
local function place()
  if turtle.getItemCount(slot) == 0 then
    repeat --Scanning inventory for blocks
     slot = slot + 1
     turtle.select(slot)
    until turtle.getItemCount(slot) > 0 or (slot >= 16 or error("No blocks"))
  end
  placeFunc()
end

local function go()
  term.clear()
  term.setCursorPos(1,1)
  print("Dir:      ",dir)
  print("PlaceDir: ",placeDir)
  print("Distance: ",xDist+1)
  print()
  print("On row:   ",rows)
  print("Rows:     ",zDist)
  while not turtle.forward() do
    if not turtle.detect() then
      turtle.attack()
    else
      return false
    end
  end
  return true
end

while rows <= (zDist or math.huge) do
  rows = rows + 1
  if not xDist then --Initial behavior
    xDist = -1
    repeat --First row check
      place()
      xDist = xDist + 1
    until not go()
  else --Normally. Allow this in loop so user can specify a distance
    for i=1, xDist do
      place()
      go()
    end
  end
  place()
  func()
  if rows == zDist or not go() then
    break --We have hit the other wall
  end
  func()
  change()
end

print("Done!")