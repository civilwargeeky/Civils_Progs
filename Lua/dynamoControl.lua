--Designed to control dynamos feeding into an energy cell because they DONT limit themselves.
--Designed to work with MFR rednet cable
checkRate = 10
emptyPercent = 0.01
fullPercent = .95
favorFastCharge = true


sides = { front = 1, right = 2, left = 3, back = 4, top = 5, bottom = 6}

local function checkSide(side)
  if not sides[side] then error("Caller gave side "..tostring(side), 3) end
  return side
end

local function isOn(side, color)
  checkSide(side)
  if not color then
    return rs.getOutput(side)
  else
    return colors.test(rs.getBundledOutput(side), color)
  end
end
  

local engines = {} --A table of engines. #1 is top priority and will be used first
local function addEngine(rf, side, color) --Color can be "false" for regular redstone output
  local toRet = {rf = rf or 80, side = checkSide(side), color = color}
  toRet.isActive = isOn(side, color)
  toRet.id = #engines + 1
  engines[toRet.id] = toRet
end

--Eventually this will be in a seperate file
addEngine(80, "bottom", false)
addEngine(80, "left", false)
addEngine(80, "front", false)
addEngine(90, "top", false)

local function engineAt(index)
  if engines[index] then return engines[index] end
  if index <= 0 then return engines[1]
  elseif index > #engines then return engines[#engines] end
end

local cell = {side = "back"}
cell.handle = peripheral.wrap(cell.side) or error("peripheral failed to wrap")
--Program Part--
local function getStored(periph) return periph.handle.getEnergyStored("west") end
local function getMax(periph) return periph.handle.getMaxEnergyStored("west") end

local function getRate(periph, period)
  local start = getStored(periph)
  local timer, passed = os.startTimer(checkRate), false
  repeat
    local event, val1, val2 = os.pullEvent()
    if val1 == timer then passed = true
    elseif event == "char" then passed = true
      if val1 == "q" then error("Program ended by user",0) end
    end
  until passed
  local finish = getStored(periph)
  print("Current rate: ",(finish-start)/period/20)
  return (finish-start)/period/20
end

local function getPercent(periph) return getStored(periph)/getMax(periph) end

local function turnOn(engine)
  if engine.isActive then return false end
  if not color then
    rs.setOutput(engine.side, true)
  else --I don't care because screw MFR for breaking
  end
  print("Turning on engine ", engine.id)
  engine.isActive = true
  return engine.rf
end

local function turnOff(engine)
  if not engine.isActive then return false end
  if not color then
    rs.setOutput(engine.side, false)
  else --I don't care
  end
  print("Turning off engine ",engine.id)
  engine.isActive = false
  return engine.rf
end

local function getOutput()
  local toRet = 0
  for a, b in pairs(engines) do
    if b.isActive then
      toRet = toRet + b.rf
    end
  end
  return toRet
end
local function getMaxOutput()
  local toRet = 0
  for a,b in ipairs(engines) do toRet = toRet+b.rf end
  return toRet
end

for i=1, #engines do --Maybe make this smarter later. I don't want nonsequential engines on
  turnOff(engineAt(i))
end


local index = 0 --The currently selected engine that is on
local function addIndex() if index == #engines then return false end index = index+1 return true end
local function subIndex() if index <= 0 then return false end index = index-1 return true end

while true do --MAIN LOOP
  for i=1, term.getSize() do write("-") end
  print("Starting loop")
  print("Percent Charged: ",getPercent(cell))
  local rate = getRate(cell, checkRate)
  if getPercent(cell) < emptyPercent then rate = -5000 end --Assuming that the battery is empty
  if rate == 0 then
    print("Assuming battery at max, turning off to save power")
    turnOff(engineAt(index))
    subIndex()
  elseif rate > 0 then
    print("Battery charging")
    if favorFastCharge then
      if getPercent(cell) < fullPercent and favorFastCharge then
        print("Less than full and want fast charge, adding engines")
        while not( rate > (getMax(cell)-getStored(cell))*20*checkRate) and index ~= #engines and favorFastCharge do --Keep adding engines until the rate would instantly fill it, or until we are out of engines
          addIndex()
          rate = rate + (turnOn(engineAt(index)) or 0)
        end
      else
        print("More than full, removing unnessesary enginess")
        while rate > engineAt(index).rf do
          rate = rate - (turnOff(engineAt(index)) or 0)
          subIndex()
        end
      end
    end
  else
    if not(getPercent(cell) > fullPercent) then
    print("Battery draining, trying to stablize")
      while rate < 0 and index ~= #engines and not(getPercent(cell) > fullPercent) do
        addIndex()
        rate = rate + (turnOn(engineAt(index)) or 0)
      end
    else
      print("Battery draining, but full. It's fine")
    end
  end

end

