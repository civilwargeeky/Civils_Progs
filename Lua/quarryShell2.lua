--Quarry Shell
--Made by Civilwargeeky
--Version 0.0.1

local doDebug = true
local debugLevel = 1 --Levels 1 through x, 1 is most trivial
local dataFolder = "quarryData"
local logsFolder = "Quarry_Logs"

local fileLocations = {}
local fc = fileLocations
fileLocations.quarry = "quarry.lua"
fileLocations.basicEditor = "edit"


local extensions = {}
extensions.quarryConfig = ".qc"
extensions.quarryConfigFull = ".qcf"
extensions.log = ""

local addDir = fs.combine

local d = {} --Table for storing debug functions
d.debug = function(level, ...)
  level = level or 3
  if doDebug and level >= debugLevel then
    print("\n",...)
    os.pullEvent("char")
  end
end
d.info = function(...)
  d.debug(1, ...)
end

local function processFileName(name, ext, folder)
  return addDir(folder or dataFolder, name..ext)
end
local function loadFile(name, ext) --This should return a file handle and fileName
  name = processFileName(name, ext) --Put this in the proper place
  if not fs.exists(name) and not fs.isDir(name) then return false end --Can't read what isn't there
  return fs.open(name, "r"), name
end
local function newFile(name, ext) --This returns a file handle and fileName
  name = processFileName(name, ext)
  return fs.open(name, "w")
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
  
--====================QUARRY FUNCTIONS====================
local quarryFunctions = {}
quarryFunctions.parseConfig = function(name) --This parses configs for other configs and returns full config  
  local file = loadFile(name, ext)
  if not file then return false, "file not found" end
  local text = file.readAll()
  file.close()
  
  local i = 1
  while true do
    local first, last = text:find("##[^#\n]+", i) --Double '#' means load config
    if not first then break end --No more matches
    local str = text:sub(first+2, last) --Returns only the config name
    
    local value
    if str:lower() ~= name:lower() then --So we don't call self. Not going to worry about other infinite recursion though, since its hard.
      value = quarryFunctions.parseConfig(str)
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

quarryFunctions.processConfig = function(name) --This is just a wrapper for parsing and saving configs
  local toSave, message = quarryFunctions.parseConfig(name)
  if not toSave then return false, message end
  
  local file = newFile(name, extensions.quarryConfigFull)
  file.writeLine(toSave)
  file.close()
  return true
end

quarryFunctions.runConfig = function(name)
  if quarryFunctions.processConfig(name) then --Prepare config for running
    d.info(fc.quarry.." -file "..addDir(dataFolder, name..extensions.quarryConfigFull))
    local spoof = {} --This is to trick quarry into saving the proper file
    spoof.getRunningProgram = function() return fc.quarry end
    os.run({shell = spoof}, fc.quarry,"-file",addDir(dataFolder, name..extensions.quarryConfigFull)) --Maybe later we'll handle running programs before/after quarry
    return true
  end
  return false
end

quarryFunctions.deleteConfig = function(name)
  if not fs.exists(addDir(dataFolder,name..extensions.quarryConfig)) then
    return false
  end
  fs.delete(addDir(dataFolder,name..extensions.quarryConfig))
  fs.delete(addDir(dataFolder,name..extensions.quarryConfigFull))
  return true
end

quarryFunctions.basicEdit = function(name, ignoreExists)
  name = processFileName(name, extensions.quarryConfig)
  d.info("New Basic Edit: ",name)
  if not ignoreExists and fs.exists(name) then
    return false, "file exists"
  end
  os.run({}, fileLocations.basicEditor .. " " .. name) --Just load the basic editor
  return true
end

--====================LOGGING FUNCTIONS====================
local loggingFunctions = {}
loggingFunctions.readLog = function(name) --returns a table of individual lines
  local file = loadFile(processFileName(name, extensions.log, logsFolder))
  local toRet = {}
  for a in file:lines() do
    table.insert(toRet, a)
  end
  file.close()
  
  return toRet
end

loggingFunctions.deleteLog = function(name)
  name = processFileName(name, extensions.log, logFolder)
  if fs.exists(name) then
    fs.delete(name)
  end
end

loggingFunctions.deleteAllLogs = function()
  for a, b in pairs(getFiles(logFolder, extensions.log)) do
    loggingFunctions.deleteLog(b)
  end
end

--====================MAIN PROGRAM====================

