--Wizard for making dynamoControls!
--Made by civilwargeeky
local enginesFile = "dynamoEngines"
local peripheralsFile = "dynamoBatteries"
local apiFile = "civilsMenuAPI"
local pastebin = "6gUUv3Ng" --For the dynamo

if not fs.exists(apiFile) then
  print("Getting menu API")
  shell.run("pastebin get E4TJ2uCR "..apiFile)
end
local menu = {}
os.run(menu, apiFile) --Loads the API

local tArgs, onlyUpdate = {...}
if tArgs[1] == "update" then
  onlyUpdate = true
end


local function home()
  term.setCursorPos(1,1)
  term.clear()
end

if not onlyUpdate then
  home()
  print("Welcome to the dynamo control file creation wizard!")
  print("This will guide you to making config files\n")
  --Stage 1, Engines
  local basicSides = {"front", "back", "left", "right", "top", "bottom", }
  print("To start, we will register the engines")
  local toWrite = {}
  local engines = 0
  while true do 
    engines = engines + 1
    local rf, side, data, isColored
    rf = menu.menu("New Engine "..tostring(engines), "How much power per tick does the engine produce?", {"80", "Other", "Quit"})
    if rf == "Other" then
      print("\nHow much then?")
      rf = read()
    elseif rf == "Quit" then
      break
    end
    rf = tonumber(rf) or 80
    side = menu.menu("What side should the output be on?", "", menu.sentenceCaseTable(basicSides)):lower() --Lower so we get the lowercase side
    local check = menu.menu("Is the output basic or colored?", "", {"Basic", "Colored"})
    isColored = check == "Colored"
    if not isColored then
      local tab = {}
      for i=15,1,-1 do table.insert(tab, i) end
      data = menu.menu("What strength should the output be?", "", tab, false, nil, "center", ">>>> "," <<<<")
    else
      data = 1
      print("Colored not supported yet :(")
    end
    home()
    table.insert(toWrite, rf..",\""..side.."\","..data..","..tostring(isColored).."\n")
  end
  local file = fs.open(enginesFile,"w") or error("Engines file could not be opened")
  for i=1, #toWrite do
    file.write(toWrite[i])
  end
  file.close()

  home()
  print("Now for the Energy Cells")
  print("Assuming you are using TE ones, this could work for other mods, though\n")
  sleep(2)
  local periphSides = peripheral.getNames()
  table.insert(periphSides,"Quit")
  local toWrite = {}
  local periphs = 0
  while true do
    periphs = periphs + 1
    local rm
    _, rm = menu.menu("New Cell "..tostring(periphs), "Select which side/peripheral the cell is on, or select quit to quit", menu.sentenceCaseTable(periphSides))
    if rm == #periphSides then --If they selected quit
      break
    else
      table.remove(periphSides,rm)
    end
    table.insert(toWrite, "\""..periphSides[rm].."\"")
  end
  local file = fs.open(peripheralsFile, "w")
  for i=1, #toWrite do
    file.write(toWrite[i])
  end
  file.close()
end

home()
local fileName = "dynamoControl.lua"
local should = menu.menu("Thank you for using the Dynamo Control Station Wizard! \nWould you like to install dynamoControl?","",{"Yes","No"},nil, nil, "center")
if should == "Yes" then
  if fs.exists(fileName) then
    shell.run("rm "..fileName)
  end
  shell.run("pastebin get "..pastebin.." "..fileName)
  local shouldAgain = menu.menu("Done","Would you like to replace startup and reboot?",{"Yes","No"},nil, nil, "center")
  if shouldAgain == "Yes" then
    if fs.exists("startup") then
      shell.run("rm startup")
    end
    local file = fs.open("startup","w")
    file.write("shell.run('"..fileName.."')")
    file.close()
    shell.run("reboot")
  end
end
print("")
