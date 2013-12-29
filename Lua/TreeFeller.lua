--Single Tree-Cutter
--Version 0.1.0
--Made by Civilwargeeky, at the request of Mr. Hohenheim
--Idea, if mod that lets see inv, then check if things are bonemeal/saplings

local facing = 0 --0 is front, 1 is right, 2 is back, 3 is left
local cut = 0 --Trees cut

--Custom movement related functions
local function fromBoolean(input) --Like a calculator
if input then return 1 end
return 0
end
function coterminal(num, limit) --I knew this would come in handy :D TI-83 FTW!
limit = limit or 4 --This is for facing
return math.abs((limit*fromBoolean(num < 0))-(math.abs(num)%limit))
end
local function genericTurn(func, toAdd)
  local toRet = func()
    facing = coterminal(facing + toAdd)
  return toRet
end
function right()
  return genericTurn(turtle.turnRight, 1)
end
function left()
  return genericTurn(turtle.turnLeft, -1)
end
function turnTo(toTurn)
  toTurn = coterminal(toTurn) or facing
  local func = right
  if coterminal(facing-toTurn) == 1 then func = left end --0 - 1 = -3, 1 - 0 = 1, 2 - 1 = 1
  while facing ~= toTurn do          --The above is used to smartly turn
    func()
  end
end
function turnAround()
  return turnTo(facing + 2) --Works because input is coterminaled
end
function genericDig(func, doAdd)
  if func() then
    if doAdd then 
      cut = cut + 1
    end
    return true
  end
  return false
end
local function dig(doAdd) return genericDig(turtle.dig, doAdd) end
local function digUp(doAdd) return genericDig(turtle.digUp, doAdd) end
local function digDown(doAdd) return genericDig(turtle.digDown, doAdd) end
function genericMove(move, dig, attack, force)
  force = force or true
  while not move() do
    if force then 
      if not dig() then
        attack()
       end
    else print("Move Failed"); sleep(1)
    end
  end
  return true
end
function forward(force)
  return genericMove(turtle.forward, dig, turtle.attack, force)
end
local function returnNil() return nil end --Used in back below
function back()
  return genericMove(turtle.back, returnNil, returnNil, false)
end
function up(force)
  return genericMove(turtle.up, digUp, turtle.attackUp, force)
end
function down(force)
  return genericMove(turtle.down, digDown, turtle.attackDown, force)
end
--Specific functions
local slotTypes = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
--local types = 0 --Types of items
function selectRep(which)
  local first = false
  for i=1, 16 do
    --[[if turtle.getItemCount(i) > 0 and not first then --If not a rep, will return first slot with items
      first = i
    end]]
    if slotTypes[i] == which then
      return i
    end
  end
  return first
end
function assignSlots(initial) --This gives all items names, if not initial, will not give newTypes
  local currType = 0 --Types: 1 = saplings, 2 = bonemeal, >= 3 = other/wood
  for i=1, 16 do
    turtle.select(i)
    local compares = false
    for a=1, currType do
      if turtle.compareTo(selectRep(a) or 1) then --There should always be a representative, unless first slot
        slotTypes[i] = a
        print("Compares to ",a)
        compares = true
        break
      end
    end
    if turtle.getItemCount(i) > 0 and initial and not compares and currType < 2 then --I don't care about the slot if its not a sapling/bonemeal
      currType = currType + 1
      slotTypes[i] = currType
      print("New Item ",currType)
    end
  end
  turtle.select(1)
  --types = currType
end

assignSlots(true)
print(textutils.serialize(slotTypes))
print("Has saplings: ", not not selectRep(1))
print("Has bonemeal: ", not not selectRep(2))

function mineTree()
  local moveDown = 0
  forward()
  while turtle.detectUp() do
    up()
    moveDown = moveDown + 1
  end
  for i=1, moveDown do
    down()
  end
  back()
end

local saplingType, bonemealType = 1, 2
function placeSapling()
  local currSlot = selectRep(saplingType) or noSaplings()
  turtle.select(currSlot) --If no saplings, get some saplings/wait
  if not turtle.place() then
    local k = not(dig(false)) or turtle.place() or print("Cannot place sapling, please fix") --Unexpected symbol crap --Digs without adding tries again, then prints that place failed
    if turtle.getItemCount(currSlot) == 0 then
      slotTypes[currSlot] = 0
    end
  end
end
function useBonemeal()
  while true do
    for i=1, 10 do
      local slot = selectRep(bonemealType)
      if not slot then return false end
      turtle.select(slot)
      turtle.place()
      if turtle.getItemCount(slot) == 0 then 
        slotTypes[slot] = 0
      end
    end
    return true
    --[[turtle.select(selectRep(saplingType)) --This doesn't work because turtle.compare doesn't work with bonemealed saplings
    if not turtle.compare() then return true end]]
  end
end

while true do --Main loop
  if turtle.detect() then mineTree() end --Dig out the tree
  placeSapling()
  if not useBonemeal() then
    getBonemeal()
    if not useBonemeal() then
      die()
    end
  end
end