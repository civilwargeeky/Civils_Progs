--Tower Building / Hole Filling Program
--Made by Civilwargeeky
--Version 0.0.2

--[[ Recent Changes:
  1. Made the program work
]]

--[[ToDo:
  3. Add in intial arguments for dimensions
  4. Add in an initial refueling
  5. Make an intelligent goto for getting more material
  6. Make a getBlocks function for retrieving blocks
]]
--Ignore
local fuel = {}
local dim = {}
local inv = {}
--End of Ingore

--Config
fuel.keepAbove = 100
fuel.raiseTo = 300
fuel.slot = 16
dim.x = 5
dim.z = 5
dim.raise = 0

--====Defining Values and Functions====
--Fuel
fuel.check = turtle.getFuelLevel
function fuel:test()
  if self.check() < self.keepAbove then
    if turtle.getItemCount(fuel.slot) > 0 and turtle.select(fuel.slot) and turtle.refuel(0) then
      repeat
        turtle.refuel(1)
      until turtle.getItemCount(fuel.slot) == 0 or self.check() > self.raiseTo
      return true
    else
      print("Cannot Refuel")
      return false
    end
  end
  return false
end
--Moving and Placing Blocks
inv.slot = 1
inv.placed = 0
local pos = {x = 0, y = 0, z = 1, facing = 1, direction = 0, rowPos = 0}
--Facing: 1 Forward, 2 Right, 3 Backward, 4 Left
--Going: 0 Down, 1 Up
--RowPos is a variable used in the x loop to determine location
function pos.update()
  if pos.z % 2 == 0 then --If coming towards 0
    pos.rowPos = dim.x - pos.x + 1
  else
    pos.rowPos = pos.x
  end
end
local function hasItems(num)
  num = num or inv.slot
  return turtle.getItemCount(num) > 0
end
local function changeSlot(num)
  num = num or inv.slot
  if hasItems(num) then
    turtle.select(num)
    inv.slot = num
    return true
  end
  return false
end
local function getBlocks()
  local count = 0
  for i=1, 16 do
    if i ~= fuel.slot then
      count = count + turtle.getItemCount(i)
    end
  end
  return count
end
local function placeUp()
  if turtle.placeUp() then
    inv.placed = inv.placed + 1
    return true
  end
  return false
end
local function placeDown()
  if turtle.placeDown() then
    inv.placed = inv.placed + 1
    return true
  end
  return false
end
local function place()
  if turtle.place() then
    inv.placed = inv.placed + 1
    return true
  end
  return false
end
local move = {}
function move.place(placeForward)
  if turtle.getItemCount(inv.slot) == 0 then --This block changes from empty slots
    repeat
      changeSlot(inv.slot+1)
    until (hasItems() and inv.slot ~= fuel.slot) or inv.slot == 16
    if inv.slot == 16 then
      getBlocks()
    end
  end
  if placeForward then return place() end
  if pos.direction == 0 then
    return placeUp()
  elseif pos.direction == 1 then
    return placeDown()
  else error("Improper Place Direction",2) end
end
function move.generic(moveFunc,attackFunc)
  fuel:test()
  local number = 0
  while not moveFunc() do
    number = number + 1
    attackFunc()
    sleep(0.5)
    if number > 10 then return false end
  end
  return true
end
function move.genericPosChange(plusOrMinus) --Giving 1 is for forward, -1 is for back
  if type(plusOrMinus) ~= "number" then error("Illegal Argument to Generic Pos Change",2) end
  if pos.facing == 1 then
    pos.x = pos.x + plusOrMinus
  elseif pos.facing == 3 then
    pos.x = pos.x - plusOrMinus
  elseif pos.facing == 2 then
    pos.z = pos.z + plusOrMinus
  elseif pos.facing == 4 then
    pos.z = pos.z - plusOrMinus
  else error("Facing is messed up: "..tostring(pos.facing),2)
  end
end
function move.up()
  if move.generic(turtle.up,turtle.attackUp) then
    pos.y = pos.y - 1
  end
  updateScreen()
end
function move.down()
  if move.generic(turtle.down,turtle.attackDown) then
    pos.y = pos.y + 1
  end
  updateScreen()
end
function move.forward()
  if move.generic(turtle.forward,turtle.attack) then
    move.genericPosChange(1)
    pos.update()
    updateScreen()
  end
end
function move.back()
  if move.generic(turtle.back, function() return nil end) then
    move.genericPosChange(-1)
    pos.update()
    updateScreen()
  end
end
function move.turnTo(direction)
  while pos.facing ~= direction do
    turtle.turnRight()
    pos.facing = pos.facing + 1
    if pos.facing > 4 then pos.facing = 1 end
  end
end
--Screen
function updateScreen()
term.clear()
term.setCursorPos(1,1)
for a, b in pairs(pos) do if type(b) ~= "function" then print(a,": ",b) end end
for a, b in pairs(inv) do if type(b) ~= "function" then print(a,": ",b) end end
end

--====Actual Movement====
print("Welcome to the Tower Builder / Quarry Filler Thing")
for i=1, dim.raise + 1 do
  move.up()
end
dim.yHome = pos.y --The home position is the current y value number of blocks down
pos.x, pos.y, pos.z = 0, 1, 1 --Initialize at the top
move.forward()
move.turnTo(3) --Moves backward

while pos.z <= dim.z do --Repeat the making of a row until it is done with rows
  while pos.rowPos <= dim.x do --Repeat until it gets to the end of an x row
    pos.doBreak = false
    if pos.rowPos == dim.x and pos.direction == 0 then --If it is on the last row and it is going down, then just go up instead
      repeat move.down() until turtle.detectDown()
      pos.direction = 1
    end
    if pos.direction == 0 then --If it is going down
      move.down()
      repeat --Repeat moving down and placing above itself until it gets to the bottom of the pit
        move.down()
        move.place()
      until turtle.detectDown()
      if pos.rowPos ~= dim.x then --If it is not at the end of the row
        move.back()
        move.place(true)
      else
        pos.doBreak = true --Break the loop
      end
      pos.direction = 1 --It should go up the next row
    else
      repeat --This is the same thing as above except going up
        move.up()
        move.place()
      until pos.y == 1
      if pos.rowPos ~= dim.x then
        move.back() --Does not need to place because it is above everything
      else
        pos.doBreak = true --Break the loop
      end
      pos.direction = 0 --It should go down the next row
    end
    if pos.doBreak then --Break the loop
      break
    end
  end
  if pos.z == dim.z then break end --Do not want to go an extra layer
  if pos.z % 2 == 1 then --If it on an odd row (e.g. the start one)
    move.turnTo(2) --Turn to the right
    move.forward() --Get to the next row
    move.turnTo(1) --Because it moves backwards
  else
    move.turnTo(2) --Turn to the absolute right (left)
    move.forward() --Get to the next row
    move.turnTo(3) --Because it moves backwards
  end
end
move.goto(1,1,1,3)
move.forward()
while pos.y < dim.yHome do
  move.down()
end
print("Should be finished")
