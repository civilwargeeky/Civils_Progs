--[[This will feature a "graphical" menu that has selection options for edit config file, read logs, and start quarry.
The edit mode will just call shell.run("edit", filename)
Reading the logs will have a number with arrows on either side. You can press left or right to increase/decrease the number, then press enter to print the contents of the log to the screen.
Start the quarry. This will read options from the config file and write them as parameters and call shell.run("quarry"). This will also be the first option 
IDEA: You can have multiple different config files so you could say "shell quarry bigMine" or "shell quarry 9x9"
These will be registered in a config file specific to this program.]]
--Will have optional parameter of "-quarry" to just run a quarry from the config file.

--Changing global namespace to avoid conflicts
globalTable = nil; _G.globalTable = {}; setmetatable(globalTable, {__index = getfenv(1)}); setfenv(1,globalTable)

--Filenames
names = {
config = "Civil_Quarry_Config",
quarry = "quarry",
logFolder = "Quarry_Logs",
logPrefix = "Quarry_Log_",
logSuffix = "",
prompt = "Name of Quarry: ",
}

term.clear()
term.setCursorPos(1,1)
print("Welcome to the interactive quarry config maker!")
print("You will be able to edit and save mining configurations, but for now, you are only able to save and load one.")
print("In fact, as of now, the only way to run the quarry with this config is 'loader quarry'")
print("Anyway, press \"o\" when you're done reading, and it will bring up an editor")
repeat until ({os.pullEvent("char")})[2] == "o"

local function newConfig(name)
local file = fs.open(names.config,"w")
file.write("--Welcome to the quarry editor!--\n")
file.write("--Enter in parameters you would give to the turtle below\n")
file.write("--Example: -dim 12 12 12\n")
file.write("--Also, please fill in what you named the quarry program below.\n")
file.write(names.prompt.."\n")
file.close()
shell.run("clear")
shell.run("edit", names.config)
print("Oh yeah, still running...")
end
local function runQuarry(file)
local file = fs.open(names.config,"r")
local text = file.readAll()
file.close()
local start, conditionsStart = text:find(names.prompt.."%C+\n")
names.quarry = text:sub(start + #(names.prompt) ,conditionsStart - 1)
local textToParse, textToLoad = text:sub(conditionsStart+1,#text), '"'..names.quarry..'",'
for a in textToParse:gmatch("[%w\-?]+") do
  textToLoad = textToLoad..'"'..a..'",'
end
textToLoad = textToLoad:sub(1,#textToLoad - 1)
print(textToLoad)
os.pullEvent()
setfenv(assert(loadstring("shell.run("..textToLoad..")")),getfenv(1))()
end

tArgs = {...}
if tArgs[1] == "quarry" then
  runQuarry()
else
  newConfig()
end

--[[ Snippet for finding the number of logs
  local i = 0
  repeat
    i = i + 1
  until not fs.exists(names.logFolder.."/..names.logPrefix..tostring(i)..(names.logSuffix))
  number = i]]