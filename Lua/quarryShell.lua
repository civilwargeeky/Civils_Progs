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

local menuItem = {__index = menuItem} --For class
function menuItem:new(text, ...)
  toRet = {text = text}
  action = {...}
  if action[1] == "return" then
    toRet.action = "return"
  elseif type(action[1]) == "table" then
    toRet.child = action[1]
  elseif #action > 0 then --We want to allow for nil actions, in case of table and linking later
    toRet.action = action
  end
  setmetatable(toRet, self)
  return toRet
end

local menuList = {} --For class
function menuList:new(title, description)
  toRet = {title = title, description = desctiption, class = "menuList"} --Class is to see if elements of a menu contain menus
  setmetatable(toRet, self)
  self.__index = self
  return toRet
end
function menuList:link(tab, index) self[index or #self].child = tab; tab.parent = self return tab end
function menuList:addElement(...) 
  local tab = {...}
  if type(tab[1]) ~= "table" then
    table.insert(self, menuItem:new(...))
  else
    table.insert(self, tab[1])
  end
  return self
end
function menuList:addBack(text) self:addElement(menuItem:new(text or "Back", "return")); return self end



local main = menuList:new("Welcome to Quarry Shell")
main:addElement("Option 1"):link(menuList:new("Inner Test"))
  :addElement("Sub 1", printPause,3, "Works!")
  :addElement("Sub 2"):link(menuList:new("Far Out"))
    :addElement("Way far out man")
    :addElement("So far out"):link(menuList:new("Further out"))
      :addElement("test")
      :addBack().parent
    :addElement("Tests of things", printPause, 2, "Woah")
    :addBack().parent
  :addBack()
main:addElement("Option 2")
main:addBack("Exit")

local currentTab = main
while true do
  local text, index = menu.menu(currentTab.title, currentTab.description or "", currentTab, false)
  local selection = currentTab[index]
  if not selection.action then --Assume it has a child
    if selection.child then
      local parent = currentTab
      currentTab = selection.child
    end
  elseif selection.action == "return" then
    currentTab = currentTab.parent or exit()
  else
    local tab = copyTab(selection.action) --Don't want to be popping from a menu
    local func = table.remove(tab, 1) --Take out the function part
    func(unpack(tab)) --Pass everything else as arguments
  end
  
end




exit()