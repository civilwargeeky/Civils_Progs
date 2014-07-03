--[[This will feature a "graphical" menu that has selection options for edit config file, read logs, and start quarry.
The edit mode will just call shell.run("edit", filename)
Reading the logs will have a number with arrows on either side. You can press left or right to increase/decrease the number, then press enter to print the contents of the log to the screen.
Start the quarry. This will read options from the config file and write them as parameters and call shell.run("quarry"). This will also be the first option 
IDEA: You can have multiple different config files so you could say "shell quarry bigMine" or "shell quarry 9x9"
These will be registered in a config file specific to this program.]]
--Will have optional parameter of "-quarry" to just run a quarry from the config file.

--Changing global namespace to avoid conflicts
globalTable = nil; _G.globalTable = {}; setmetatable(globalTable, {__index = getfenv(1)}); setfenv(1,globalTable)

local fileNames = {
  workingDirectory = "", --For debug
  workingDirectory = "quarryResources",
  menuAPI = "menuAPI.lua",
}
local gettingAPI = {
  version = "1.0.0",
  pastebin = "4ptKaSQp",
}
--Setting directory
if not fs.isDir(fileNames.workingDirectory) then
  fs.makeDir(fileNames.workingDirectory)
end
shell.setDir(fileNames.workingDirectory)
local function addDir(file, dir)
  return (dir or shell.dir()) .. "/"..file
end


--Screen and Debug functions
local doPrintDebug = true --For debugging messages
local function clearSet(x,y) term.clear(); term.setCursorPos(x or 1, y or 1) end
local function debug(...)
  if doPrintDebug then
    return print(...)
  end
end

--Program functions
local function exit(noClear)
  if not noClear then
    clearSet()
  end
  shell.setDir("")
  error("",0)
end
local function copyTab(tab)
  local toRet = {}
  for a,b in pairs(tab) do
    toRet[a] = b
  end
  return toRet
end
--Acquiring menu api
local requiresDownload = false
if not fs.exists(addDir(fileNames.menuAPI)) then
  requiresDownload = true
else
  debug("API exists")
  local file = fs.open(addDir(fileNames.menuAPI),"r")
  if not file or file.readAll():match("Version (%d+%.%d+%.%d+)") ~= gettingAPI.version then --If we don't have the proper version, redownload stuff
    debug("Improper API Version, downloading latest")
    requiresDownload = true
  end
  if file then file.close() end --Stupid file might not exist stuff
end
if requiresDownload then
  debug("Downloading API")
  if not http then --If we can't download it
    clearSet()
    print("HTTP API not enabled. For this program to work, go to my pastebin and download the menu api as ",fileNames.menuAPI)
    exit(true)
  end
  if fs.exists(addDir(fileNames.menuAPI)) then fs.delete(addDir(fileNames.menuAPI)) end
  shell.run("pastebin get ",gettingAPI.pastebin," ",fileNames.menuAPI) --No addDir because pastebin puts in working directory
  if not fs.exists(addDir(fileNames.menuAPI)) then --If pastebin get failed
    print("API Failed to download.")
    print("Sorry, but this program cannot work without it. Try again later")
    exit(true)
  end
  debug("API Successfully downloaded")
end

--Loading API
local menu = {}
os.run(menu, addDir(fileNames.menuAPI))
if menu.menu then debug("Menu API loaded successfully") end


local function printPause(wait, ...)
  print(...)
  sleep(wait)
end
  

main = {
  title = "Welcome to Quarry Shell",
  { text = "Option 1",
    action = nil,
    child = {
      title = "Inner test",
      { text = "Sub 1",
        action  = {printPause, 3, "This works!"},
      },
      { text = "Back",
        action = "return",
      }
    }
  },
  { text = "Exit",
    action = {exit},
  }
}


local currentTab, parent = main
while true do
  local text, index = menu.menu(currentTab.title, "", currentTab, false)
  local selection = currentTab[index]
  if not selection.action then
    parent = currentTab
    currentTab = selection.child
  elseif selection.action == "return" then
    currentTab = parent or exit()
  else
    local tab = copyTab(selection.action) --Don't want to be popping from a menu
    local func = table.remove(tab, 1) --Take out the function part
    func(unpack(tab)) --Pass everything else as arguments
  end
  
end




exit()