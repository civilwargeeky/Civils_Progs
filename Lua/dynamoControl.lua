--Designed to control dynamos feeding into an energy cell because they DONT limit themselves.
--Designed to work with MFR rednet cable
--Made by civilwargeeky
local checkRate = 10
local emptyPercent = 0.01
local fullPercent = .95
local favorFastCharge = false
local enginesFile = "dynamoEngines"
local peripheralsFile = "dynamoBatteries"


local function isOn(engine)
  if not engine.isColored then
    return rs.getOutput(engine.side)
  else
    return colors.test(rs.getBundledOutput(side), engine.data)
  end
end
  

local engines = {} --A table of engines. #1 is top priority and will be used first
local function addEngine(rf, side, data, isColored) --Data is a number, either the redstone strength or the color.
  isColored = false --Not yet supported
  data = data or 15 --Default strength/color
  local toRet = {rf = rf or 80, side = side, data = data, isColored = isColored}
  toRet.isActive = isOn(toRet, color)
  toRet.id = #engines + 1
  engines[toRet.id] = toRet
end
local cells = {}
local function addCell(side)
  local toRet = {side = side, id = #cells+1}
  toRet.handle = peripheral.wrap(side) or error("Peripheral "..side.." failed to wrap")
  cells[toRet.id] = toRet
end

do --This is the file reading portion
  for a, current in pairs({{enginesFile,addEngine},{peripheralsFile,addCell}}) do
    local file = fs.open(current[1],"r") or error("File not found, please use wizard or create "..current[1],0)
    local input = file.readAll()
    if not input or input == "" then error("File empty: "..current[1],0) end
    for line in input:gmatch("[^\n]+") do --Seperates lines
      if not (line:sub(1,2) == "--") then --If not comment
        local toRet = {}
        for entry in line:gmatch("[\"\'_%w]+") do --Matches sets of letters, numbers, quotes, and underscores
          table.insert(toRet,tonumber(entry) or loadstring("return "..entry)()) --This gets numbers as numbers, but still allows non numbers
        end
        current[2](unpack(toRet)) --Makes a new engine/cell from the parameters

        --current[2](line) --Better Idea. This 'should' work
      end
    end
  end
end

local function engineAt(index)
  if engines[index] then return engines[index] end
  if index <= 0 then return engines[1]
  elseif index > #engines then return engines[#engines] end
end

--Program Part--
local function getLocalStored(periph) return periph.getEnergyStored("west") end
local function getLocalMax(periph) return periph.getMaxEnergyStored("west") end

local function getCellsInfo(fn) --Generic
  local count = 0
  for a, cell in pairs(cells) do
    count = count + fn(cell.handle)
  end
  return count
end
local function getStored()
  return getCellsInfo(getLocalStored)
end
local function getMax()
  return getCellsInfo(getLocalMax)
end

local function getRate(periph, period) --This is the main "waiting" part
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
    rs.setAnalogOutput(engine.side, engine.data)
  else --I don't care because screw MFR for breaking
  end
  print("Turning on engine ", engine.id)
  engine.isActive = true
  return engine.rf
end

local function turnOff(engine)
  if not engine.isActive then return false end
  if not color then
    local toSet = 0
    for a, b in pairs(engines) do --This is for setting to the next analog engine
      if b.side == engine.side then --If we use the same side for analog
        if b.data >= engine.data then
          b.isActive = false --We want to confirm that this one is off too
        elseif b.data > toSet and b.isActive then --We want to turn the power to the next lowest engine
          toSet = b.data
        end
      end
    end
    rs.setAnalogOutput(engine.side, toSet)
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

