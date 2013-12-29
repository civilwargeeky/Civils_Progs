--Note: Made in-game, not yet up to scratch

local slot = 1
local turnRight = true

local function placeDo(func)
  while turtle.getItemCount(slot) == 0 do
    if slot < 16 then
      turtle.select(slot+1)
      slot = slot + 1
    else
      error("Out of stuff")
    end
  end
  local toRet = func()
  turtle.place()
  return toRet
end
  

turtle.select(1)
while true do
  while placeDo(turtle.back) do
  end
  local func
  if turnRight then
    func = turtle.turnRight
  else func = turtle.turnLeft
  end
  func()
  if not placeDo(turtle.back) then break end
  func()
  turnRight = not turnRight
end
