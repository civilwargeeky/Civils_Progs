--Quarry Shell
--Made by Civilwargeeky
--Version 0.0.1

local doDebug = true
local debugLevel = 1 --Levels 1 through x, 1 is most trivial
local dataFolder = "quarryData"
local initialSave = "initialData"

local fileLocations = {}
local fc = fileLocations
fc.basicEditor = "edit"
fc.logsFolder = "Quarry_Logs"
fc.versions = "versions"
fc.quarry = "quarry" --These are unnecessary but useful for testing
fc.menuAPI = "menuAPI.lua"

local extensions = {}
extensions.quarryConfig = ".qc"
extensions.quarryConfigFull = ".qcf"
extensions.log = ""
extensions.saveFile = ".ssf"
extensions.program = ".lua"

local pastebins = {}
pastebins.default = "UQD6i2y9"

local versions = {}

local addDir = fs.combine

local d = {} --Table for storing debug functions
d.baseDebug = function(level, ...)
  if type(level) ~= "number" then
    level = 3
  end
  if doDebug and level >= debugLevel then
    print("\n",...)
    os.pullEvent("char")
  end
end
d.debug = function(...)
  d.baseDebug(3, ...)
end
d.info = function(...)
  d.baseDebug(1, ...)
end

--====================DIRECTORY FUNCTIONS====================
local function processFileName(name, ext, folder)
  return addDir((folder or dataFolder):gsub("%s",""), name:gsub("%s","")..(ext or ""))
end
local function copyTable(tab)
  local toRet = {}
  for a,b in pairs(tab) do
    toRet[a] = b
  end
  return toRet
end
local function loadFile(name, ext) --This should return a file handle and fileName
  name = processFileName(name, ext) --Put this in the proper place
  if not fs.exists(name) or fs.isDir(name) then return false end --Can't read what isn't there
  return fs.open(name, "r"), name
end
local function newFile(name, ext) --This returns a file handle and fileName
  if not fs.exists(dataFolder) then --It is possible this doesn't exist
    d.info("newFile making data folder")
    fs.makeDir(dataFolder)
  end
  name = processFileName(name, ext)
  return fs.open(name, "w")
end
local function saveFile(name, ext, text)
  local handle = newFile(name, ext)
  handle.write(text)
  handle.close()
  return true
end
local function getFiles(dir, regex) --Returns a list of all files that match regex
  local list, toRet = fs.list(dir or ""), {}
  for a, b in pairs(list) do
    if b:match(regex or ".") then
      table.insert(toRet, b)
    end
  end
  return toRet
end
local function updateTable(original, new)
  for a, b in pairs(copyTable(original)) do --Remove all the old values
    original[a] = nil
  end
  for a,b in pairs(new) do --Add all my own
    original[a] = b
  end
  return original
end

--====================SAVING FUNCTIONS====================
local save = {}
save.seperator = "<SEPERATOR>"
save.saveFile = function(saveName, ...)
  d.info("Saving Properties File: ",saveName)
  local handle = newFile(saveName, extensions.saveFile)
  if not handle then return false end --The file must already be in use
  local args = {...}
  for i=1, #args do
    if type(args[i]) == "table" then
      handle.write(textutils.serialize(args[i]))
      handle.write(save.seperator)
    end
  end
  handle.close()
  return true
end

save.loadFile = function(saveName, ...) --Updates all the tables passed with new values, in order
  d.info("Loading Properties File: ",saveName)
  local args = {...} --Note: Order saved must be order loaded, since I don't deal with the names
  local handle = loadFile(saveName, extensions.saveFile)
  if not handle then return false end
  local text = handle.readAll()
  handle.close()
  local i = 1
  for tab in text:gmatch("(.-)"..save.seperator) do
    updateTable(args[i], textutils.unserialize(tab))
    i = i + 1
  end
  return true
end

save.changeDataFolder = function(newName) --Actually changes this file so that the folder is different
  newName = newName:gsub("%s","") --Remove all whitespaces
  if fs.exists(newName) or not shell then
    return false
  end
  os.rename(dataFolder, newName) --Change it for current session
  dataFolder = newName
  
  local prog = shell.getRunningProgram() --Change for future sessions
  local handle = fs.open(prog, "r")
  local text = handle.readAll()
  handle.close()
  text = text:gsub("local dataFolder = \"[^\"]+\"", "local dataFolder = \""..newName.."\"",1) --Replaces the definition line with a new one
  local handle = fs.open(prog, "w")
  handle.write(text)
  handle.close()
  return true
end

save.items = {}
save.new = function(saveName, ...)
  local obj = {}
  save.items[saveName] = obj
  obj.saveName = saveName
  obj.data = {...}
  obj.isSaveObj = true
  return obj
end

save.saveObj = function(str, func)
  local a = save.items[str]
  if a then
    return (func or save.saveFile)(a.saveName, unpack(a.data))
  end
end
save.loadObj = function(str)
  return save.saveObj(str, save.loadFile)
end
 
--====================QUARRY FUNCTIONS====================
local quarry = {}
quarry.installed = function()
  return fs.exists(fc.quarry)
end

quarry.runQuarry = function(...) --Accepts any number of arguments
  if not quarry.installed() then d.debug("Could not run quarry, not loaded") return false end
  local spoof = {} --This is to trick quarry into saving the proper file
  spoof.getRunningProgram = function() return fc.quarry end
  os.run({shell = spoof}, ...) --Maybe later we'll handle running programs before/after quarry
  return true
end

quarry.parseConfig = function(name) --This parses configs for other configs and returns full config  
  local file = loadFile(name, extensions.quarryConfig)
  if not file then return false, "file not found" end
  local text = file.readAll()
  file.close()
  
  local i = 1
  while true do
    local first, last = text:find("##[^#\n]+", i) --Double octothorpe means load config
    if not first then break end --No more matches
    local str = text:sub(first+2, last) --Returns only the config name
    
    local value
    if str:lower() ~= name:lower() then --So we don't call self. Not going to worry about other infinite recursion though, since its hard.
      value = quarry.parseConfig(str)
    end
    if not value then
      value = "#Failed to load: "..str
    end
    text = text:sub(0, first-1) .. value .. text:sub(last+1) --Take first part, add in value, then next part
    print("Text:\n",text,"\n----------")
    i = first + #value + 1 --If this exists, go to the end of it to parse
  end
  return text
end

quarry.processConfig = function(name) --This is just a wrapper for parsing and saving configs
  local toSave, message = quarry.parseConfig(name)
  if not toSave then return false, message end
  
  local file = newFile(name, extensions.quarryConfigFull)
  file.writeLine(toSave)
  file.close()
  return true
end

quarry.runConfig = function(name)
  if quarry.processConfig(name) then --Prepare config for running
    d.info(fc.quarry.." -file "..addDir(dataFolder, name..extensions.quarryConfigFull))
    return quarry.runQuarry("-file",processFileName(name,extensions.quarryConfigFull))
  else
    d.debug("run config could not run '",processFileName(name,extensions.quarryConfig),"'")
    return false
  end
end

quarry.deleteConfig = function(name)
  if not fs.exists(addDir(dataFolder,name..extensions.quarryConfig)) then
    return false
  end
  fs.delete(addDir(dataFolder,name..extensions.quarryConfig))
  fs.delete(addDir(dataFolder,name..extensions.quarryConfigFull))
  return true
end

quarry.basicEdit = function(name, ignoreExists)
  name = processFileName(name, extensions.quarryConfig)
  d.info("New Basic Edit: ",name)
  if not ignoreExists and fs.exists(name) then
    return false, "file exists"
  end
  os.run({shell = shell}, fileLocations.basicEditor, name) --Just load the basic editor
  return name
end

--====================LOGGING FUNCTIONS====================
local logging = {}
logging.readLog = function(name) --returns a table of individual lines
  local file = loadFile(processFileName(name, extensions.log, logsFolder))
  local toRet = {}
  for a in file:lines() do
    table.insert(toRet, a)
  end
  file.close()
  
  return toRet
end

logging.deleteLog = function(name)
  name = processFileName(name, extensions.log, logFolder)
  if fs.exists(name) then
    fs.delete(name)
  end
end

logging.deleteAllLogs = function()
  for a, b in pairs(getFiles(logFolder, extensions.log)) do
    logging.deleteLog(b)
  end
end

--====================UPDATING FUNCTIONS====================
local updating = {}
updating.pastebinGet = function(id)
  local file = http.get("http://www.pastebin.com/raw.php?i="..id)
  if not file then d.debug("Pastebin get failed on: ",id) return false end
  d.info("Pastebin Get Succeeded!")
  return file.readAll(), file.close()
end

updating.downloadFile = function(tab, ext, allowOutdated)
  if type(tab) ~= "table" then error("downloadFile expected table, got "..type(tab),1) end
  if not allowOutdated and (versions[tab.name] or 0) >= tab.version then d.debug(tab.name," already updated") return false end
  local text = updating.pastebinGet(tab.pastebin)
  if not text then return false end
  saveFile(tab.name, ext, text)
  fileLocations[tab.name] = processFileName(tab.name, ext)
  versions[tab.name] = tab.version
  save.saveObj(initialSave)
  save.saveObj(fc.versions)
  return true
  
end

updating.parseVersion = function(version)
  if type(version) == "number" then return version end
  local total, i = 0, 3
  for a in version:gmatch("[^%.]+") do
    total = total + (tonumber(a) or 0) * 100 ^ i --So 3.1.2 would be 30102 and 3.4.0 would be 30400, which is greater
    i = i-1
  end
  return total
end

updating.parseVersionsFile = function(text) --This returns two tables, one containing versions, the other pastebin ids for download
  local toRet = {}

  if text:sub(-1) ~= "\n" then text = text.."\n" end
  d.info("Parsing Version File")
  for line in text:gmatch("[^\n]+") do --Expects line in form "name of program:version:pastebin"
    local first = line:find(":")
    if first then
      local second = line:find(":",first+1)
      local third = line:find(":",second+1)
      local key, name, pastebin, version = line:sub(1,first-1), line:sub(first+1, second-1), line:sub(second+1, third-1), line:sub(third+1)
      d.info("K,V,P ",key," ",version," ",pastebin)
      toRet[key] = {rawVersion = version, version = updating.parseVersion(version), pastebin = pastebin, name = key, displayName = name}
    end
  end
  return toRet
end

updating.compareVersions = function(existing, check) --Returns a list of updates available
  local toRet = {}
  for a,b in pairs(check) do
    if existing[a] and b > existing[a] then
      table.insert(toRet, a)
    end
  end
  return toRet
end
--====================MENU FUNCTIONS====================
local menus = {}
menus.installed = function()
  return fs.exists(fc.menuAPI)
end

--====================MAIN PROGRAM====================

--Loading Initial Configurations
save.new(initialSave,fc, extensions)
--save.loadObj(initialSave)

save.new(fc.versions, versions)
save.loadObj(fc.versions)

local data = updating.parseVersionsFile(updating.pastebinGet(pastebins.default)) --This gets the table of versions and IDs and parses them into tables
updating.downloadFile(data.menuAPI, extensions.program) --We need this before anything else
