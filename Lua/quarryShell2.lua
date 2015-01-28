--Quarry Shell
--Made by Civilwargeeky
--Version 0.0.1

local dataFolder = "quarryData"

local fileLocations = {}
fileLocations.quarry = "quarry.lua"

local extensions = {}
extensions.quarryConfig = ".qc"
extensions.quarryConfigFull = ".qcf"

local addDir = fs.combine

local function loadFile(name, ext) --This should return a file handle and fileName
  name = addDir(dataFolder, name..extensions.quarryConfig) --Put this in the proper place
  if not fs.exists(name) and not fs.isDir(name) then return false end --Can't read what isn't there
end

local quarryFunctions = {}
quarryFunctions.parseConfig = function(name) --This parses configs for other configs and returns full config
  name = addDir(dataFolder, name..extensions.quarryConfig) --Put this in the proper place
  if not fs.exists(name) and not fs.isDir(name) then return false, "file not found" end --Can't read what isn't there
  
  local file = fs.open(name, "r")
  local text = file.readAll()
  file.close()
  
  local i = 1
  while true do
    local first, last = text:find("##[^#\n]+", i) --Double '#' means load config
    if not first then break end --No more matches
    local str = text:sub(first+2, last) --Returns only the config name
    
    local value = quarryFunctions.parseConfig(str)
    if not value then
      value = "#Failed to load: "..str
    end
    text = text:sub(0, first) .. value .. text:sub(last) --Take first part, add in value, then next part
    i = first + #value + 1 --If this exists, go to the end of it to parse
  end
  
  return text
end

quarryFunctions.processConfig = function(name)
  local toSave, message = quarryFunctions.parseConfig(name)
  if not toSave then return false, message end
  
  local file = fs.open(addDir(dataFolder, name.. extensions.quarryConfigFull), "w")
  file.writeLine(toSave)
  file.close()
  return true
end

quarryFunctions.runConfig = function(name)
  if processConfig(name) then --Prepare config for running
    os.run(addDir(dataFolder, name..extensions.quarryConfigFull), {}) --Maybe later we'll handle running programs before/after quarry
    return true
  end
  return false
end