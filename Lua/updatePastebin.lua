--Updates programs from a pastebin

local tArgs = {...}
if #tArgs < 2 then
  print("Usage: update [pasteID] [fileName]")
  error("",0)
end

local id, file = tArgs[1], tArgs[2]

if fs.exists(file) then
  print("Removing Existing File")
  fs.remove(file)
end
shell.run("pastebin get "..id.." "..file)
print("Done")