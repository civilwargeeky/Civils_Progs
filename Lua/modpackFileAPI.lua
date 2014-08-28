--These are just some nice functions to have when working with files

function add(input, toAdd) 
  if not (input and toAdd) then error("add got "..tostring(input).." and "..tostring(toAdd),2) end
  if input:sub(-1) == "\\" then
    return input..toAdd 
  else 
    return input.."\\"..toAdd
  end 
end --Simplifies folders
function sanitize(input)
  if input:match(" ") then --If input has a space in it
    return "\""..input.."\"" --Return it with surrounding quotes
  end
  return input --Else just return
end
string.add = add --So I can use ":"
string.sanitize = sanitize
string.san = sanitize --Alias
function exists(path) --Check if the file exists. Note: This fails if the folder in question is open in explorer
  return os.rename(path,path) and true or false
end
function copyFile(file, dest)
  return os.execute("copy /y "..file:san().." "..dest:add(file:match("\\[^\\]-$"):sub(2,-1)):san()) --Matching stuff so you just specify what folder it goes in, not full file name
end
function copyDir(folder, dest)
  return os.execute("xcopy /e /y /i /q "..folder:san().." "..dest:add(folder:match("\\[^\\]-$"):sub(2,-1)):san())
end
function rmFile(file)
  return os.execute("del /q "..file:san())
end
function rmDir(folder)
  return os.execute("rd /s /q "..folder:san())
end
function mkDir(folder)
  return os.execute("mkdir "..folder:san())
end
function getDir() --Returns the current working directory
  return getRet("cd")
end

function scan(dir, switchString) --Returns an iterator that goes through all the files in a directory
  dir, switchString = dir or "", switchString or ""
  return io.popen("dir /b "..switchString.." "..dir:san()):lines()
end
function countFiles(dir, switchString) --Just counts the number of files and or folders
  local toRet = 0
  for i in scan(dir,switchString) do
    toRet = toRet + 1
  end
  return toRet
end
function getRet(input) --Gets the the return statement of a windows command
  local a=io.popen(input); return a:read(), a:close()
end

local function retCall(file) --I think this iterates through the lines of a file in the return statement, so return line1, line2, line3, etc
  local toRet = file:read()
  if toRet then return toRet, retCall(file) else return file:close() end
end
function getNameAndVersion(file)--This block gets the modpack name and version number from file
  if not exists(file) then return "nil", "0" end
  local versions = io.open(file ,"r") 
  return retCall(versions) --First line, second line, close
end
function splitVersion(version) --This should work on all number separated by anything
  local toRet = {}
  for a in version:gmatch("%d+") do
    table.insert(toRet, tonumber(a))
  end
  return toRet
end
function compareVersions(in1, in2) --Returns true if first is greater than, false otherwise
  for i=1, math.min(#in1,#in2) do
    if in1[i] > in2[i] then return true end
  end
  return false
end
