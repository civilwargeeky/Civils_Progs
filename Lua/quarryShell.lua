--[[This will feature a "graphical" menu that has selection options for edit config file, read logs, and start quarry.
The edit mode will just call shell.run("edit", filename)
Reading the logs will have a number with arrows on either side. You can press left or right to increase/decrease the number, then press enter to print the contents of the log to the screen.
Start the quarry. This will read options from the config file and write them as parameters and call shell.run("quarry"). This will also be the first option 
IDEA: You can have multiple different config files so you could say "shell quarry bigMine" or "shell quarry 9x9"
These will be registered in a config file specific to this program.]]
--Will have optional parameter of "-quarry" to just run a quarry from the config file.

--Changing global namespace to avoid conflicts
globalTable = nil; _G.globalTable = {}; setmetatable(globalTable, {__index = getfenv(1)}); setfenv(1,globalTable)

