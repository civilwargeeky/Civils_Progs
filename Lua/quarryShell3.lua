--Quarry Shell v3
--Made by Civilwargeeky
--Version 0.0.1

--This basically handles the initial setup of folders and such and checking for updates to installed modules
--So all of the "shell" functions will be handled by a different program that takes info from this one

string.add = function(a, b) return fs.combine(a,b) end --For resolving file paths

local dir = {
  main = ".quarry",
}
dir.modules = dir.main.."/modules"
dir.configs = dir.main.."/configs"
dir.apis = dir.main.."/apis"

local url = {
  main = "insert url here",
  dev = "etc",
}

local ext = {
  data = ".ssf",
  module = ".lua",
}

local files = {
  settings = dir.main:add("settings"..ext.data)
}

local function checkDir(dir)
  if not fs.isDir(dir) then
    if fs.exists(dir) then fs.delete(dir) end
    fs.makeDir(dir)
  end
end
local function writeFile(location, data)
  local handle = fs.open(location,"w")
  if type(data) == "table" then
    handle.write(textutils.serialize)
  else
    handle.write(tostring(data))
  end
  handle.close()
end
local function readFile(location)
  local handle - fs.open(location,"r")
  local text = handle.readAll()
  handle.close()
  if textutils.unserialize(text) then
    return textutils.unserialize(text)
  else
    return text
  end
end

local function saveData(tab)
  checkDir(dir.main)
  if tab.fileLocation:sub(-#ext.data) ~= ext.data then error("in saveData, "..tab.fileLocation.." has improper extension") end
  writeFile(dir.main:add(tab.fileLocation), tab)
end
local function loadData(tab)
  return readFile(tab.fileLocation)
end
local function newData(fileLocation)
  local toRet = {fileLocation = dir.main:add(fileLocation..ext.data)}
  if fs.exists(toRet.fileLocation) then
    toRet = loadData(toRet)
  else
    saveData(toRet)
  end
  return toRet
end

local modules = newData("modules") --This will store installed modules by identifier (quarry is 1?) and store version, fileName, and display name
local metadata = newData("metadata") --This will store the last downloaded list of files.

local function downloadFile(url)
  local data, code = http.get(url)
  if code ~= 200 then error("Failed to download file from "..url) end
  if not textutils.unserialize(data) then error("Could not unserialize internet data from "..url) end
  return textutils.unserialize(data)
end

local function getNumericVersion(input)
  local toRet = 0
  local i = 5
  for a in input:gmatch("%d+") do
    toRet = toRet + tonumber(i)*100^i
  end
  return toRet
end
local gnv = getNumericVersion

