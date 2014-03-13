#Designed to go on a 1x1 screen
tArgs = {...}
side = (tArgs[1] or "front"):lower()
sunrise = {start = 4.75, ending = 6 }
sunset = {start = 17.75, ending = 19 }


sleep(2)
term.redirect(peripheral.wrap(side))
x, y = term.getSize()
while true do
  term.clear()
  time = os.time()
  printTime = textutils.formatTime(os.time(),false)
  term.setCursorPos(1,2)
  print(printTime)
  if time > sunrise.ending and time < sunset.start then
    print("Day")
  elseif time > sunset.start and time < sunset.ending then
    print("Sunset")
  elseif time > sunrise.start and time < sunrise.ending then
    print("Sunrise")
  else
    print("Night")
  end
  sleep(0.05)
end
