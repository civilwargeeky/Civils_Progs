--Single Tree-Cutter
--Version 0.1.0
--Made by Civilwargeeky, at the request of Mr. Hohenheim
--Idea, if mod that lets see inv, then check if things are bonemeal/saplings
--[[
More ideas:
  For picking up more things if out, compare inv before and after pickup. All slots that have changed are new type.
  ]]


local facing = 0 --0 is front, 1 is right, 2 is back, 3 is left
local cut = 0 --Trees cut

--Misc functions
local function getInvTable()
  local toRet = {}
  for i=1, 16 do
    toRet[i] = turtle.getItemCount(i)
  end
  return toRet
end
local function compareChangedSlots(input1, input2)
  local toRet = {}
  for i=1, math.min(#input1, #input2) do
    if input1[i] ~= input2[i] then
      table.insert(toRet,i)
    end
  end
  return toRet
end
local function screenSet(x, y)
  x, y = x or 1, y or 1
  term.clear()
  term.setCursorPos(x,y)
end
--Custom movement related local functions
local function fromBoolean(input) --Like a calculator
if input then return 1 end
return 0
end
local function coterminal(num, limit) --I knew this would come in handy :D TI-83 FTW!
limit = limit or 4 --This is for facing
return math.abs((limit*fromBoolean(num < 0))-(math.abs(num)%limit))
end
local function genericTurn(func, toAdd)
  local toRet = func()
    facing = coterminal(facing + toAdd)
  return toRet
end
local function right()
  return genericTurn(turtle.turnRight, 1)
end
local function left()
  return genericTurn(turtle.turnLeft, -1)
end
local function turnTo(toTurn)
  toTurn = coterminal(toTurn) or facing
  local func = right
  if coterminal(facing-toTurn) == 1 then func = left end --0 - 1 = -3, 1 - 0 = 1, 2 - 1 = 1
  while facing ~= toTurn do          --The above is used to smartly turn
    func()
  end
end
local function turnAround()
  return turnTo(facing + 2) --Works because input is coterminaled
end
local function genericDig(func, doAdd)
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
local function genericMove(move, dig, attack, force)
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
local function forward(force)
  return genericMove(turtle.forward, dig, turtle.attack, force)
end
local function returnNil() return nil end --Used in back below
local function back()
  return genericMove(turtle.back, returnNil, returnNil, false)
end
local function up(force)
  return genericMove(turtle.up, digUp, turtle.attackUp, force)
end
local function down(force)
  return genericMove(turtle.down, digDown, turtle.attackDown, force)
end
--Specific local functions
local slotTypes = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local typeTable = {sapling = 1, bonemeal = 2}
local materialsTable = {sapling = "left", bonemeal = "back", wood = "bottom"}
--local types = 0 --Types of items
local function getRep(which)
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
local function assignTypes(initial) --This gives all items names, if not initial, will not give newTypes
  local currType = 0 --Types: 1 = saplings, 2 = bonemeal, >= 3 = other/wood
  for i=1, 16 do
    turtle.select(i)
    local compares = false
    for a=1, currType do
      if turtle.compareTo(getRep(a) or 1) then --There should always be a representative, unless first slot
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

local function mineTree()
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


local function placeSapling()
  local currSlot = getRep(typeTable.sapling) or getMaterials("sapling")
  turtle.select(currSlot) --If no saplings, get some saplings/wait
  if not turtle.place() then
    local k = not(dig(false)) or turtle.place() or print("Cannot place sapling, please fix") --Unexpected symbol crap --Digs without adding tries again, then prints that place failed
    if turtle.getItemCount(currSlot) == 0 then
      slotTypes[currSlot] = 0
    end
  end
end
local function useBonemeal()
  while true do
    for i=1, 10 do
      local slot = getRep(typeTable.bonemeal)
      if not slot then return false end
      turtle.select(slot)
      turtle.place()
      if turtle.getItemCount(slot) == 0 then 
        slotTypes[slot] = 0
      end
    end
    return true
    --[[turtle.select(getRep(typeTable.sapling)) --This doesn't work because turtle.compare doesn't work with bonemealed saplings
    if not turtle.compare() then return true end]]
  end
end
local facingTable = {}
do --This will be so I have all the info I need for dropping and sucking.
  local function newEntry (side, number, dropFunc, suckFunc, detectFunc)
    facingTable[side] = {number = number, drop = dropFunc, suck = suckFunc, detect = detectFunc}
  end
  newEntry("forward", 0, turtle.drop, turtle.suck, turtle.detect)
  newEntry("top", 0, turtle.dropUp, turtle.suckUp, turtle.detectUp)
  newEntry("bottom", 0, turtle.dropDown, turtle.suckDown, turtle.detectDown)
  newEntry("left", 3, turtle.drop, turtle.suck, turtle.detect)
  newEntry("right", 1, turtle.drop, turtle.suck, turtle.detect)
  newEntry("back", 2, turtle.drop, turtle.suck, turtle.detect)
end
local function getMaterials(what) --This function will get materials from a certain place
  local facingInfo = facingTable[materialsTable[what]] --This table contains direction specific functions, since use is the same
  turnTo(facingInfo.number) --Eg: facingTable[materialsTable["sapling"]].number --> facingTable["left"].number --> 3
  local doWait = false
  while not facingInfo.detect() do
    doWait = true
    screenSet()
    print("Waiting for ",what," chest to be placed on ", materialsTable[what])
    sleep(2)
  end
  if doWait then
    print("Waiting for key press when all materials in chest")
    os.pullEvent("char")
  end
  local snapshot = getInvTable() --Done to compare inventory
  while facingInfo.suck() do end
  local currType = typeTable[what]
  for a,b in ipairs(compareChangedSlots(getInvTable(), snapshot)) do
    slotTypes[b] = currType
  end
  return getRep(typeTable[what])
end



--Initial
assignTypes(true) --Initial assign types
getMaterials("bonemeal")
print(textutils.serialize(slotTypes))

turnTo(0)


--[[


--Main Loop

while true do
if turtle.detect() then mineTree() end --Dig out the tree
  placeSapling()
  if not useBonemeal() then
    getMaterials("bonemeal")
    useBonemeal()
  end
end]]