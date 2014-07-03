--[[To Do:
If interest is high enough:
1. Add rednet capability
]]

--Version 2.3.0

--Config rows are to the right
--Columns are forward

rows = 2
columns = 2
--Space between saplings
space = 2
--Self Refueling
doRefuel = false
--Turn on Fuel Check
doCheckFuel = true
--If how much to raise by when fuel low
raise = 1000


--More configurable spaces, spaceX is between trees in rows, spaceZ is between rows
--Leave these as nil or a number or the program will error
spaceX = nil
spaceZ = nil
--If you want to use an electric furnace for fueling, set to true
electricFurnace = false



tArgs = {...}
tArgsCheck = {}

for i=1, #tArgs do
if tArgs[i] == "refuel" or tArgs[i] == "fuel" then
doRefuel = true
end
end

if tArgs[1] == "initial" then
failings = 0
initial = true
if tArgs[2] and tArgs[3] and tArgs[4] then
if not (tonumber(tArgs[2]) and tonumber(tArgs[3]) and tonumber(tArgs[4])) then
error([[Please restart with acutal numbers in the argument,
it will most definantly not work without numbers there]],0)
end
rows = tonumber(tArgs[2])
columns = tonumber(tArgs[3])
space = tonumber(tArgs[4])
end
else
initial = false
tArgsCheck = {}
for i=1, #tArgs do
if tonumber(tArgs[i]) then
tArgsCheck[i] = tonumber(tArgs[i])
end
end
if tArgsCheck[1] ~= nil and tArgsCheck[2] ~= nil then
rows = tArgsCheck[1]
columns = tArgsCheck[2]
end
if tArgsCheck[3] ~= nil then
space = tArgsCheck[3]
end
end

if rows < 1 then rows = 1 end
if columns <1 then columns = 1 end
if space <1 then space = 1 end
rows = math.floor(rows)
columns = math.floor(columns)
space = math.floor(space)


if not (spaceX and spaceZ) then
spaceX = space
spaceZ = space
end

if electricFurnace ~= true then
electricFurnace = false
end


--Calculating Fuel Usage
--This will just keep it over the fuel value you set
fuelUsage = rows*columns*8 + --Assume an average of height 8 per tree
rows*(spaceX+1)+  
columns*(spaceZ+1)
if columns/2 ~= math.floor(columns/2)
then
fuelUsage = fuelUsage + rows*(space+1)
end

--Fuel is checked and gotten later in the program


--Defining Functions
function logger() --Will get inside tree, second block, destroy below, then up until top
print("Fuel: "..checkFuel())
local dist = 0
turtle.digDown()
while turtle.detectUp() do
up()
dist = dist + 1
end
for i=0, dist-1 do
down()
end
end


function moveSaplings()
local movedSaps = false
if turtle.getItemCount(1) < 10 then
local itemsInInventory = false
for i=2, 15 do
if turtle.getItemCount(i) > 0 then
itemsInInventory = true
end
end
if itemsInInventory then
for i=2, 15 do
turtle.select(i)
if turtle.compareTo(1) then
turtle.transferTo(1)
movedSaps = true
end
end
end
turtle.select(1)
end
return movedSaps
end

function countSaplings()
local var = turtle.getItemCount(1)
return var
end

function treeCheck()
if turtle.detectUp() or initial then --Added "or initial" to see if the logger works here
logger()
if countSaplings() > 1 then
turtle.placeDown()
elseif moveSaplings() == true then
turtle.place()
elseif initial then --Counts fails for initial
failings = failings + 1
end
end
move() -- This is the move when done with chopping tree
end

function goHome(direction) --This will be the function to get from the tree cutting point to the home chest cluster
if direction == "start" then
up()
move()
elseif direction == "end" then
move()
down()
end
end

function getFuel(electric) -- This will be the function to get fuel from a furnace
turtle.turnLeft()
move()
if not turtle.detectUp() then
  turtle.back()
  turtle.turnRight()
  print("No refueling furnace")
  return 0
end
turtle.select(16) --Sucking Charcoal
turtle.dropDown()
turtle.suckUp()
turtle.back()
local fuelObtained = turtle.getItemCount(16)
up()
 --Dropping off fuel
if turtle.getItemSpace(15) > fuelObtained/4 then --Space, not count
turtle.transferTo(15, math.ceil(fuelObtained/4))
end
turtle.refuel()
if turtle.getItemCount(15) > 0 then --If there is reserve charcoal
  turtle.select(15)
  turtle.drop()
elseif turtle.getItemCount(2) > 2 then --If there isn't, but collected wood
  turtle.select(2)
  turtle.drop(2)
end
if turtle.getItemCount(2) > 5 then --Drop Wood
  up()
  turtle.forward()
  turtle.select(2)
  turtle.dropDown(turtle.getItemCount(2)/4)
  turtle.select(1)
  turtle.back()
  down()
end

down()
turtle.select(1)
turtle.turnRight()
return fuelObtained, checkFuel()
end

function checkFuel()
local fuelLevel = turtle.getFuelLevel()
return fuelLevel
end

--Misc. Move Functions:
function move()
while not turtle.forward() do 
turtle.dig()
end
turtle.suckDown()
end
function up()
while not turtle.up() do turtle.digUp() end
end
function down()
while not turtle.down() do turtle.digDown() end
end

--Initial Check for Saplings
if turtle.getItemCount(1) == 0 then
turtle.turnLeft()
turtle.suck()
turtle.turnRight()
if countSaplings() == 0 then
print("No Saplings, Continue (\"c\") or Quit (\"q\")?")
local _, key = os.pullEvent("char")
if key == "q" then
return
end
end
end


local rowCheck = "right"

--UserInterface
term.clear()
term.setCursorPos(1,1)
print("This is the Auto Log Harvester")
print("Made by Civilwargeeky","")
print("Your Current Dimensions:")
print("X: "..rows.." Z: "..columns.." Space: "..space,"")
print("This Job Will Take Up To "..fuelUsage.." fuel")

--If it should check fuel, defines function and checks
if doCheckFuel == true then

if checkFuel() < fuelUsage then
  if doRefuel then
    term.clear()
    term.setCursorPos(1,1)
    print("Place some wood into slot 2")
    turtle.turnLeft(); turtle.turnLeft()
    getFuel()
    sleep(10)
    getFuel()
    turtle.turnLeft(); turtle.turnLeft()
  end
if checkFuel() < fuelUsage then
term.clear()
term.setCursorPos(1,1)
print("More Fuel Needed")
print("Place in Bottom Right, press any key")
os.pullEvent("char")
turtle.select(16)
while checkFuel() < fuelUsage + raise do
if turtle.refuel(1) == false then
term.clearLine()
print("Still too little fuel")
term.clearLine()
print("Press a key to resume fueling")
os.pullEvent("char")
end
local x,y = term.getCursorPos()
print(checkFuel().." Fuel")
term.setCursorPos(x,y)
end
print(checkFuel().." Units of Fuel")
sleep(3)
turtle.select(1)
end
end
end

print("Starting in 3")
for i=2, 1, -1 do
sleep(1)
print(i)
end
sleep(1)
print("Starting")

--Starting it along
if initial and countSaplings() == 0 then
print("No saplings, please restart with proper amounts")
return false
end
goHome("start")
turtle.turnRight()

cRow = 0
cColumn = 0

--In the program, the singular "column" and "row" are the current count
--   while the plural "columns" and "rows" are the numbers from the config

--Actual Loops
for column=1, columns do
cColumn = cColumn + 1 -- See cRow below...

--Cutting Down Every Tree in Column
move()
for row=1, rows do
cRow = cRow + 1 -- cRow because the rows variable refuses to be nice in called functions
treeCheck()
if row ~= rows then
for b=1, spaceX do
move()
end
end
end

--Go to Next Column
if column ~= columns then
if rowCheck == "right" then
turtle.turnLeft()
for b=1, spaceZ+1 do
move()
end
turtle.turnLeft()
else
turtle.turnRight()
for b=1, spaceZ+1 do
move()
end
turtle.turnRight()
end


--Switching Row
if rowCheck == "right" then
rowCheck = "left"
else
rowCheck = "right"
end
end
end


--Getting back to home chest
if rowCheck == "right" then
turtle.turnLeft()
turtle.turnLeft()
for a=1, rows-1 do
for i=1, spaceX + 1 do
move()
end 
end
for i=1, 2 do
move()
end
end
turtle.turnLeft()

for i=1, (columns-1) * (spaceZ+1) do
move()
end
goHome("end")

--Resupply Saplings
if turtle.getItemCount(1) < 10 then
if not moveSaplings() then
turtle.turnRight()
if turtle.detect() then
turtle.suck()
else
print("No Supply Chest")
sleep(1)
end
turtle.turnLeft()
end
end


--Dropping Inventory
local abc, logs = 0, 0
sleep(1)
for i=2, 14 do
logs = logs + turtle.getItemCount(i)
end
if doRefuel and checkFuel() < fuelUsage then
abc = getFuel(electricFurnace) --abc used to display charcoal
end
if turtle.detect() then
for i=2, 14 do
turtle.select(i)
if not turtle.compareTo(1) then
turtle.drop()
end
end
end
turtle.select(1)


turtle.turnLeft()
turtle.turnLeft()

term.clear()
term.setCursorPos(1,1)
print("Job Done!")
print("Wood Obtained: "..logs)
print("Current Fuel: "..turtle.getFuelLevel())
if initial == true and failings ~= 0 then
print("Placed: "..(columns*rows-failings).."/"..(columns*rows))
end
if doRefuel then
print("Self Fueling Complete, got "..abc.." charcoal")
end


moveSaplings()
