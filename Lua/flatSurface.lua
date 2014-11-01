--flat surface

local slot = 1
local turnFunc = turtle.turnRight

local tArgs = {...}
if (tArgs[1] or ""):lower() == "left" then
  turnFunc = turtle.turnLeft
end

local function placeDo(moveFunc, placeFunc)
  while turtle.getItemCount(slot) == 0 do
    slot = slot + 1
    if slot > 16 then error("Out of stuff") end
    turtle.select(slot)
  end
  return moveFunc(), placeFunc()
end

turtle.select(1)
turtle.turnLeft()
turtle.turnLeft()
local switch = false --Whether or not it is above the layer
while true do
  while placeDo(turtle.back, turtle.place) do end --Will keep going back until the end of the row
  turnFunc()
  if not placeDo(turtle.back, turtle.place) then --If can't turn will end
    switch = true
    if not (placeDo(turtle.up, turtle.placeDown) and turtle.back()) then error("Program Stuck") end --Goes up, back, then errors if either fails, and stops the second from going if the first fails
  end
  turnFunc()
  if switch then
    if not (turtle.back() and turtle.down()) then error("Program Over") end --Goes back into the regular
    switch = false
  end
  
  if turnFunc == turtle.turnRight then --Switch the turn function for next row
    turnFunc = turtle.turnLeft
  else
    turnFunc = turtle.turnRight
  end
end
