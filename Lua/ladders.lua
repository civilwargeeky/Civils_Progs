--Version 2.0.0
--[[
  Strategy:
    1. Ensure we have enough fuel to go down and then back up.
    2. Ensure we have at least some ladders
      - We will check all our slots for things with "ladder" in the name, 
      - failing that, if items in inventory, ask if they are ladders
      - If no items/items are not ladders, ask for ladders.
    3. Go forward 1 (optional), turn around, go down until can't.
    4. Go up, placing ladders when possible and filler blocks when needed.
]]

local check_fuel, fuel_limit;

if turtle.getFuelLimit() == "unlimited" then
  check_fuel = function () return math.huge; end;
  fuel_limit = function() return math.huge; end;
else
  check_fuel = turtle.getFuelLevel
  fuel_limit = turtle.getFuelLimit
end

local function table_contains(table, value)
  for _, v in pairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

local function inv_snapshot()
  local to_ret = {}
  for i = 1, 16, 1 do
    to_ret[i] = turtle.getItemDetail(i)
  end
  return to_ret
end

local function inv_difference(old, new)
  if new == nil then
    new = inv_snapshot()
  end
  local to_ret = {}
  for i = 1, 16, 1 do
    local old_slot, new_slot = old[i], new[i];
    if (old_slot == nil) and (new_slot == nil) then
      -- do nothing
    elseif (old_slot ~= nil and new_slot ~= nil) and (old_slot.name == new_slot.name) and (old_slot.count == new_slot.count) then
      -- nothing changed, do nothing
    else -- actual logic
      local temp = {}
      if old_slot == nil then old_slot = {count=0} end -- Fill in missing so we can access elements
      if new_slot == nil then new_slot = {count=0} end -- Fill in missing so we can access elements
      if old_slot.name ~= new_slot.name then
        temp["old_name"] = old_slot.name -- Can be nil
        temp["name"] = new_slot.name -- Can be nil
      end
      temp["difference"] = new_slot.count - old_slot.count
      temp["count"] = new_slot.count
      to_ret[i] = temp;
    end
  end
  return to_ret
end

local function first_changed(changed_slots)
  for index, value in pairs(changed_slots) do
    return index, value.difference
  end
end

local needed_fuel = math.min(256*2, fuel_limit()) --Max World height and back
local go_forward_one = true -- If true, goes forward one when starting. If false, does not
local do_dig_down = true -- If true, will try digging down when going down. Otherwise just goes down as far as possible.
local moved_down = 0
local filler_needed = 0

local function display_settings()
  if go_forward_one then
    print("[F] {Fwd 1 at start} |  Stright down ")
  else
    print("[F]  Fwd 1 at start  | {Stright down}")
  end
  if do_dig_down then
    print("[D] {Dig to Bedrock} |  No dig down ")
  else
    print("[D]  Dig to Bedrock  | {No dig down}")
  end
end

turtle.select(1)
term.clear()
term.setCursorPos(1,1)
print("Welcome to Civil's Ladder Placer!\n")
print("It will also attempt to fill gaps with a material\n")
print("\n")
print("Change settings with keys listed below or any other key to start")
local x, y = term.getCursorPos()
repeat
  term.setCursorPos(x, y)
  display_settings()
  local event, key = os.pullEvent("key")
  if key == keys.f then
    go_forward_one = not go_forward_one
  elseif key == keys.d then
    do_dig_down = not do_dig_down
  end
until key ~= keys.f and key ~= keys.d

if check_fuel() < needed_fuel then
  term.clear()
  term.setCursorPos(1,1)
  print("More fuel needed! Place fuel material in the turtle")
  repeat
    local curr_fuel = check_fuel()
    print("Needed Fuel: ",needed_fuel)
    print("Current Fuel: ",curr_fuel)
    local snapshot = inv_snapshot()
    os.pullEvent("turtle_inventory")
    local changed_slots = inv_difference(snapshot)
    local idx, diff = first_changed(changed_slots)
    if idx ~= nil then -- So using fuel items will queue inventory changes, but we don't want to wait for those
      if (diff > 0) or (changed_slots[idx].count > 0 and changed_slots[idx].old_name ~= nil) then -- Only do anything if they put more items in or replaced some item with a different one
        turtle.select(idx)
        if turtle.refuel(0) then -- If we have a fuelable item.
          turtle.refuel(1) -- Find out how much a single fuel item is
          local new_fuel = check_fuel()
          local amnt_single = new_fuel - curr_fuel
          turtle.refuel(math.ceil((needed_fuel-new_fuel)/amnt_single))
        else -- Otherwise just set select back
          print("Cannot refuel with item!")
        end
        turtle.select(1)
      end
    end
  until check_fuel() > needed_fuel
  term.clear(); term.setCursorPos(1,1)
  print("Current Fuel: ",check_fuel())
else
  term.clear(); term.setCursorPos(1,1)
  print("Sufficient Fuel")
end
print("\nPlace ladders in the top left slot")
print("And place any filler material beside the ladders")

print("\nPlease place all ladders and filler blocks in now. Ladders must be in first slot, but the rest don't matter")
print("Press any key when done")
os.pullEvent("char")
while turtle.getItemCount(1) == 0 do
  print("Must have items in first slot...")
  print("Press any key when done")
  os.pullEvent("char")
end

local slots = inv_snapshot() -- Each element is nil or an element of "name", "count" for slot
local ladder_slots = {} -- Record all slots with ladders in them. Any other slots will be considered to be filler
for i=16,1, -1 do
  if slots[i] ~= nil and slots[i].name == slots[1].name then
    table.insert(ladder_slots, i)
  end
end

local function generic_movement(move, dig, attack, detect)
  while not move() do
    if check_fuel() == 0 then error("Out of fuel",0) end
    if detect() and not dig() then -- If there is a block below us but we can't mine it, bottom of hole
      return false
    end
    attack()
  end
  return true
end
local function forward() return generic_movement(turtle.forward, turtle.dig, turtle.attack, turtle.detect) end
local function up() return generic_movement(turtle.up, turtle.digUp, turtle.attackUp, turtle.detectUp) end
local down;
if do_dig_down then
  down = function() return generic_movement(turtle.down, turtle.digDown, turtle.attackDown, turtle.detectDown) end
else
  down = function() return generic_movement(turtle.down, function() return false end, turtle.attackDown, turtle.detectDown) end
end

local function emergency_end()
  print("Initiating Emergency End!")
  for i = 1, moved_down, 1 do
    up()
  end
  if go_forward_one then
    forward()
  end
  turtle.turnLeft()
  turtle.turnLeft()
  print("Exiting")
  error("Ended in Emergency")
end

local function place_ladder()
  --[[
    State of variables and inventory:
      1. ladder_slots is a list of all inventory slots that contain ladders.
        - If we place the last ladder in an inventory slot, we will remove it from the list
        - If the list is empty that means we are out of ladders
      2. We place ladders below ourselves. Previous functions should have set this up correctly
        - If we can't place a ladder below ourselves, we try a few times before giving up and moving on.
  ]]
  local desired_slot = ladder_slots[1]
  if desired_slot == nil then -- Means we are out of ladders
    emergency_end()
  end
  if turtle.getSelectedSlot() ~= desired_slot then
    turtle.select(desired_slot)
  end
  local place_counter = 0
  while not turtle.placeDown() do -- Try to place, but there may be a mob in the way so hit them a bunch
    turtle.attackDown()
    sleep(0.5)
    place_counter = place_counter + 1
    if place_counter > 20 then
      return false
    end
  end

  if turtle.getItemCount() == 0 then -- If we just placed the last ladder
    table.remove(ladder_slots, 1) -- Remove the top index from slots
  end
  return true
end

local function place_filler(slots)
  --[[
    State of variables and inventory:
      1. slots is an inventory snapshot of all filler slots we have (this is passed by reference)
        - When we place a block, we decrement the count by 1
        - If we place the last block in an inventory slot, we will remove it from the list
        - If the list is empty that means we are out of blocks to place
      2. We place blocks in front of ourselves
        - If we can't place a block in front of ourselves, the item we have selected may not be a block and we remove it from the list
  ]]
  local desired_slot; -- Set desired slot to the first value in the table
  for i, value in pairs(slots) do
    desired_slot = i;
    break
  end
  if desired_slot == nil then
    return emergency_end()
  end

  if turtle.getSelectedSlot() ~= desired_slot then
    turtle.select(desired_slot)
  end

  local has_tried_attacking = false;
  while true do
    local success, reason = turtle.place()
    if success then
      break -- We did it!
    elseif reason:find("item") or has_tried_attacking then -- If we can't place the thing because it's an item (it can be a "block" like redstone but if nothing to attack it's an item)
      slots[desired_slot] = nil -- Remove from available items
      for i, _ in pairs(slots) do -- Get next available slot as desired
        desired_slot = i;
        break
      end
      turtle.select(desired_slot)
      has_tried_attacking = false -- Make sure we reset this
    else
      local attack_success, attack_reason = turtle.attack()
      if not attack_success and attack_reason:find("No tool") then -- If we have no weapon to attack with, wait until mob goes away
        sleep(0.5)
      else
        if has_tried_attacking then
          return false -- If we can't place and can't attack, something is strange
        else
          has_tried_attacking = true -- Note that we tried to attack but failed
        end
      end
    end
  end
  slots[desired_slot].count = slots[desired_slot].count - 1 -- Reduce the count of items in this slots
  if slots[desired_slot].count <= 0 then -- If no more, remove from list
    slots[desired_slot] = nil
  end
  return true
end

local function updateDisplay()
  term.clear(); term.setCursorPos(1,1)
  print("Gone down ",moved_down," blocks")
  print("Needed Filler: ",filler_needed)
  print(check_fuel()," Fuel Left")
  print("Block Below? ", tostring(turtle.detectDown()))
end

turtle.select(1)
print("Starting in...\n")
print("3"); sleep(1)
print("2"); sleep(1)
print("1"); sleep(1)
if go_forward_one then
  forward() --Get in to hole
  turtle.digUp() -- Dig the block above, if possible.
end
turtle.turnLeft()
turtle.turnLeft()

while down() do -- Keep going down until we can't
  moved_down = moved_down + 1 -- Increment how far down we've gone
  if not turtle.detect() then -- Increment how much filler we need
    filler_needed = filler_needed + 1
  end
  updateDisplay()
end

-- Now we know how many ladders and filler we need. Do an inventory check.
slots = inv_snapshot()
local filler_slots = inv_snapshot()
local num_ladders, num_filler = 0, 0
for i, slot_info in pairs(slots) do
  if table_contains(ladder_slots, i) then
    num_ladders = num_ladders + slot_info.count
    filler_slots[i] = nil -- Remove from list of available filler
  else
    num_filler = num_filler + slot_info.count
  end
end
print("We have ", num_ladders, " ladders and need ", moved_down,"\n")
print("We have ", num_filler, " filler and need ", filler_needed,"\n")
if num_ladders < moved_down or num_filler < filler_needed then -- If we don't have enough materials to complete the job, end it here.
  print("Did not have enough blocks to properly make ladders. Sorry.\n")
  emergency_end()
end

--[[
print("Ladders slots:", textutils.serialise(ladder_slots))
print("Filler slots:", textutils.serialise(filler_slots))
read()
]]

while moved_down > 0 do -- Actual job of going back up while placing
  if not turtle.detect() then
    place_filler(filler_slots)
  end
  up()
  place_ladder()
  moved_down = moved_down - 1
end

if go_forward_one then
  forward()
end
turtle.turnRight()
turtle.turnRight()

print("Done")