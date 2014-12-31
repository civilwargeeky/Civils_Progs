--[[This will feature a "graphical" menu that has selection options for edit config file, read logs, and start quarry.
The edit mode will just call shell.run("edit", filename)
Reading the logs will have a number with arrows on either side. You can press left or right to increase/decrease the number, then press enter to print the contents of the log to the screen.
Start the quarry. This will read options from the config file and write them as parameters and call shell.run("quarry"). This will also be the first option 
IDEA: You can have multiple different config files so you could say "shell quarry bigMine" or "shell quarry 9x9"
These will be registered in a config file specific to this program.]]
--Will have optional parameter of "-quarry" to just run a quarry from the config file.

--List of Menu Items this needs to implement:
--[[
  1. Configurations - Running a quarry configuration from a file, editing and making new configurations dynamically from parameters
  2. Themes - Load receiver with themes (once implemented), reset shell with themes (once implemented in menu API)
  3. Read logs from quarry
  4. Update Programs (If not, title "Updates", if update, title "!!!Updates Available!!!")
     at start of program, will go through all the registered files and check version numbers, including the shell.
     If the shell needs an update, it will write a file to replace itself and prompt to reboot the computer. The new program will be called with a "-removeTemp" param to remove the startup
  5. Register programs so that the shell will know where things are. Programs can also be downloaded here
  6. Misc Settings
]]

--Changing global namespace to avoid conflicts
globalTable = nil; _G.globalTable = {}; setmetatable(globalTable, {__index = getfenv(1)}); setfenv(1,globalTable)

cwd = "quarryResources" --Current Working Directory
local fileNames = {
  menuAPI = "menuAPI.lua",
}
local updateInfo = {
  menu = {
    version = "1.0.1",
    pastebin = "4ptKaSQp",
  },
  
}
--Setting directory and directory functions
if not fs.isDir(cwd) then
  fs.makeDir(cwd)
end
local function setDir(dir)
  cwd = dir
end
local function addDir(file, dir)
  return (dir or cwd) .. "/"..file
end
for a,b in pairs(fileNames) do --All file names are absolutes
  if not b:match("/") then
    fileNames[a] = addDir(b)
  end
end

--Screen and Debug functions
local doDebug = true --For debugging messages
local function clearSet(x,y) term.clear(); term.setCursorPos(x or 1, y or 1) end
local function debug(...)
  if doDebug then
    return print(...)
  end
end
local function printPause(t, ...)
  print("")
  print(...)
  sleep(t)
end

--Program functions
local function exit(noClear)
  if not noClear then
    clearSet()
  end
  error("",0)
end
local function copyTab(tab)
  local toRet = {}
  for a,b in pairs(tab) do
    toRet[a] = b
  end
  return toRet
end
function pastebin(code, fileName)
  return shell.run("pastebin get "..code.." "..fileName)
end

--Acquiring menu api
local requiresDownload = false
if not fs.exists(fileNames.menuAPI) then
  requiresDownload = true
else
  debug("API exists")
  local file = fs.open(fileNames.menuAPI,"r")
  if not file or file.readAll():match("Version (%d+%.%d+%.%d+)") ~= updateInfo.menu.version then --If we don't have the proper version, redownload stuff
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
  if fs.exists(fileNames.menuAPI) then fs.delete(fileNames.menuAPI) end
  pastebin(updateInfo.menu.pastebin, fileNames.menuAPI)
  if not fs.exists(fileNames.menuAPI) then --If pastebin get failed
    print("API Failed to download.")
    print("Sorry, but this program cannot work without it. Try again later")
    exit(true)
  end
  debug("API Successfully downloaded")
end

--Loading API
local menu = {}
os.run(menu, fileNames.menuAPI)
if menu.menu then debug("Menu API loaded successfully") end


--Menu Item Class
local menuItem = {} --For class
menuItem.meta = {__index = menuItem}
function menuItem:new(text, ...)
  toRet = {text = text}
  action = {...}
  if action[1] == "return" then --This signals the handler to go to the menuList's parent
    toRet.action = "return"
  elseif type(action[1]) == "table" then --This means the action is a menuList
    toRet.child = action[1]
  elseif #action > 0 then --We want to allow for nil actions, in case of table and linking later
    toRet.action = action --Really cool bit: If we try adding a function that doesn't exist, the table length is nil because the function is nil. Therefore it doesn't error, it just fails to run :)
  end
  setmetatable(toRet, menuItem.meta)
  return toRet
end
function menuItem:run()
  if type(self.action) ~= "table" then return end
  local tab = copyTab(self.action)
  return table.remove(tab, 1)(unpack(tab)) --This runs the first element using all the others
end
--Menu List Class
local menuList = {} --For class
menuList.meta = {__index = menuList}
function menuList:new(title, description)
  toRet = {title = title, description = desctiption, class = "menuList"} --Class is to see if elements of a menu contain menus
  setmetatable(toRet, menuList.meta)
  return toRet
end
function menuList:link(tab, index) self[index or #self].child = tab; tab.parent = self return tab end --This links a menu element to a new menu. This is not in menuItem for brevity reasons
function menuList:addElement(...) 
  local tab = {...}
  if type(tab[1]) ~= "table" then
    table.insert(self, menuItem:new(...)) --If we are making a new menuItem
  else
    table.insert(self, tab[1]) --If the menuItem already exists
  end
  return self
end
function menuList:addBack(text) self:addElement(menuItem:new(text or "Back", "return")); return self end
function menuList:setTemp() menuList.temp = self; return self end --This is so you can break a chain, then come back to it


------MAIN PROGRAM FUNCTIONS------
local configuration = {}
function configuration.parseString(text)
  local toRet = {}
  for a in text:gmatch("%W+") do
    toRet[#toRet+1] = a
  end
  toRet[1] = "-"..toRet[1]
  return toRet
end
function configuration.parseFile(fileName)
  local file = fs.open(fileName,"r")
  local text = file.readAll()
  file.close()
  local toRet = {}
  for line in text:gmatch("[^\n]+") do
    toRet[#toRet+1] = parseString(line)
  end
  return toRet --Returns a table of tables that can be parsed later
end
function configuration.makeString(config)
  local toRet = ""
  for i=1,#config do
    for j=1, #config[i] do
      toRet = toRet..config[i][j].." "
    end
  end
  return toRet
end

local quarry = {}
function quarry.run(config)
  shell.run(fileNames.quarry.." "..configuration.makeString(config))
  exit()
end

  
local register = {}
function register.addPath(fileType, path)
  fileNames[fileType] = path
  --Save file
end



--Defining main menu tree
local mainMenu = menuList:new("Welcome to Quarry Shell")
mainMenu:addElement("Quarry"):link(menuList:new("Quarry Configurations"))
  :addElement("Run Configuration")
  :addElement("New Configuration")
  :addElement("Edit Configuration")
  :addElement("Delete Configurations")
  :addElement("Delete all Configurations"):link(menuList:new("Are You Sure?"))
    :addElement("Yes")
    :addBack("No").parent
  :addBack()
mainMenu:addBack("Exit")



local test = menuList:new("Welcome to Quarry Shell")
test:addElement("Option 1"):link(menuList:new("Inner Test"))
  :addElement("Sub 1", printPause,3, "Works!")
  :addElement("Sub 2"):link(menuList:new("Far Out"))
    :addElement("Way far out man")
    :addElement("So far out"):link(menuList:new("Further out"))
      :addElement("test")
      :addBack().parent:setTemp()
    if math.random(2) == 1 then
      menuList.temp:addElement("Supra tests", printPause, 3, "I'm the best")
    else
      menuList.temp:addElement("Tests of things", printPause, 2, "Woah")
    end
    menuList.temp
    :addBack().parent
  :addBack()
test:addElement("Option 2")
test:addBack("Exit")

local currentTab = mainMenu
while true do
  local text, index = menu.menu(currentTab.title, currentTab.description or "", currentTab, false)
  local selection = currentTab[index]
  if not selection.action then --Assume it has a child. If no action it has a menu
    if selection.child then
      local parent = currentTab
      currentTab = selection.child
    end
  elseif selection.action == "return" then
    currentTab = currentTab.parent or exit()
  else
    --local tab = copyTab(selection.action) --Don't want to be popping from a menu
    --local func = table.remove(tab, 1) --Take out the function part
    --func(unpack(tab)) --Pass everything else as arguments
    selection:run()
  end
  
end




exit()