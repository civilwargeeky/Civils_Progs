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


 insistOnStock = false --Whether or not it will force a certain amount of things to be in inventory
 facing = 0 --0 is front, 1 is right, 2 is back, 3 is left
 cut = 0 --Trees cut
 dropped = 0 --Wood/things dropped off
 slotTypes = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
 numTypes = 2 --Used in assign types function
 restock = {sapling = 64 * 2, bonemeal = 64*4}
 keepOpen = 5
 atHome = true --Whether or not its in its home spot

 typesTable = {}
do local function assignValues(name, typeNum, side) typesTable[name] = {typeNum = typeNum, side = side} end
  assignValues("sapling", 1, "left"); assignValues("bonemeal",2, "right"); assignValues("wood", 0, "back")
end
 highScores = {tree = {}, bonemeal = {}}
local function registerScore(what, score)
  if highScores[what][1] == nil then --Initialize table
    highScores[what] = {0, 0, tally = {}}
  end
  local a = highScores[what]
  a[1] = a[1] + 1
  if score > a[2] then
    a[2] = score
  end
  if not a.tally[score] then 
    a.tally[score] = 1
  else
    a.tally[score] = a.tally[score] + 1
  end --Give every time something happens a tally too
end
 
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
  local snapshot, changed = getInvTable(), 0
  func(num)
  local ending = getInvTable()
  for i=1,16 do
    if snapshot[i] ~= ending[i] then
      changed = changed + math.abs(snapshot[i]-ending[i])
    end
  end
  return changed
end
function screenSet(x, y)
  x, y = x or 1, y or 1
  term.clear()
  term.setCursorPos(x,y)
end
function display()
  screenSet(1,1)
  print("Fuel: ",turtle.getFuelLevel())
  print("Blocks Cut: ",cut)
  print("Blocks Dropped Off: ",dropped)
  print("Current # Wood: ", countType(0))
  print("Current # Saplings: ",countType(1))
  print("Current # Bonemeal: ",countType(2))
  print("Highest Tree: ",highScores.tree[2])
  print("Number of Trees Cut: ",highScores.tree[1])
  print("Bonemeal High Score: ",highScores.bonemeal[2])
  print("Number of Bonemeal Uses: ",highScores.bonemeal[1])
  print("Tree height tallys: ",textutils.serialize(highScores.tree.tally))
end
function fromBoolean(input) --Like a calculator
if input then return 1 end
return 0
end
function coterminal(num, limit) --I knew this would come in handy :D TI-83 FTW!
limit = limit or 4 --This is for facing
return math.abs((limit*fromBoolean(num < 0))-(math.abs(num)%limit))
end
--Custom movement related local functions
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
  if doAdd == nil then doAdd = true end
  if func() then
    if doAdd then 
      cut = cut + 1
    end
    return true
  end
  return false
end
function dig(doAdd) return genericDig(turtle.dig, doAdd) end
function digUp(doAdd) return genericDig(turtle.digUp, doAdd) end
function digDown(doAdd) return genericDig(turtle.digDown, doAdd) end
function genericMove(move, dig, attack, force)
  if force == nil then force = true end
  while not move() do
    if force then 
      if not dig() then
        attack()
       end
    else print("Move Failed"); sleep(1)
    end
  end
  display()
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
    if slotTypes[i] == which and turtle.getItemCount(i) > 0 then
      return i
    end
  end
  return first
end
local function purgeType(which)
  for i=1, 16 do
    if slotTypes[i] == which then slotTypes[i] = 0 end
  end
end
function assignTypes(initial, ...) --This gives all items names, if not initial, will not give new types. ... is slot overrides
  local overrides = {...}
  for i=1,16 do --This handles the overrides
    local a = overrides[i] or 0 --0 because cannot compare with number
    if 1 <= a and a <= 16 then
      if turtle.getItemCount(a) > 0 then
        purgeType(i) --This makes it so this slot is the only one to compare to.
        slotTypes[a] = i --i is the type value, a is the slot number
      end
    end
  end
  local currType --Types: 1 = saplings, 2 = bonemeal, >= 3 = other/wood
  if initial then currType = 0 else currType = numTypes end
  for i=1, 16 do --This handles comparing and new items
    turtle.select(i)
    local compares = false
    for a=1, currType do
      if turtle.compareTo(getRep(a, true) or 1) and turtle.getItemCount(i) > 0 then --There should always be a representative, unless first slot
        slotTypes[i] = a
        print("Slot ", i," Compares to Type ",a)
        compares = true
        break
      end
    end
    if turtle.getItemCount(i) > 0 and initial and not compares and currType < 2 then --I don't care about the slot if its not a sapling/bonemeal
      currType = currType + 1
      slotTypes[i] = currType
      print("Slot ",i," Has New Item Type ",currType)
    end
    if not initial and not compares then
      slotTypes[i] = 0
    end
  end
  turtle.select(1)
  --types = currType
end
function countType(which)
  local num = 0
  for i=1, 16 do
    if turtle.getItemCount(i) == 0 then
      slotTypes[i] = 0
    end
    if slotTypes[i] == which then
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
  if moveDown <= 1 then --These aren't saplings!
    local tab = {}
    tab[1] = getRep(0) --Assuming it thought trees were bonemeal
    tab[2] = getRep(1) --I'm assuming that it thought bonemeal was saplings
    if tab[1] then
      assignTypes(false, unpack(tab)) --Saplings are probably in there somewhere
    else
      print("Assuming no saplings, going for more to compare")
      getMaterials("sapling")
    end
  else
    registerScore("tree",moveDown-1) -- -1 because goes up extra
  end
  atHome = true
end
function placeSapling()
  local currSlot = getRep(typesTable.sapling.typeNum) or getMaterials("sapling")
  turtle.select(currSlot) --If no saplings, get some saplings/wait
  if not turtle.place() then
    local k = not(dig(false)) or turtle.place() or error("Cannot place sapling, something broke") --Unexpected symbol crap --Digs without adding tries again, then prints that place failed
  end
  if turtle.getItemCount(currSlot) == 0 then
    slotTypes[currSlot] = 0
  end
end
function useBonemeal()
  local count = 0
  repeat
    local currSlot = getRep(typesTable.bonemeal.typeNum) or getMaterials("bonemeal")
    turtle.select(currSlot)
    local test = turtle.place()
    if test then
      count = count + 1
    end
    if turtle.getItemCount(currSlot) == 0 then 
      slotTypes[currSlot] = 0
    end
  until not test
  if count == 0 then --If this happens, then its actually hitting/using trees, not saplings
    dig(false) --Kill tree, no counting
    print("Bonemeal place failed something's wrong")
    print("Refreshing inventory")
    --[[print(textutils.serialize(slotTypes))
        os.pullEvent("char")]]
    getMaterials("sapling", true) --Get more saplings, this will also force a recount
--[[print(textutils.serialize(slotTypes))
        os.pullEvent("char")]]
    getMaterials("bonemeal", true) --Actually, it might mean that bonemeal was misidentified too. Better get fresh
--[[print(textutils.serialize(slotTypes))
        os.pullEvent("char")]]
  else
    registerScore("bonemeal", count)
  end
    --[[turtle.select(getRep(typesTable.sapling.typeNum)) --This doesn't work because turtle.compare doesn't work with bonemealed saplings
    if not turtle.compare() then return true end --This would have been in a while true do loop]]
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
  print("Getting ",what)
  turtle.select(1) --So materials go in in the first available spot
  local toFace = facing
  if forceWait == nil then forceWait = insistOnStock end
  local facingInfo = facingTable[typesTable[what].side] --This table contains direction specific functions, since use is the same
  turnTo(facingInfo.number) --Eg: facingTable[materialsTable["sapling"]].number --> facingTable["left"].number --> 3
  local doWait = false
  while not facingInfo.detect() do
    doWait = true
    screenSet()
    print("Waiting for ",what," chest to be placed on ", typesTable[what].side)
    sleep(2)
  end
  if doWait then
    print("Waiting for key press when all materials in chest")
    os.pullEvent("char")
  end
  local snapshot = getInvTable() --Done to compare inventory
  local numObtained = countType(typesTable[what].typeNum)
  local hasSucked = not forceWait --If forceWait is true, we want to make sure it sucks at least one stack, for flushing purposes.
  while (numObtained < restock[what]) or (not hasSucked) do
    local a = countChange(facingInfo.suck)
    if a ~= 0 then
      numObtained = numObtained + a
      print("Obtained ",numObtained,"/",restock[what]," ",what)
      hasSucked = true
    else
      if forceWait then
        print("Suck failed, no more ",what,"?")
        sleep(4)
      else
        break
      end
    end
  end
  local currType = typesTable[what].typeNum
  local changedTable = getChangedSlots(getInvTable(), snapshot)
  for a,b in ipairs(changedTable) do
    slotTypes[b] = currType
  end
  local tempTable = {}
  tempTable[typesTable[what].typeNum] = changedTable[1] --Doesn't even matter if nil. Nil means no override.
  assignTypes(false, unpack(tempTable)) --This call overrides whatever it just got as the proper type
  turnTo(toFace)
  return (getRep(typesTable[what].typeNum) or getMaterials(what, true))
end
function dropMaterials(what, doAdd)
  print("Dropping off ",what)
  local toFace = facing
  if doAdd == nil then doAdd = true end
  local facingInfo = facingTable[typesTable[what].side] --This table contains direction specific functions, since use is the same
  turnTo(facingInfo.number) --Eg: facingTable[materialsTable["sapling"]].number --> facingTable["left"].number --> 3
  assignTypes(false) --This will catch any saplings and things that get picked up along the way
  while not facingInfo.detect() do
    screenSet()
    print("Waiting for ",what," chest to be placed on ", typesTable[what].side)
    sleep(2)
  end
  local currDropped = 0
  for i=16, 1, -1 do
    if slotTypes[i] == typesTable[what].typeNum and turtle.getItemCount(i) > 0 then
      turtle.select(i)
      local hasDropped = false
      repeat
        local currItems = turtle.getItemCount(i)
        local amount = countChange(facingInfo.drop, currItems)
        currDropped = currDropped + amount
        if doAdd then
          dropped = dropped + amount --This is the global
        end
        print("Dropped ",amount," ",what,". ",currDropped, " total")
        if amount >= currItems then 
          hasDropped = true
        else 
          screenSet(1,1)
          print("Cannot drop ",what," on ",typesTable[what].side, " side")
          sleep(2)
        end
      until hasDropped
      slotTypes[i] = 0
      if countType(typesTable[what].typeNum) <= (restock[what] or 0) then
        break
      end
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
if countType(typesTable.sapling.typeNum) == 0 then
  getMaterials("sapling",true)
end
if countType(typesTable.bonemeal.typeNum) == 0 then
  getMaterials("bonemeal", true)
end

--Main Loop
while true do
  if turtle.detect() then mineTree() end --Dig out the tree
  placeSapling() --Place a sapling
  useBonemeal() --Use the bonemeal
  if isFull() then --If inventory is full, drop it
    dropMaterials("wood")
  end
  if countType(typesTable.sapling.typeNum) > restock.sapling then
    dropMaterials("sapling", false)
  end
  if countType(typesTable.bonemeal.typeNum) > restock.bonemeal then
    dropMaterials("bonemeal", false)
  end
end