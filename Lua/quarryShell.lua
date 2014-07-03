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
  menuAPI = "menuAPI.lua"
}
local gettingAPI = {
  version = "1.0.0"
  pastebin = "4ptKaSQp"
}

--Basic screen functions
  local doPrintDebug = true --For debugging messages
  local function clearSet(x,y) term.clear(); term.setCursorPos(x or 1, y or 1) end
  local function debug(...)
    if doPrintDebug then
      return print(...)
    end
  end
--Acquiring menu api
local requiresDownload = false
if not fs.exists(fileNames.menuAPI) then
  requiresDownload = true
else
  local file = fs.open(fileNames.menuAPI,"w")
  if not file or file.readAll():match("Version (%d+%.%d+%.%d+)") ~= gettingAPI.version then --If we don't have the proper version, redownload stuff
    requiresDownload = true
  end
  if file then file.close() end --Stupid file might not exist stuff
end
if requiresDownload then
  debug("Downloading API")
  if not http then --If we can't download it
    clearSet()
    print("HTTP API not enabled. For this program to work, go to my pastebin and download the menu api as ",fileNames.menuAPI)
    error("",0)
  end
  shell.run("pastebin get ",gettingAPI.pastebin)
  if not fs.exists(fileNames.menuAPI) then --If pastebin get failed
    print("API Failed to download.")
    print("Sorry, but this program cannot work without it. Try again later")
    error("",0)
  end
  debug("API Successfully downloaded")
end
