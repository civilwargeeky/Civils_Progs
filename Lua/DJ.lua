tArgs = {...}
side = (tArgs[1] or "bottom"):lower()

basic = {["13"] = 178,
cat = 185,
blocks = 345,
chirp = 185,
far = 174,
mall = 197,
mellohi = 96,
stal = 150,
strad = 188,
ward = 251,
["11"] = 71,
wait = 298
}

lengths = {}

for a, b in pairs(basic) do
  lengths["C418 - "..a] = b
end

while true do
  sleep(1)
  term.clear()
  term.setCursorPos(1,1)
  print("Welcome to the DJ!")
  if disk.hasAudio(side) then
    title = disk.getAudioTitle(side)
    time = lengths[title]
    print("Now Playing: "..title)
    print("Music will play for ",time, " seconds")
    disk.playAudio(side)
    _, pos = term.getCursorPos()
    for i = 1, time do
      term.setCursorPos(1,pos)
      term.clearLine()
      print("Has already played ",i," seconds")
      term.clearLine()
      print(math.floor(i/time*100),"% Complete")
      sleep(1)
      if disk.getAudioTitle(side) ~= title then
        break
      end
    end
  else
    print("No Music")
  end
end
