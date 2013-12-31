--Single Tree-Cutter
--Version 0.1.0
--Made by Civilwargeeky, at the request of Mr. Hohenheim
--Idea, if mod that lets see inv, then check if things are bonemeal/saplings
--[[
More ideas:
  If wanting to save progress, you need these:
    slotTypes
    facing
    atHome
  On startup, if not at home, go down until you are level, then back one
  Also on startup, turnTo 0
  
  MAKE IT SO ON ITEM RESTOCK, MATCHING ITEMS AND MATCHING ITEMS ONLY ARE PROPERLY MARKED
  ]]

local insistOnStock = false --Whether or not it will force a certain amount of things to be in inventory
local facing = 0 --0 is front, 1 is right, 2 is back, 3 is left
local numCut = 0 --Trees cut
local numDropped = 0 --Wood/things dropped off
local slotTypes = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local typeTable = {sapling = 1, bonemeal = 2, wood = 0}
local numTypes = 2 --Used in assign types function
local materialsTable = {sapling = "left", bonemeal = "back", wood = "right"}
local restock = {sapling = 64 * 2, bonemeal = 64*4}
local keepOpen = 5
local atHome = true --Whether or not its in its home spot

--Misc functions
function getInvTable()
  local toRet = {}
  for i=1, 16 do
    toRet[i] = turtle.getItemCount(i)
  end
  return toRet
end

function getChangedSlots(input1, input2)
  local toRet = {}
  for i=1, math.min(#input1, #input2) do
    if input1[i] ~= input2[i] then
      table.insert(toRet,i)
    end
  end
  return toRet
end
function countChange(func, num)
  local snapshot = getInvTable()
  func(num)
  local ending = getInvTable()
  for i=1,16 do
    if snapshot[i] ~= ending[i] then
      return math.abs(snapshot[i]-ending[i])
    end
  end
  return false
end
function screenSet(x, y)
  x, y = x or 1, y or 1
  term.clear()
  term.setCursorPos(x,y)
end
function display()
  screenSet(1,1)
  print("Fuel: ",turtle.getFuelLevel())
  print("I couldn't really think of anything else to put here...")
end
--Custom movement related local functions
function fromBoolean(input) --Like a calculator
if input then return 1 end
return 0
end
function coterminal(num, limit) --I knew this would come in handy :D TI-83 FTW!
limit = limit or 4 --This is for facing
return math.abs((limit*fromBoolean(num < 0))-(math.abs(num)%limit))
end
function genericTurn(func, toAdd)
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
      numCut = numCut + 1
    end
    display()
    return true
  end
  return false
end
function dig(doAdd) return genericDig(turtle.dig, doAdd) end
function digUp(doAdd) return genericDig(turtle.digUp, doAdd) end
function digDown(doAdd) return genericDig(turtle.digDown, doAdd) end
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
--Specific local functions
function getRep(which, fromBack)
  local first, start, finish, step = false
  if fromBack then
    start, finish, step = 16, 1, -1
  else
    start, finish, step = 1, 16, 1
  end
  for i=start, finish, step do --Goes backward because slots are often taken/dropped off
    --[[if turtle.getItemCount(i) > 0 and not first then --If not a rep, will return first slot with items
      first = i
    end]]
    if slotTypes[i] == which then
      return i
    end
  end
  return first
end
function assignTypes(initial) --This gives all items names, if not initial, will not give newTypes
  local currType --Types: 1 = saplings, 2 = bonemeal, >= 3 = other/wood
  if initial then currType = 0 else currType = numTypes end
  for i=1, 16 do
    turtle.select(i)
    local compares = false
    for a=1, currType do
      if turtle.compareTo(getRep(a, true) or 1) then --There should always be a representative, unless first slot
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
    if not initial and not compares then
      slotTypes[i] = 0
    end
  end
  turtle.select(1)
  --types = currType
end
function getNumType(which)
  local num = 0
  turtle.select(getRep(typeTable[which] or which))
  for i=1, 16 do
    if turtle.compareTo(i) then
      num = num + turtle.getItemCount(i)
    end
  end
  return num
end


function mineTree()
  local moveDown = 0
  forward()
  atHome = false
  while turtle.detectUp() do
    up()
    moveDown = moveDown + 1
  end
  for i=1, moveDown do
    down()
  end
  back()
  atHome = true
end
function placeSapling()
  local currSlot = getRep(typeTable.sapling) or getMaterials("sapling")
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
      local currSlot = getRep(typeTable.bonemeal) or getMaterials("bonemeal")
      turtle.select(currSlot)
      turtle.place()
      if turtle.getItemCount(currSlot) == 0 then 
        slotTypes[currSlot] = 0
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
function getMaterials(what, forceWait) --This function will get materials from a certain place
  turtle.select(1) --So materials go in in the first available spot
  local toFace, forceWait = facing, forceWait or insistOnStock
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
  local numObtained = 0
  while numObtained < restock[what] do
    local a = countChange(facingInfo.suck)
    if a then
      numObtained = numObtained + a
      print("Obtained ",numObtained,"/",restock[what]," ",what)
    else
      if insistOnStock then
        print("Suck failed, no more ",what,"?")
        sleep(4)
      else
        break
      end
    end
  end
  local currType = typeTable[what]
  for a,b in ipairs(getChangedSlots(getInvTable(), snapshot)) do
    slotTypes[b] = currType
  end
  assignTypes(false)
  turnTo(toFace)
  return (getRep(typeTable[what]) or getMaterials(what, true))
end
function dropMaterials(what, doAdd)
  local toFace = facing
  doAdd = doAdd or true
  local facingInfo = facingTable[materialsTable[what]] --This table contains direction specific functions, since use is the same
  turnTo(facingInfo.number) --Eg: facingTable[materialsTable["sapling"]].number --> facingTable["left"].number --> 3
  while not facingInfo.detect() do
    screenSet()
    print("Waiting for ",what," chest to be placed on ", materialsTable[what])
    sleep(2)
  end
  for i=1, 16 do
    if slotTypes[i] == typeTable[what] and turtle.getItemCount(i) > 0 then
      turtle.select(i)
      local dropped = false
      repeat
        local curr = turtle.getItemCount(i)
        local amount = countChange(facingInfo.drop, curr) or 0
        if doAdd then
          numDropped = numDropped + amount --This is the global
        end
        print("Dropped ",amount," ",what)
        if amount >= curr then 
          dropped = true
        else 
          screenSet(1,1)
          print("Cannot drop ",what," on ",materialsTable[what], " side")
          sleep(2)
        end
      until dropped
      slotTypes[i] = 0
    end
  end
  turnTo(toFace)
  turtle.select(1) --Its just nicer
  return true
end

function isFull()
  local areFull = 0
  local currInv = getInvTable()
  for i=1, #currInv do
    if currInv[i] > 0 then
      areFull = areFull + 1
    end
  end
  return areFull >= 16-keepOpen
end

--Initial
assignTypes(true) --Initial assign types

--Main Loop
while true do
if turtle.detect() then mineTree() end --Dig out the tree
  placeSapling() --Place a sapling
  useBonemeal() --Use the bonemeal
  if isFull() then --If inventory is full, drop it
    dropMaterials("wood")
  end
end