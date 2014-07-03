--Version 1.1.0
local neededFuel = 256*2 --Max World height and back

local oldGetFuel = turtle.getFuelLevel
if type(turtle.getFuelLevel()) ~= "number" then
  turtle.getFuelLevel = function() return math.huge end
end

term.clear()
term.setCursorPos(1,1)
print("This program will place ladders straight down on the block it's facing\n")
print("It will also attempt to fill gaps with a material\n")
print("Press any key to continue to fueling section")
os.pullEvent("char")
if turtle.getFuelLevel() < neededFuel then
  turtle.select(16)
  print("Place fuel in bottom right")
  repeat
    print("Needed Fuel: ",neededFuel)
    print("Current Fuel: ",turtle.getFuelLevel())
    while not(turtle.refuel(0)) do --Wait until usable fuel items
      sleep(1)
    end
    turtle.refuel(1)
  until turtle.getFuelLevel() > neededFuel
  term.clear(); term.setCursorPos(1,1)
  print("Current Fuel: ",turtle.getFuelLevel())
else
  term.clear(); term.setCursorPos(1,1)
  print("Sufficient Fuel")
end
print("\nPlace ladders in the top left")
print("And place any filler material beside the ladders")

print("\nPlease place all ladders and filler blocks in now. Ladders must be in first slot, but the rest doesn't matter")
print("Press any key when done")
os.pullEvent("char")

local slots = {} --Format is [1] Amount of items, [2] Is slot ladders
local numLadders, numFiller = 0,0
for i=16,1, -1 do
  turtle.select(i)
  slots[i] = {turtle.getItemCount(i), turtle.compareTo(1)}
  if slots[i][2] then --This gets a count of how much material the turtle has
    numLadders = numLadders + slots[i][1]
  else
    numFiller = numFiller + slots[i][1]
  end
end

local selectedSlot = 1 --Currently selected slot
local function nextLadderSlot()
  if numLadders > 0 then
    for i=selectedSlot+1, 16 do --Cycle through slots
      if turtle.getItemCount(i) > 0 and slots[i][2] then
        turtle.select(i)
        selectedSlot = i
        return true
      end
    end
  end
  return false --If it knows there are no ladders left, or there aren't any for some other reason
end
local function placeFiller()
  local flag = false
  if numFiller > 0 then
    for i=1, 16 do
      if turtle.getItemCount(i) > 0 and not slots[i][2] then --If slot is filler and has stuff in it
        turtle.select(i) --The slot with filler
        if turtle.place() then numFiller = numFiller - 1; flag = true end
        turtle.select(selectedSlot) --The one with ladders
        break
      end
    end
  end
  return flag --Will be true or false
end
      

local function generic(move, dig, attack)
  if turtle.getFuelLevel() == 0 then error("Out of fuel",0) end
  while not move() do
    dig()
    attack()
  end
  return true
end
local function forward() return generic(turtle.forward,turtle.dig,turtle.attack) end
local function up() return generic(turtle.up, turtle.digUp, turtle.attackUp) end

local movedDown = 0

local function updateDisplay()
  term.clear(); term.setCursorPos(1,1)
  print("Gone down ",movedDown," blocks")
  print("Still have ",numLadders," ladders left")
  print("And ",numFiller," filler blocks left")
  print(turtle.getFuelLevel()," Fuel Left")
  print("Block Below? ", tostring(turtle.detectDown()))
end

forward() --Get in to hole
turtle.turnLeft()
turtle.turnLeft()

repeat --This is where it actually goes into a hole
  while not turtle.down() do turtle.attackDown() end
  movedDown = movedDown + 1
  if turtle.getItemCount(selectedSlot) == 0 then 
    if not nextLadderSlot() then break end --If there are no more ladders, then leave
  end 
  if turtle.placeUp() then
    numLadders = numLadders - 1
  end
  if not turtle.detect() then placeFiller() end  
  updateDisplay()
until turtle.detectDown() or numLadders == 0

if not turtle.back() then
  turtle.turnRight()
  turtle.turnRight()
  forward()
  turtle.turnRight()
  turtle.turnRight()
end
turtle.place() --Place ladder at bottom
updateDisplay()

for i=1, movedDown do --Getting back up. Up will automatically break blocks
  up()
end

forward() --Getting back to start pos
forward()
turtle.turnRight()
turtle.turnRight()

turtle.getFuelLevel = oldGetFuel --Cleanup
print("Done")