#Designed to go on a 1x1 screen, but can go on a larger one
local tArgs = {...}
local screenSide = (tArgs[1]):lower()
local sunrise = {start = 4.75, ending = 6 }
local sunset = {start = 17.75, ending = 19 }
local times = {"Day", "Sunset", "Sunrise", "Night"}
local frontColor = colors[tArgs[2]] or colors.white
local backColor = colors[tArgs[3]] or colors.black

local function center(text, xDim)
  for i=1, (xDim-#text)/2 do
    text = " "..text.." "
  end
  return text
end

sleep(2)
term.redirect(peripheral.wrap(screenSide) or peripheral.find("monitor") or error("No Monitors attached, please attach one",0))
if term.isColor() then
  term.setTextColor(frontColor)
  term.setBackgroundColor(backColor)
end
local x, y = term.getSize()
local state = 1
while true do
  local time = os.time()
  if time > sunrise.ending and time < sunset.start then --Day Time
    state = 1
  elseif time > sunset.start and time < sunset.ending then --Sunset
    state = 2
  elseif time > sunrise.start and time < sunrise.ending then --Sunrise
    state = 3
  else --Night
    state = 4
  end
  term.clear()
  term.setCursorPos(1,2)
  print(center(textutils.formatTime(os.time(),false),x))
  print(center(times[state], x))
  sleep(0.05)
end
