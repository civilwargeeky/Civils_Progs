--Note: Made in-game, not yet up to scratch
--TODO: Make this file lay tracks on essentially the same concept. Maybe use type generation from auto-tree logger.
--      This will go through inventory to assign types to rails. It will go through to different stacks if needed.
--      Also prompt users for rail ratio like 12:3 regular to powered, maybe have redstone torches too. Ooh! You could have a configurable function to place the redstone.

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
