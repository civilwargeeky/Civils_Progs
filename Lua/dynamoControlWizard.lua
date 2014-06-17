--Wizard for making dynamoControls!
--Made by civilwargeeky
local enginesFile = "dynamoEngines"
local peripheralsFile = "dynamoBatteries"
local apiFile = "civilsMenuAPI"

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
  local basicSides = {"top", "bottom", "front", "back", "left", "right"}
  print("To start, we will register the engines")
  local file = fs.open(enginesFile,"w")
  local engines = 0
  while true do 
    engines = engines + 1
    local rf, side, data, isColored
    print("New Engine "..tostring(engines).."\n")
    print("How much power per tick does this engine produce?")
    print("Or type 'quit' to end the engine section")
    rf = read()
    if rf:sub(1,1):lower() == "q" then break end
    _, side = menu.menu("What side should is the output on?", "", basicSides)
    local _, check = menu.menu("Is the output basic or colored?", "", {"Basic", "Colored"})
    isColored = check == "Colored"
    if not isColored then
      local tab = {}
      for i=15,1,-1 do table.insert(tab, i) end
      _, data = menu.menu("What strength should the output be?", "", tab, false, nil, "center", ">>>> "," <<<<")
    else
      data = 1
      print("Colored not supported yet :(")
    end
    home()
    file.write(rf..",\""..side.."\","..data..","..tostring(isColored).."\n")
  end
  file.close()

  home()
  print("Now for the Energy Cells")
  print("Assuming you are using TE ones, this could work for other mods, though\n")
  sleep(2)
  local periphSides = peripheral.getNames()
  table.insert(periphSides,"Quit")
  local file = fs.open(peripheralsFile, "w")
  local periphs = 0
  while true do
    periphs = periphs + 1
    local side
    local rm
    rm, side = menu.menu("New Cell "..tostring(periphs), "Select which side/peripheral the cell is on, or select quit to quit", periphSides)
    if rm == #periphSides then 
      break
    else
      table.remove(periphSides,rm)
    end
    file.write("\""..side.."\"")
  end
  file.close()
end

home()
local fileName = "dynamoControl.lua"
local should = menu.menu("","Thank you for using the Dynamo Control Station Wizard!\nWould you like to install dynamoControl?",{"Yes","No"},nil, nil, "center")
if should == 1 then
  if fs.exists(fileName) then
    shell.run("rm "..fileName)
  end
  shell.run("pastebin get 6gUUv3Ng "..fileName)
  local shouldAgain = menu.menu("Done","Would you like to replace startup and reboot?",{"Yes","No"},nil, nil, "center")
  if shouldAgain == 1 then
    if fs.exists("startup") then
      shell.run("rm startup")
    end
    local file = fs.open("startup","w")
    file.write("shell.run('"..fileName.."')")
    file.close()
    shell.run("reboot")
  end
end

