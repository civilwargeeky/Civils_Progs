--Civilwargeeky's Quarry Program--
  VERSION = "3.6.4.5"
--[[
Recent Changes:
  Parameter Files! Create a file of parameters, and use -file to load it!
    Works will with -forcePrompt
  Quarry no longer goes to start at end of row!
  Turtle can go left!
  QuadCopters! Check Lyqyd's thread
New Parameters:
    -overfuel/fuelMultiplier [number]: This number is is what neededFuel is multiplied by when fuel is low.
    -version: This will display the current version number and end the program
    -file [fileName]: This will load a custom configuration file (basically a list of parameters). "##" starts comment lines. In the future "#" will start programs to run (but only through shell)
    -preciseTotals [t/f]: If true, turtle will write exactly what it mined to the logs. It may also transmit it over rednet.
    -forcePrompt [param]: This will add to a list of parameters to force prompt for. So if you say "-forcePrompt doRefuel" it will prompt you "Length","Width","Height","Invert","Do Refuel" etc.
]]
--Defining things
civilTable = nil; _G.civilTable = {}; setmetatable(civilTable, {__index = getfenv()}); setfenv(1,civilTable)
originalDay = os.day() --Used in logging
numResumed = 0 --Number of times turtle has been resumed
-------Defaults for Arguments----------
--Arguments assignable by text
x,y,z = 3,3,3 --These are just in case tonumber fails
inverted = false --False goes from top down, true goes from bottom up [Default false]
rednetEnabled = false --Default rednet on or off  [Default false]
--Arguments assignable by tArgs
dropSide = "front" --Side it will eject to when full or done [Default "front"]
careAboutResources = true --Will not stop mining once inventory full if false [Default true]
doCheckFuel = true --Perform fuel check [Default true]
doRefuel = false --Whenever it comes to start location will attempt to refuel from inventory [Default false]
keepOpen = 1 --How many inventory slots it will attempt to keep open at all times [Default 1]
fuelSafety = "moderate" --How much fuel it will ask for: safe, moderate, and loose [Default moderate]
excessFuelAmount = math.huge --How much fuel the turtle will get maximum. Limited by turtle.getFuelLimit in recent CC [Default math.huge]
fuelMultiplier = 1 --How much extra fuel turtle will ask for when it does need fuel [Default 1]
saveFile = "Civil_Quarry_Restore" --Where it saves restore data [Default "Civil_Quarry_Restore"]
autoResume = true --If true, turtle will auto-restart when loaded. [Default true]
startupRename = "oldStartup.quarry" --What the startup is temporarily renamed to [Default "oldStartup.quarry"]
startupName = "startup" --What the turtle auto-resumes with [Default "startup"]
doBackup = true --If it will keep backups for session persistence [Default true]
uniqueExtras = 8 --How many different items (besides cobble) the turtle expects. [Default 8]
maxTries = 200 --How many times turtle will try to dig a block before it "counts" bedrock [Default 200]
gpsEnabled = false -- If option is enabled, will attempt to find position via GPS api [Default false]
gpsTimeout = 3 --The number of seconds the program will wait to get GPS coords. Not in arguments [Default 3]
legacyRednet = false --Use this if playing 1.4.7
logging = true --Whether or not the turtle will log mining runs. [Default ...still deciding]
logFolder = "Quarry_Logs" --What folder the turtle will store logs in [Default "Quarry_Logs"]
logExtension = "" --The extension of the file (e.g. ".txt") [Default ""]
flatBedrock = false --If true, will go down to bedrock to set startDown [Default false]
startDown = 0 --How many blocks to start down from the top of the mine [Default 0]
preciseTotals = false --If true, will record exact totals and names for all materials [Default false]
goLeftNotRight = false --Quarry to left, not right (parameter is "left") [Default false]
oreQuarry = false --Enables ore quarry functionality [Default false]
oreQuarryBlacklistName = "oreQuarryBlacklist.txt" --This is the file that will be parsed for item names [Default "oreQuarryBlacklist"]
dumpCompareItems = true --If ore quarry, the turtle will dump items compared to (like cobblestone) [Default true]
frontChest = false --If oreQuarry and chest checking, you can turn this on to make turtle check in front of itself for chests as well [Default false]
lavaBuffer = 500 --If using a lava bucket, this is the buffer it will wait for before checking for lava [Default 500]
inventoryMax = 16 --The max number of slots in the turtle inventory [Default 16] (Not assignable by parameter)
quadEnabled = false --Whether or not to request a quadRotor when out of fuel [Default false]
quadTimeout = 60 * 5 --How long the turtle will wait for a quadRotor [Default 5 minutes]
--Standard number slots for fuel (you shouldn't care)
fuelTable = { --Will add in this amount of fuel to requirement.
safe = 1000,
moderate = 200,
loose = 0 } --Default 1000, 200, 0
--Standard rednet channels
channels = {
send = os.getComputerID() + 1  ,
receive = os.getComputerID() + 101 ,
confirm = "Turtle Quarry Receiver",
message = "Civil's Quarry",
fingerprint = "quarry"
}

--AVERAGE USER: YOU DON'T CARE BELOW THIS POINT

local help_paragraph = [[
Welcome!: Welcome to quarry help. Below are help entries for all parameters. Examples and tips are at the bottom.
-default: This will force no prompts. If you use this and nothing else, only defaults will be used.
-dim: [length] [width] [height] This sets the dimensions for the quarry
-invert: [t/f] If true, quarry will be inverted (go up instead of down)
-rednet: [t/f] If true and you have a wireless modem on the turtle, will attempt to make a rednet connection for sending important information to a screen
-restore / -resume: If your quarry stopped in the middle of its run, use this to resume at the point where the turtle was. Not guarenteed to work properly. For more accurate location finding, check out the -GPS parameter
-autoResume / autoRestore: Turtle will automatically resume if stopped. Replaces startup
-oreQuarry: [t/f] If true, the turtle will use ore quarry mode. It will not mine the blocks that are placed in the turtle initially. So if you put in stone, it will ignore stone blocks and only mine ores.
-oreQuarry: [t/f] If you are using a newer version of CC, you won't have to put in any compare blocks. (CC 1.64+)
-blacklist: [file name] If using oreQuarry, this is the blacklist file it will read. Example --
  minecraft:stone
  minecraft:sand
  ThermalExpansion:Sponge
  ThermalFoundation:Storage
  
  Note: If you have bspkrsCore, look 
  for "UniqueNames.txt" in your config
-file: [file name] Will load a file of parameters. One parameter per line. # is a comment line (See the forum thread for more detailed directions)
-atChest: [force] This is for use with "-restore," this will tell the restarting turtle that it is at its home chest, so that if it had gotten lost, it now knows where it is.
-doRefuel: [t/f] If true, the turtle will refuel itself with coal and planks it finds on its mining run
-doCheckFuel: [t/f] If you for some reason don't want the program to check fuel usage, set to false. This is honestly a hold-over from when the refueling algorithm was awful...
-overfuel: [number] When fuel is below required, fuel usage is multiplied by this. Large numbers permit more quarries without refueling
-fuelMultiplier: [number] See overfuel
-uniqueExtras: [number] The expected number of slots filled with low-stacking items like ore. Higher numbers request more fuel.
-maxFuel: [number] How much the turtle will fuel to max (limited by turtle in most cases)
-chest: [side] This specifies what side the chest at the end will be on. You can say "top", "bottom", "front", "left", or "right"
-enderChest: [slot] This one is special. If you use "-enderChest true" then it will use an enderChest in the default slot. However, you can also do "-enderChest [slot]" then it will take the ender chest from whatever slot you tell it to. Like 7... or 14... or whatever.
-fuelChest: [slot] See the above, but for a fueling chest. Reccommend use with -maxFuel and -doCheckFuel false
-lava: [slot] If using an oreQuarry, will fill itself with lava it finds to maxFuel
-lavaBuffer: [number] The amount of fuel below maxFuel the turtle will wait for before using lava again
-GPS: [force] If you use "-GPS" and there is a GPS network, then the turtle will record its first two positions to precisly calculate its position if it has to restart. This will only take two GPS readings
-quad: [t/f] This forces the use of GPS. Make sure you have a network set up. This will request to be refueled by a quadrotor from Lyqyd's mod if the turtle is out of fuel
-quadTimeout: [number] The amount of time the turtle will wait for a quadRotor
-sendChannel: [number] This is what channel your turtle will send rednet messages on
-receiveChannel: [number] This is what channel your turtle will receive rednet messages on
-legacyRednet: [t/f] Check true if using 1.4.7
-startY: [current Y coord] Randomly encountering bedrock? This is the parameter for you! Just give it what y coordinate you are at right now. If it is not within bedrock range, it will never say it found bedrock
-startupRename: [file name] What to rename any existing startup to.
-startupName: [file name] What the turtle will save its startup file to.
-extraDropItems: [force] If oreQuarry then this will prompt the user for extra items to drop, but not compare to (like cobblestone)
-dumpCompareItems: [t/f] If oreQuarry and this is true, the turtle will dump off compare blocks instead of storing them in a chest
-oldOreQuarry: [t/f] If you are using new CC versions, you can use this to use the old oreQuarry.
-compareChest: [slot] If using oldOreQuarry, this will allow you to check for dungeon chests and suck from them.
-frontChest: [t/f] If using oreQuarry/oldOreQuarry, this will check in front of itself for chests as well.
-left: [t/f] If true, turtle will quarry to the left instead of the right
-maxTries: [number] This is the number of times the turtle will try to dig before deciding its run into bedrock.
-forcePrompt: [parameter] Whatever parameter you specify, it will always prompt you, like it does now for invert and dim.
-logging: [t/f] If true, will record information about its mining run in a folder at the end of the mining run
-preciseTotals: [t/f] If true (and turtle.inspect exists), it will log a detailed record of every block the turtle mines and send it over rednet
-doBackup: [t/f] If false, will not back up important information and cannot restore, but will not make an annoying file (Actually I don't really know why anyone would use this...)
-saveFile: [word] This is what the backup file will be called
-logFolder: [word] The folder that quarry logs will be stored in
-logExtension: [word] The extension given to each quarry log (e.g. ".txt" or ".notepad" or whatever)
-keepOpen: [number] This is the number of the slots the turtle will make sure are open. It will check every time it mines
-careAboutResources: [t/f] Who cares about the materials! If set to false, it will just keep mining when its inventory is full
-startDown: [number] If you set this, the turtle will go down this many blocks from the start before starting its quarry
  =
  C _ |
      |
      |
      |
      |_ _ _ _ >
-flatBedrock: [t/f] If true, turtle will find bedrock and "zero" itself so it ends on bedrock level
-promptAll: This is the opposite of -Default, it prompts for everything
-listParams: This will list out all your selected parameters and end quarry. Good for testing
-manualPos: [xPos] [zPos] [yPos] [facing] This is for advanced use. If the server reset when the turtle was in the middle of a 100x100x100 quarry, fear not, you can now manually set the position of the turtle. yPos is always positive. The turtle's starting position is 0, 1, 1, 0. Facing is measured 0 - 3. 0 is forward, and it progresses clockwise. Example- "-manualPos 65 30 30 2"
-version: Displays the current quarry version and stops the program
-help: Thats what this is :D
Examples: Everything below is examples and tips for use
Important Note:
  None of the above parameters are necessary. They all have default values, and the above are just if you want to change them.
Examples [1]:
  Want to just start a quarry from the interface, without going through menus? It's easy! Just use some parameters. Assume you called the program "quarry." To start a 10x6x3 quarry, you just type in "quarry -dim 10 6 3 -default".
  You just told it to start a quarry with dimensions 10x6x3, and "-default" means it won't prompt you about invert or rednet. Wasn't that easy?
Examples [2]:
  Okay, so you've got the basics of this now, so if you want, you can type in really long strings of stuff to make the quarry do exactly what you want. Now, say you want a 40x20x9, but you want it to go down to diamond level, and you're on the surface (at y = 64). You also want it to send rednet messages to your computer so you can see how its doing.
Examples [2] [cont.]:
  Oh yeah! You also want it to use an ender chest in slot 12 and restart if the server crashes. Yeah, you can do that. You would type
  "quarry -dim 40x20x9 -invert false -startDown 45 -rednet true -enderChest 12 -restore"
  BAM. Now you can just let that turtle do it's thing
Tips:
  The order of the parameters doesn't matter. "quarry -invert false -rednet true" is the same as "quarry -rednet true -invert false"
  
  Capitalization doesn't matter. "quarry -iNVErt FALSe" does the same thing as "quarry -invert false"
Tips [cont.]:
  For [t/f] parameters, you can also use "yes" and "no" so "quarry -invert yes"
  
  For [t/f] parameters, it only cares about the first letter. So you can use "quarry -invert t" or "quarry -invert y"
Tips [cont.]:
  If you are playing with fuel turned off, the program will automatically change settings for you so you don't have to :D
  
  If you want, you can load this program onto a computer, and use "quarry -help" so you can have help with the parameters whenever you want.
Internal Config:
  At the top of this program is an internal configuration file. If there is some setup that you use all the time, you can just change the config value at the top and run "quarry -default" for a quick setup.
  
  You can also use this if there are settings that you don't like the default value of.
]]
--NOTE: BIOS 114 MEANS YOU FORGOT A COLON
--NOTE: THIS ALSO BREAKS IF YOU REMOVE "REDUNDANT" WHITESPACE
--Parsing help for display
--[[The way the help table works:
All help indexes are numbered. There is a help[i].title that contains the title,
and the other lines are in help[i][1] - help[i][#help[i] ]
Different lines (e.g. other than first) start with a space.
As of now, the words are not wrapped, fix that later]]
local help = {}
local i = 0
local titlePattern = ".-%:" --Find the beginning of the line, then characters, then a ":"
local textPattern = "%:.+" --Find a ":", then characters until the end of the line
for a in help_paragraph:gmatch("\n?.-\n") do --Matches in between newlines
  local current = string.sub(a,1,-2).."" --Concatenate Trick
  if string.sub(current,1,1) ~= " " then
    i = i + 1
    help[i] = {}
    help[i].title = string.sub(string.match(current, titlePattern),1,-2)..""
    help[i][1] = string.sub(string.match(current,textPattern) or " ",3,-1)
  elseif string.sub(current,1,1) == " " then
    table.insert(help[i], string.sub(current,2, -1).."")
  end
end

local supportsRednet
if peripheral.find then
  supportsRednet = peripheral.find("modem") or false
else
  supportsRednet = (peripheral.getType("right") == "modem") or false
end

--Pre-defining variables that need to be saved
      xPos,yPos,zPos,facing,percent,mined,moved,relxPos, rowCheck, connected, isInPath, layersDone, attacked, startY, chestFull, gotoDest, atChest, fuelLevel, numDropOffs, allowedItems, compareSlots, dumpSlots, selectedSlot, extraDropItems, oldOreQuarry, specialSlots, relzPos, eventInsertionPoint
    = 0,   1,   1,   0,     0,      0,    0,    1,       true   ,  false,     true,     1,          0,        0,      false,     "",       false,   0,         0,           {},             {},           {},      1,            false,          false,        {explicit = {}},    0, 1

--These are slot options that need to exist as variables for parameters to work.
  enderChest, fuelChest, lavaBucket, compareChest
= false,      false,     false,      false

local chestID, lavaID, lavaMeta = "minecraft:chest", "minecraft:flowing_lava", 0

local statusString

--Initializing various inventory management tables
for i=1, inventoryMax do
  allowedItems[i] = 0 --Number of items allowed in slot when dropping items
  dumpSlots[i] = false --Does this slot contain junk items?
end --compareSlots is a table of the compare slots, not all slots with a condition
totals = {cobble = 0, fuel = 0, other = 0} -- Total for display (cannot go inside function), this goes up here because many functions use it

local function newSpecialSlot(index, value, explicit) --If isn't explicit, it will move whatever is already in the slot around to make room.
  value = tonumber(value) or 0 --We only want numerical indexes
  local flag = false --Used in slot moving, moved slot is returned for ease of use
  local function check(num) return num >= 1 and num <= inventoryMax end
  if not check(value) then error("from newSpecialSlot: number "..value.." out of range",2) end
  local function getFirstFree(start)
    for i=1, math.max(inventoryMax-value,value-1) do
      for a=-1,1,2 do
        local num = value + (a*i)
        if check(num) and not specialSlots[num] then return num end
      end
    end
    return false
  end
  if specialSlots[value] and specialSlots[value] ~= index then --If we aren't trying to override the same slot :P
    if not explicit then
      value = getFirstFree(value) or error("from newSpecialSlots: all slots full, could not add")
    elseif explicit and not specialSlots.explicit[value] then --Moving around other slots
      flag = getFirstFree(value)
      if not flag then error("from newSpecialSlots: could not add explicit in slot: "..index.." "..value.." Taken by "..specialSlots[value],2) end
      specialSlots[flag] = specialSlots[value]
      specialSlots[specialSlots[value]] = flag --These will get set to the new thing later
    else
      error('You cannot put a "'..index..'" in the same slot as a "'..specialSlots.explicit[value]..'" (Slot '..value..")",0) --Show the user an understandable error :)
    end
  end
  specialSlots[index] = value
  specialSlots[value] = index
  if explicit then
    specialSlots.explicit[value] = index
  end
  return value, flag
end

function resetDumpSlots()
    for i=1, inventoryMax do
      if oldOreQuarry then
        if turtle.getItemCount(i) > 0 and i~= specialSlots.enderChest then
          dumpSlots[i] = true
        else
          dumpSlots[i] = false
        end
      else
        dumpSlots[i] = false
      end
    end
    if not oldOreQuarry and specialSlots.enderChest == 1 then
      dumpSlots[2] = true
    elseif not oldOreQuarry then
      dumpSlots[1] = true
    end
end

local function copyTable(tab) if type(tab) ~= "table" then error("copyTable received "..type(tab)..", expected table",2) end local toRet = {}; for a, b in pairs(tab) do toRet[a] = b end; return toRet end --This goes up here because it is a basic utility

--NOTE: rowCheck is a bit. true = "right", false = "left"

local foundBedrock = false

local checkFuel, checkFuelLimit
if turtle then --Function inits
  checkFuel = turtle.getFuelLevel
  if turtle.getFuelLevel() == "unlimited" then --Fuel is disabled --Unlimited screws up my calculations
    checkFuel = function() return math.huge end --Infinite Fuel
  end --There is no "else" because it will already return the regular getFuel
  if turtle.getFuelLimit then
    checkFuelLimit = function() return math.min(turtle.getFuelLimit(), excessFuelAmount) end --Return the limiting one
    if turtle.getFuelLimit() == "unlimited" then
      checkFuelLimit = function() return math.huge end
    end
  else
    checkFuelLimit = function() return excessFuelAmount end --If the function doesn't exist
  end


  turtle.select(1) --To ensure this is correct
end


function select(slot)
  if slot ~= selectedSlot and slot > 0 and slot <= inventoryMax then
    selectedSlot = slot
    return turtle.select(slot), selectedSlot
  end
end


 -----------------------------------------------------------------
--Input Phase
local function screen(xPos,yPos)
xPos, yPos = xPos or 1, yPos or 1
term.setCursorPos(xPos,yPos); term.clear(); end
local function screenLine(xPos,yPos)
term.setCursorPos(xPos,yPos); term.clearLine(); end

screen(1,1)
print("----- Welcome to Quarry! -----")
print("")

local sides = {top = "top", right = "right", left = "left", bottom = "bottom", front = "front"} --Used to whitelist sides
local tArgs --Will be set in initializeArgs
local originalArgs = {...}
local changedT, tArgsWithUpper, forcePrompts = {}, {}, {}
changedT.new = function(key, value, name) table.insert(changedT,{key, value, name}); if name then changedT[name] = #changedT end end --Numeric list of lists
changedT.remove = function(num) changedT[num or #changedT].hidden = true end --Note actually remove, just hide :)
local function capitalize(text) return (string.upper(string.sub(text,1,1))..string.sub(text,2,-1)) end
local function initializeArgs()
  tArgs = copyTable(originalArgs) --"Reset" tArgs
  for i=1, #tArgs do --My signature key-value pair system, now with upper
    tArgsWithUpper[i] = tArgs[i]
    tArgsWithUpper[tArgsWithUpper[i]] = i
    tArgs[i] = tArgs[i]:lower()
    tArgs[tArgs[i]] = i
    if tArgs[i] == "-forceprompt" and i ~= #tArgs then --If the prompt exists then add it to the list of prompts
      forcePrompts[tArgs[i+1]:lower()] = true
    end
  end
end
initializeArgs()

local restoreFound, restoreFoundSwitch = false --Initializing so they are in scope
function parseParam(name, displayText, formatString, forcePrompt, trigger, variableOverride, variableExists) --Beware confusion, all ye who enter here
  --[[ Guide to Variables
    originalValue: what the variable was before the function
    givenValue: This is the value after the parameter. So -invert fAlSe, givenValue is "fAlSe"
  ]]
  if variableExists ~= false then variableExists = true end --Almost all params should have the variable exist. Some don't exist unless invoked
  if trigger == nil then trigger = true end --Defaults to being able to run
  if not trigger then return end --This is what the trigger is for. Will not run if trigger not there
  if restoreFoundSwitch or tArgs["-default"] then forcePrompt = false end --Don't want to prompt if these. Default is no variable because resuming
  if not restoreFoundSwitch and (tArgs["-promptall"] or forcePrompts[name:lower()]) then forcePrompt = true end --Won't prompt if resuming, can prompt all or checks list of prompts
  local toGetText = name:lower() --Because all params are now lowered
  local formatType = formatString:match("^%a+"):lower() or error("Format String Unknown: "..formatString) --Type of format string
  local args = formatString:match(" (.+)") or "".."" --Everything in formatString after the type
  local variable = variableOverride or name --Goes first to the override for name
  local func = loadstring("return "..variable) --Note to future self: If you want to remove loadstring, this breaks on tables. You will have to remove tables or figure something else out
  setfenv(func,getfenv(1))
  local originalValue = assert(func)() --This is the default value, for checking to add to changed table
  if originalValue == nil and variableExists then error("From addParam, \""..variable.."\" returned nil",2) end --I may have gotten a wrong variable name
  local givenValue, toRet, values --Initializing for use
  if tArgs["-"..toGetText] then
    givenValue = tArgsWithUpper[tArgs["-"..toGetText]+1] --This is the value after the desired parameter
  elseif forcePrompt then
    write(displayText.."? ")
    givenValue = io.read()
  end
  if formatType == "force" then --This is the one exception. Should return true if givenValue is nothing
    toRet = (tArgs["-"..toGetText] and true) or false --Will return true if param exists, otherwise false
  end
  if not (givenValue or toRet) or (type(givenValue) == "string" and #givenValue == 0) then return end --Don't do anything if you aren't given anything. Leave it as default, except for "force". Also don't want empty strings
  if formatType == "boolean" then --All the format strings will be basically be put through a switch statement
    toRet = givenValue:sub(1,1):lower() ~= "n" and givenValue:sub(1,1):lower() ~= "f" --Accepts anything but false or no
  elseif formatType == "string" then
    toRet = givenValue:match("^[%w%./]+") --Basically anything not a space or control character etc
  elseif formatType == "number" or formatType == "float" then
    toRet = tonumber(givenValue) --Note this is a local, not the above so we don't change anything
    if not toRet then return end --We need a number... Otherwise compare errors
    if formatType == "number" then toRet = math.floor(toRet) end --Get proper integers
    local startNum, endNum = formatString:match("(%d+)%-(%d+)") --Gets range of numbers
    startNum, endNum = tonumber(startNum), tonumber(endNum)
    if not ((toRet >= startNum) and (toRet <= endNum)) then return end --Can't use these
  elseif formatType == "side" then
    local exclusionTab = {} --Ignore the wizardry here. Just getting arguments without format string
    for a in args:gmatch("%S+") do exclusionTab[a] = true end --This makes a list of the sides to not include
    if not exclusionTab[givenValue] then toRet = sides[givenValue] end --If side is not excluded
  elseif formatType == "list" then
    toRet = {}
    for a in args:gmatch("[^,]") do
      table.insert(toRet,a)
    end
  elseif formatType == "slot" then
    if givenValue:sub(1,1):lower() == "n" or givenValue:sub(1,1):lower() == "f" then --Copied from boolean
      toRet = false
    else
      local userNumber, correction = givenValue:match("^%d+$") --This makes sure the value is a number | Locally initialize correction
      toRet, correction = newSpecialSlot(variable, tonumber(userNumber or args), userNumber) --If givenValue was "true", it won't be explicit and will use default number
      if correction then changedT[changedT[specialSlots[correction]]][2] = tostring(correction) end --This changes the value field of the changedT index taken from the named pointer (which is the value in specialSlots under correction)
    end
  elseif formatType == "force" then --Do nothing, everything is already done
  else error("Improper formatType",2)
  end
  if toRet == nil then return end --Don't want to set variables to nil... That's bad
  tempParam = toRet --This is what loadstring will see :D
  local func = loadstring(variable.." = tempParam")
  setfenv(func, getfenv(1)) --Note to future self: If you want to remove loadstring, this breaks on tables. You will have to remove tables or figure something else out
  func()
  tempParam = nil --Cleanup of global
  if toRet ~= originalValue and displayText ~= "" then
    changedT.new(displayText, tostring(toRet), variable)
  end
  return toRet
end

local paramLookup = {}
local function addParam(...)
  local args = {...}
  if not paramLookup[args[1]] then
    local toRet = copyTable(args)
    for i=2, table.maxn(toRet) do --Have to do this because table.remove breaks on nil
      toRet[i-1] = toRet[i]
    end
    table.remove(toRet)
    paramLookup[args[1]] = toRet
  end
  return parseParam(unpack(args, 1, table.maxn(args)))
end

local function paramAlias(original, alias)
  local a = paramLookup[original]
  if a then
    if a[5] == nil then a[5] = original end --This is variableOverride because the originals won't put a variable override
    return parseParam(alias, unpack(a, 1, table.maxn(a)))
  else
    error("In paramAlias: '"..original.."' did not exist",2)
  end
end

--Check if it is a turtle
if not(turtle or tArgs["help"] or tArgs["-help"] or tArgs["-?"] or tArgs["?"]) then --If all of these are false then
  print("This is not a turtle, you might be looking for the \"Companion Rednet Program\" \nCheck My forum thread for that")
  print("Press 'q' to quit, or any other key to start help ")
  if ({os.pullEvent("char")})[2] ~= "q" then tArgs.help = true else error("",0) end
end

if tArgs["help"] or tArgs["-help"] or tArgs["-?"] or tArgs["?"] then
  print("You have selected help, press any key to continue"); print("Use arrow keys to navigate, q to quit"); os.pullEvent("key")
  local pos = 1
  local key = 0
  while pos <= #help and key ~= keys.q do
    if pos < 1 then pos = 1 end
    screen(1,1)
    print(help[pos].title)
    for a=1, #help[pos] do print(help[pos][a]) end
    repeat
      _, key = os.pullEvent("key")
    until key == 200 or key == 208 or key == keys.q
    if key == 200 then pos = pos - 1 end
    if key == 208 then pos = pos + 1 end
  end
  error("",0)
end

if tArgs["-version"] or tArgs["version"] then
  print("QUARRY VERSION: ",VERSION)
  error("",0) --Exit not so gracefully
end

--Loading custom parameter lists
local function split(str, sep)
  assert(#sep == 1, "Split seperator too long. Got '"..sep.."'")
  if not str:match(sep) then return {str} end --So everything else isn't pointless
  local toRet = {}
  toRet[1] = str:match("^([^"..sep.."]-)"..sep)
  for i in str:gmatch(sep.."([^"..sep.."]*)") do --Matches not seperator chars
    toRet[#toRet+1] = i
  end
  return toRet
end

if addParam("file","Custom Parameters","string", false, nil, "parameterFile", false) and parameterFile then --This will not load when resuming because there is no "file" parameter when resuming.
  if not fs.exists(parameterFile) then
    print("WARNING: '"..parameterFile.."' DOES NOT EXIST. FILE NOT LOADED")
    sleep(3)
    changedT.remove()
  else
    local file = fs.open(parameterFile, "r")
    local text = file.readAll()
    file.close()
    text = text.."\n" --So that all replacements work properly
    text = text:gsub("#[^\n]-\n","") --Replace program codes/comment lines+
    local commands = {} --Contains all the parameters
    local append = table.insert
    for _, a in pairs(split(text,"\n")) do
      local words = split(a," ")
      if not a:match("-") then --This means only one command per line
        append(originalArgs,"-"..words[1])
        for i=2, #words do
          append(originalArgs, words[i])
        end
      else --Otherwise the dashes are already ordered where we want!
        for i=1, #words do
          append(originalArgs, words[i])
        end
      end
    end
    initializeArgs() --Manipulate the args again, because we modified them
    print("Finished loading file: ",tArgs[tArgs["-file"]+1])
    sleep(0.5) --Give em a sec
  end
end



--Saving
addParam("doBackup", "Backup Save File", "boolean")
addParam("saveFile", "Save File Name", "string")

restoreFound = fs.exists(saveFile)
restoreFoundSwitch = (tArgs["-restore"] or tArgs["-resume"] or tArgs["-atchest"]) and restoreFound and doBackup
if restoreFoundSwitch then
  local file = fs.open(saveFile,"r")
  local test = file.readAll() ~= ""
  file.close()
  if test then
    local temp = shell and copyTable(shell) --For whatever reason, the shell table doesn't survive resuming. shell and ... so that copyTable doesn't error
    os.run(getfenv(1),saveFile) --This is where the actual magic happens
    shell = temp
    numResumed = numResumed + 1
    if checkFuel() ~= math.huge then --If turtle uses fuel
      if fuelLevel - checkFuel() == 1 then
        if facing == 0 then xPos = xPos + 1
        elseif facing == 2 then xPos = xPos - 1
        elseif facing == 1 then zPos = zPos + 1
        elseif facing == 3 then zPos = zPos - 1 end
      elseif fuelLevel - checkFuel() ~= 0 then
        print("Very Strange Fuel in Restore Section...")
        print("Current: ",checkFuel())
        print("Saved: ",fuelLevel)
        print("Difference: ",fuelLevel - checkFuel())
        os.pullEvent("char")
      end
     end
    if gpsEnabled then --If it had saved gps coordinates
      print("Found GPS Start Coordinates")
      local currLoc = {gps.locate(gpsTimeout)} or {}
      local backupPos = {xPos, yPos, zPos} --This is for comparing to later
      if #currLoc > 0 and #gpsStartPos > 0 and #gpsSecondPos > 0 then --Cover all the different positions I'm using
        print("GPS Position Successfully Read")
        if currLoc[1] == gpsStartPos[1] and currLoc[3] == gpsStartPos[3] then --X coord, y coord, z coord in that order
          xPos, yPos, zPos = 0,1,1
          if facing ~= 0 then turnTo(0) end
          print("Is at start")
        else
          if inverted then --yPos setting
          ------------------------------------------------FIX THIS
          end
          local a, b = copyTable(gpsStartPos), copyTable(gpsSecondPos) --For convenience
          local flag = true --So we can account for left quarry
          if b[3] - a[3] == -1 then--If went north (-Z)
            a[1] = a[1] - 1 --Shift x one to west to create a "zero"
            xPos, zPos = -currLoc[3] + a[3], currLoc[1] + -a[1]
          elseif b[1] - a[1] == 1 then--If went east (+X)
            a[3] = a[3] - 1 --Shift z up one to north to create a "zero"
            xPos, zPos = currLoc[1] + -a[1], currLoc[3] + -a[3]
          elseif b[3] - a[3] == 1 then--If went south (+Z)
            a[1] = a[1] + 1 --Shift x one to east to create a "zero"
            xPos, zPos = currLoc[3] + a[3], -currLoc[1] + a[3]
          elseif b[1] - a[1] == -1 then--If went west (-X)
            a[3] = a[3] + 1 --Shift z down one to south to create a "zero"
            xPos, zPos = -currLoc[1] + a[1], -currLoc[3] + a[3]
          else
            flag = false
            print("Improper Coordinates")
            print("GPS Locate Failed, Using Standard Methods")        ----Maybe clean this up a bit to use flags instead.
          end
          if flag and goLeftNotRight then --This accounts for left quarry (barred to left only because there might be errors in a regular, causing neg/0
            zPos = math.abs(zPos-1) + 1
          end
        end
        print("X Pos: ",xPos)
        print("Y Pos: ",yPos)
        print("Z Pos: ",zPos)
        print("Facing: ",facing)
        for i=1, 3, 2 do --We want 1 and 3, but 2 could be coming back to start.
          if backupPos[i] ~= currLoc[i] then
            events = {} --We want to remove event queue if not in proper place, so won't turn at end of row or things.
          end
        end
      else
        print("GPS Locate Failed, Using Standard Methods")
      end
    print("Restore File read successfully. Starting in 3"); sleep(3)
    end
  else
    fs.delete(saveFile)
    print("Restore file was empty, sorry, aborting")
    error("",0)
  end
else --If turtle is just starting
  events = {} --This is the event queue :D
  originalFuel = checkFuel() --For use in logging. To see how much fuel is REALLY used
end

--Dimensions
if tArgs["-dim"] then
  local a,b,c = x,y,z
  local num = tArgs["-dim"]
  x = tonumber(tArgs[num + 1]) or x; z = tonumber(tArgs[num + 2]) or z; y = tonumber(tArgs[num + 3]) or y
  if a ~= x then changedT.new("Length", x) end
  if c ~= z then changedT.new("Width", z) end
  if b ~= y then changedT.new("Height", y) end
elseif not (tArgs["-default"] or restoreFoundSwitch) then
  print("What dimensions?")
  print("")
  --This will protect from negatives, letters, and decimals
  term.write("Length? ")
  x = math.floor(math.abs(tonumber(io.read()) or x))
  term.write("Width? ")
  z = math.floor(math.abs(tonumber(io.read()) or z))
  term.write("Height? ")
  y = math.floor(math.abs(tonumber(io.read()) or y))
  changedT.new("Length",x); changedT.new("Width",z); changedT.new("Height",y)
end
--Params: parameter/variable name, display name, type, force prompt, boolean condition, variable name override
--Invert
addParam("flatBedrock","Go to bedrock", "boolean") --Not done before GPS because GPS only runs on restart
addParam("invert", "Inverted","boolean", true, not flatBedrock, "inverted") --Not flat bedrock, because invert will be set to false
addParam("startDown","Start Down","number 1-256", nil, not flatBedrock)
addParam("left","Left Quarry","boolean", nil, nil, "goLeftNotRight")
--Inventory
addParam("chest", "Chest Drop Side", "side front", nil, nil, "dropSide")
addParam("enderChest","Ender Chest Slot","slot 16") --Note: All slots can be 16 and they will auto-assign, but I feel it is less confusing if they are always the same
addParam("fuelChest","Fuel Chest Slot","slot 15")
--Rednet
addParam("rednet", "Rednet Enabled","boolean",true, supportsRednet, "rednetEnabled")
addParam("sendChannel", "Rednet Send Channel", "number 1-65535", false, supportsRednet, "channels.send")
addParam("receiveChannel","Rednet Receive Channel", "number 1-65535", false, supportsRednet, "channels.receive")
addParam("fingerprint","Sending Fingerprint", "string", false, supportsRednet, "channels.fingerprint")
addParam("legacyRednet","Legacy Rednet","boolean", false, supportsRednet)
--Quad Rotor --Must be before GPS
if addParam("quad", "Quad Rotor Enabled","boolean",nil, rednetEnabled, "quadEnabled") then --This returns true if param found :3
  gpsEnabled = true
end
addParam("quadTimeout","Quad Rotor Timeout","number 1-1000000", nil, quadEnabled) --The amount of time to wait for a quadRotor
--GPS
addParam("gps", "GPS Location Services", "force", nil, (not restoreFoundSwitch) and supportsRednet and not quadEnabled, "gpsEnabled" ) --Has these triggers so that does not record position if restarted.
if gpsEnabled and not restoreFoundSwitch then
  gpsStartPos = {gps.locate(gpsTimeout)} --Stores position in array
  gpsEnabled = #gpsStartPos > 0 --Checks if location received properly. If not, position is not saved
  if quadEnabled and not gpsEnabled then
    error("You have no GPS network. You may not use Quad Rotors",0)
  end
end
--Fuel
addParam("uniqueExtras","Unique Items", "number 0-15")
addParam("doRefuel", "Refuel from Inventory","boolean", nil, checkFuel() ~= math.huge) --math.huge due to my changes
addParam("doCheckFuel", "Check Fuel", "boolean", doCheckFuel and fuelChest, checkFuel() ~= math.huge) --Will prompt if doCheckFuel and fuelChest are on. Probably don't want
excessFuelAmount = excessFuelAmount or math.huge --Math.huge apparently doesn't save properly (Without saving, this is the config, on save it is actually set to nil if math.huge)
addParam("maxFuel", "Max Fuel", "number 1-999999999", maxFuel == checkFuelLimit() and fuelChest, checkFuel() ~= math.huge, "excessFuelAmount") --Will prompt if fuel chest and the limit isn't changed
addParam("fuelMultiplier", "Fuel Multiplier", "float 1-9001", nil, checkFuel() ~= math.huge)
paramAlias("fuelMultiplier","fuelRequestMultiplier")
paramAlias("fuelMultiplier","overFuel")
--Logging
addParam("logging", "Logging", "boolean")
addParam("logFolder", "Log Folder", "string")
addParam("logExtension","Log Extension", "string")
--Misc
addParam("startY", "Start Y","number 1-256")
addParam("maxTries","Tries Before Bedrock", "number 1-9001")
--Inventory
addParam("keepOpen", "Slots to Keep Open", "number 1-15")
addParam("careAboutResources", "Care About Resources","boolean")
addParam("preciseTotals","Precise Totals","boolean", rednetEnabled and turtle.inspect, turtle.getItemDetail ~= nil)
if preciseTotals and not restoreFoundSwitch then
  exactTotals = {} --Don't want to initialize if we aren't using this
end
--Auto Startup
addParam("autoResume", "Auto Resume", "boolean", nil, doBackup)
paramAlias("autoResume","autoRestart")
addParam("startupRename", "Startup Rename","string", nil, autoResume)
addParam("startupName", "Startup File", "string", nil, autoResume)
--Ore Quarry
addParam("oreQuarry", "Ore Quarry", "boolean" )
if oreQuarry and not turtle.inspect then
  oldOreQuarry = true
  oreQuarry = false
end
addParam("lavaBucket","Lava Bucket Slot", "slot 14", nil, oreQuarry)
paramAlias("lavaBucket","lava")
paramAlias("lavaBucket","lavaRefuel")
addParam("lavaBuffer","Lava Buffer","number 1-19999", nil, lavaBucket)
--Old Ore
addParam("oldOreQuarry", "Old Ore Quarry", "boolean")
addParam("dumpCompareItems", "Dump Compare Items", "boolean", nil, oldOreQuarry) --Do not dump compare items if not oreQuarry
addParam("extraDropItems", "", "force", nil, oldOreQuarry) --Prompt for extra dropItems
paramAlias("extraDropItems","extraDumpItems") --changed to Dump
addParam("compareChest","Compare Chest Slot","slot 13", nil, oldOreQuarry)
addParam("frontChest","Front Chest Check","boolean", nil, compareChest or turtle.insepect) --Does not need oreQuarry, but is similar (does need inspect if not compareChest)
--New Ore
addParam("blacklist","Ore Blacklist", "string", nil, oreQuarry, "oreQuarryBlacklistName")
paramAlias("blacklist","blacklistFile")
--Mod Related

--Extra
if tArgs["-testparams"] then
  screen()
  print("KEY: VALUE (VARIABLE)")
  for key, val in ipairs(changedT) do
    if not val.hidden then
      print(val[1],": ",val[2],"  (",val[3] or "",")")
    end
  end
  error("Done",0)
end
  

--for flatBedrock
if flatBedrock then
  inverted = false
end

--Auto Startup functions
local function doAutoResumeStuff()
  if fs.exists(startupName) then
    if fs.exists(startupRename) then fs.delete(startupRename) end
    fs.move(startupName, startupRename)
  end
  local file = fs.open(startupName,"w") --Startup File
  file.writeLine( --The below is on the left because spacing
[[
--This is an auto-generated startup
--Made by civilwargeeky's Variable Size Quarry
print("Now Resuming Quarry")
print("Press any key to quit. You have 5 seconds.")
function deleteStuff()
  fs.delete("]]..startupName..[[")
  if fs.exists("]]..startupRename..[[") then
    fs.move("]]..startupRename.."\",\""..startupName..[[")
  end
end
local event
if fs.exists("]]..saveFile..[[") then
  for i=5,1,-1 do
    print(i)
    os.startTimer(1)
    event = os.pullEvent()
    if event == "key" then break end
  end
  if event == "timer" then
    os.run({},"]]..shell.getRunningProgram()..[[","-resume")
  else

    deleteStuff()
  end
else
  print("Never mind, no save file found")
  deleteStuff()
end
  ]])
  file.close()
end
if autoResume and not restoreFoundSwitch then --Don't do for restore because would overwrite renamed thing. Can't edit mid-run because no shell in restarted
  doAutoResumeStuff()
end
--oreQuarry blacklist
local blacklist = { "minecraft:air",  "minecraft:bedrock", "minecraft:cobblestone", "minecraft:dirt", "minecraft:ice", "minecraft:ladder", "minecraft:netherrack", "minecraft:sand", "minecraft:sandstone",
  "minecraft:snow", "minecraft:snow_layer", "minecraft:stone", "minecraft:gravel", "minecraft:grass", "minecraft:torch" }
for a,b in pairs(copyTable(blacklist)) do
  blacklist[b], blacklist[a] = true, nil --Switch
end
if fs.exists(oreQuarryBlacklistName) then --Loading user-defined blacklist
  local file = fs.open(oreQuarryBlacklistName, "r")
  blacklist = {}
  for a in file:readAll():gmatch("[^,\n]+") do
    blacklist[a:match("[%w_.]+:[%w_.]+")] = true --Grab only the actual characters, not whitespaces
  end
  file:close()
end

--Manual Position
if tArgs["-manualpos"] then --Gives current coordinates in xPos,zPos,yPos, facing
  local a = tArgs["-manualpos"]
  xPos, zPos, yPos, facing = tonumber(tArgs[a+1]) or xPos, tonumber(tArgs[a+2]) or zPos, tonumber(tArgs[a+3]) or yPos, tonumber(tArgs[a+4]) or facing
  changedT.new("xPos",xPos); changedT.new("zPos",zPos); changedT.new("yPos",yPos); changedT.new("facing",facing)
  restoreFoundSwitch = true --So it doesn't do beginning of quarry behavior
  for i=0,4 do tArgs[a+i] = "" end --Get rid of this argument from future restores
end
if addParam("atChest", "Is at Chest", "force") then --This sets position to 0,1,1, facing forward, and queues the turtle to go back to proper row.
  local neededLayer = math.floor((yPos+1)/3)*3-1 --Make it a proper layer, +- because mining rows are 2, 5, etc.
  if neededLayer > 2 and neededLayer%3 ~= 2 then --If turtle was not on a proper mining layer
    print("Last known pos was not in proper layer, restarting quarry")
    sleep(4)
    neededLayer = 2
  end
  xPos, zPos, yPos, facing, rowCheck, layersDone = 0,1,1, 0, true, math.ceil(neededLayer/3)
  doAutoResumeStuff() --This was probably deleted when they hit a key to launch with -atChest
  events = {{"goto",1,1,neededLayer, 0}}
end


local function saveProgress(extras) --Session persistence
exclusions = { modem = true, shell = true, _ENV = true}
if doBackup then
local toWrite = ""
for a,b in pairs(getfenv(1)) do
  if not exclusions[a] then
      --print(a ,"   ", b, "   ", type(b)) --Debug
    if type(b) == "string" then b = "\""..b.."\"" end
    if type(b) == "table" then b = textutils.serialize(b) end
    if type(b) ~= "function" then
      toWrite = toWrite..a.." = "..tostring(b).."\n"
    end
  end
end
toWrite = toWrite.."doCheckFuel = false\n" --It has already used fuel, so calculation unnecessary
local file
repeat
  file = fs.open(saveFile,"w")
until file
file.write(toWrite)
if type(extras) == "table" then
  for a, b in pairs(extras) do
    file.write(a.." = "..tostring(b).."\n")
  end
end
if checkFuel() ~= math.huge then --Used for location comparing
  file.write("fuelLevel = "..tostring(checkFuel()).."\n")
end
file.close()
end
end

local area = x*z
local volume = x*y*z
local lastHeight = y%3
layers = math.ceil(y/3)
local yMult = layers --This is basically a smart y/3 for movement
local moveVolume = (area * yMult) --Kept for display percent
--Calculating Needed Fuel--
do --Because many local variables unneeded elsewhere
  local changeYFuel = 2*(y + startDown)
  local dropOffSupplies = 2*(x + z + y + startDown) --Assumes turtle as far away as possible, and coming back
  local frequency = math.ceil(((moveVolume/(64*(15-uniqueExtras) + uniqueExtras)) ) ) --This is complicated: volume / inventory space of turtle, defined as 64*full stacks + 1 * unique stacks.
                                                                                     --max of 15 full stacks because once one item is picked up, slot is "full". Ceil to count for initial back and forth
  if enderChest then frequency = 0 end --Never goes back to start
  neededFuel = moveVolume + changeYFuel + (frequency * dropOffSupplies) + ((x + z) * layers) --x + z *layers because turtle has to come back from far corner every layer
  neededFuel = neededFuel + fuelTable[fuelSafety] --For safety
end

if neededFuel > checkFuelLimit() and doCheckFuel then--Checks for if refueling goes over turtle fuel limit
  if not (doRefuel or fuelChest) then
    screen()
    print("Turtle cannot hold enough fuel\n")
    print("Options: \n1. Select a smaller size \n2. Enable Mid-Run Refueling (RECOMMENDED) \n3. Turn fuel checking off (only if fuel chest) \n4. Do nothing")
    local _, key = os.pullEvent("char")
    if key == "1" then
      screen(); print("Okay"); error("",0)
    elseif key == "3" then
      doCheckFuel = false
    elseif key == "4" then
      --pass
    else --Not for number two because this is default
      doRefuel = true
    end
  end
  neededFuel = checkFuelLimit()-checkFuel()-1
end


--Getting Fuel
local hasRefueled --This is for oldOreQuarry prompting
if doCheckFuel and checkFuel() < neededFuel then
  neededFuel = math.min(math.floor(neededFuel * fuelMultiplier), checkFuelLimit()-checkFuel()-1) --Does the same as above, but not verbose because optional
  hasRefueled = true
  print("Not enough fuel")
  print("Current: ",checkFuel()," Needed: ",neededFuel)
  print("Starting SmartFuel...")
  sleep(2) --So they can read everything.
  term.clear()
  local oneFuel, neededFuelItems = 0,0 --Initializing Variables
  local currSlot = 0
  local function output(text, x, y) --For displaying fuel statistics
    local currX, currY = term.getCursorPos()
    term.setCursorPos(x,y)
    term.clearLine()
    term.write(text)
    term.setCursorPos(currX,currY)
  end
  local function roundTo(num, target) --For stacks of fuel and turtle slots when undergoing addition/subtraction
    if num >= target then return target elseif num < 0 then return 0 else return num end
  end
  local function updateScreen()
    output("Welcome to SmartFuel! Now Refueling...", 1,1)
    output("Fuel Request Multiplier: "..tostring(fuelMultiplier).."x",1,2)
    output("Currently taking fuel from slot "..currSlot,1,3)
    output("Current single fuel: "..tostring(oneFuel or 0),1,4)
    output("Current estimate of needed fuel: ",1,4)
    output("Single Items: "..math.ceil(neededFuelItems),4,6)
    output("Stacks:       "..math.ceil(neededFuelItems / 64),4,7)
    output("Needed Fuel: "..tostring(neededFuel),1,12)
    output("Current Fuel: "..tostring(checkFuel()),1,13)
  end
  while checkFuel() < neededFuel do
    currSlot = currSlot + 1
    select(currSlot)
    if currSlot ~= 1 and not turtle.refuel(0) then --If it's not the first slot, and not fuel, go back to start
      currSlot = 1; select(currSlot)
    end
    updateScreen()
    while turtle.getItemCount(currSlot) == 0 do
      sleep(1.5)
    end
    repeat --TODO: Probably unnecessary loop, remove later
      local previous = checkFuel()
      turtle.refuel(1)
      oneFuel = checkFuel() - previous
      updateScreen()
    until (oneFuel or 0) > 0 --Not an if to prevent errors if fuel taken out prematurely.
    neededFuelItems = math.ceil((neededFuel - checkFuel()) / oneFuel)
    turtle.refuel(roundTo(neededFuelItems, 64)) --Change because can only think about 64 at once.
    if turtle.getItemCount(roundTo(currSlot + 1, inventoryMax)) == 0 then --Resets if no more fuel
      currSlot = 0
    end
    neededFuelItems = math.ceil((neededFuel - checkFuel()) / oneFuel) --This line is not repeated uselessly, it's for the display function
  end
  select(1)
end
--Ender Chest Obtaining
function promptSpecialSlot(specialSlot, name, limit)
  local function isInRange(toCheck, lower, upper) return toCheck <= upper and toCheck >= lower end
  while not isInRange(turtle.getItemCount(specialSlots[specialSlot]), 1, limit or 1) do
    screen(1,1)
    print("You have decided to use a ",name,"!")
    print("Please place one ",name," in slot ",specialSlots[specialSlot])
    sleep(1)
  end
  print(name," in slot ",specialSlots[specialSlot], " checks out")
end
function checkSpecialSlot(specialSlot, name, allowed)
 if restoreFoundSwitch and turtle.getItemCount(specialSlots[specialSlot]) == 0 then --If the turtle was stopped while dropping off items.
    select(specialSlots[specialSlot])
    turtle.dig()
    select(1)
  end
  promptSpecialSlot(specialSlot, name, allowed)
  allowedItems[specialSlots[specialSlot]] = 1
  sleep(1)
end
if enderChest then
  checkSpecialSlot("enderChest","Ender Chest")
end
if fuelChest then
  checkSpecialSlot("fuelChest","Fuel Chest")
end
if lavaBucket then
  checkSpecialSlot("lavaBucket","Empty Bucket")
  select(specialSlots.lavaBucket)
  if turtle.refuel(1) then --Just in case they actually put in a lava bucket >:(
    print("No! You're supposed to put in an empty bucket") --This doubles as emptying the lava bucket if mid-run
    sleep(2)
  end
  select(1)
end
if compareChest then
  checkSpecialSlot("compareChest","Chest", 64)
end

--Setting which slots are marked as compare slots
if oldOreQuarry then
  if not restoreFoundSwitch then --We don't want to reset compare blocks every restart
    local counter = 0
    for i=1, inventoryMax do if turtle.getItemCount(i) > 0 and not specialSlots[i] then counter = counter+1 end end --If the slot has items, but isn't enderChest slot if it is enabled

    screen(1,1)
    print("You have selected an Ore Quarry!")
    if counter == 0 or hasRefueled then --If there are no compare slots, or the turtle has refueled, and probably has fuel in inventory
      print("Please place your compare blocks in the first slots\n")

      print("Press Enter when done")
      repeat until ({os.pullEvent("key")})[2] == 28 --Should wait for enter key to be pressed
    else
      print("Registering slots as compare slots")
      sleep(1)
    end
    for i=1, inventoryMax do
      if turtle.getItemCount(i) > 0 then
        if not specialSlots[i] then
          table.insert(compareSlots, i) --Compare slots are ones compared to while mining. Conditions are because we Don't want to compare to enderChest
          allowedItems[i] = 1 --Blacklist is for dropping off items. The number is maximum items allowed in slot when dropping off
          dumpSlots[i] = true --We also want to ignore all excess of these items, like dirt
        end
      end
    end
    if extraDropItems then
      screen(1,1)
      print("Put in extra drop items now\n")
      print("Press Enter when done")
      repeat until ({os.pullEvent("key")})[2] == 28 --Should wait for enter key to be pressed
      for i=1,inventoryMax do
        if not dumpSlots[i] and turtle.getItemCount(i) > 0 then --I don't want to modify from above, so I check it hasn't been assigned.
          dumpSlots[i] = true
          allowedItems[i] = 1
        end
      end
    end
    --This is could go very wrong if this isn't here
    if #compareSlots >= inventoryMax-keepOpen then screen(1,1); error("You have more quarry compare items than keep open slots, the turtle will continuously come back to start. Please fix.",0) end
  end
  local counter = 0
  for a, b in pairs(compareSlots) do if  turtle.getItemCount(b) > 0 then counter = counter + 1 end end
  if counter == 0 then
    screen(1,1)
    print("You have an ore quarry without any compare slots. Continue? y/n")
    if ({os.pullEvent("char")})[2] ~= "y" then error("",0) end
  end
elseif not oreQuarry then --This was screwing up dumpCompareItems
  dumpCompareItems = false --If not an ore quarry, this should definitely be false
  if specialSlots.enderChest == 1 then
    dumpSlots[2] = true
  else
    dumpSlots[1] = true
  end
end

--Rednet Handshake
function newMessageID()
  return math.random(1,2000000000)
end
function sendMessage(send, receive, message)
  if legacyRednet then
    if type(message) == "table" then message = textutils.serialize(message) end
    return modem.transmit(send, receive, message)
  end
  return modem.transmit(send , receive, {fingerprint = channels.fingerprint, id = newMessageID(), message = message})
end
if rednetEnabled then
  screen(1,1)
  print("Rednet is Enabled")
  print("The Channel to open is "..channels.send)
  if peripheral.find then
    modem = peripheral.find("modem")
  else
    modem = peripheral.wrap("right")
  end
  modem.open(channels.receive)
  local i = 0
    repeat
      local id = os.startTimer(3)
      i=i+1
      print("Sending Initial Message "..i)
      sendMessage(channels.send, channels.receive, channels.message)
      local message = {} --Have to initialize as table to prevent index nil
      repeat
        local event, idCheck, channel,_,locMessage, distance = os.pullEvent()
        if locMessage then message = locMessage end
        if legacyRednet then --For that one guy that uses 1.4.7
          message = {message = message}
        end
      until (event == "timer" and idCheck == id) or (event == "modem_message" and channel == channels.receive and type(message) == "table")
    until message.message == channels.confirm
  connected = true
  print("Connection Confirmed!")
  sleep(1.5)
end
function biometrics(isAtBedrock, requestQuad)
  if not rednetEnabled then return end --This function won't work if rednet not enabled :P
  local toSend = { label = os.getComputerLabel() or "No Label", id = os.getComputerID(),
    percent = percent, zPos = relzPos, xPos = relxPos, yPos = yPos,
    layersDone = layersDone, x = x, z = z, layers = layers,
    openSlots = getNumOpenSlots(), mined = mined, moved = moved,
    chestFull = chestFull, isAtChest = (xPos == 0 and yPos == 1 and zPos == 1),
    isGoingToNextLayer = (gotoDest == "layerStart"), foundBedrock = foundBedrock,
    fuel = checkFuel(), volume = volume, status = statusString,
    }
  if requestQuad and isInPath then --If we are requesting a quadRotor to send help
    if not gps.locate(gpsTimeout) then
      print("\nOH NOES! Trying to reach quadrotor, but can't get GPS position!")
      sleep(1)
    else
      toSend.firstPos = gpsStartPos
      toSend.secondPos = gpsSecondPos
      toSend.emergencyLocation = {gps.locate(gpsTimeout)}
    end
  end
  sendMessage(channels.send, channels.receive, toSend)
  id = os.startTimer(0.1)
  local event, received
  repeat
    local locEvent, idCheck, confirm, _, locMessage, distance = os.pullEvent()
    event, received = locEvent, locMessage or {message = ""}
    if legacyRednet and type(received) == "string" then
      received = {message = received}
    end
  until (event == "timer" and idCheck == id) or (event == "modem_message" and confirm == channels.receive and type(received) == "table")
  if event == "modem_message" then connected = true else connected = false end
  local message = received.message:lower()
  if message == "stop" or message == "quit" or message == "kill" then
    count(true)
    display()
    error("Rednet said to stop...",0)
  end
  if message == "return" then
    endingProcedure()
    error('Rednet said go back to start...',0)
  end
  if message == "drop" then
    dropOff()
  end
  if message == "pause" then
    print("\nTurtle is paused. Send 'resume' or press any character to resume")
    statusString = "Paused"
    toSend.status = statusString
    os.startTimer(3)
    repeat --The turtle sends out periodic messages, which will clear the receiver's queue and send a message (if it exists)
     --This may be a bit overkill, sending the whole message again, but whatever.
      local event, idCheck, confirm, _, message, distance = os.pullEvent()
      if event == "timer" then os.startTimer(3); sendMessage(channels.send, channels.receive, toSend) end --Only send messages on the timer. This prevents ridiculous spam
    until (event == "modem_message" and confirm == channels.receive and (message.message == "resume" or message.message == "unpause" or message.message == "pause")) or (event == "char")
    statusString = nil
  end
  if message == "refuel" then
    print("\nEngaging in emergency refueling")
    emergencyRefuel(true)
  end

end
--Showing changes to settings
screen(1,1)
print("Your selected settings:")
if #changedT == 0 then
  print("Completely Default")
  else
  for i=1, #changedT do
    if not changedT[i].hidden then
      print(changedT[i][1],": ",changedT[i][2]) --Name and Value
    end
  end
end
print("\nStarting in 3"); sleep(1); print("2"); sleep(1); print("1"); sleep(1.5) --Dramatic pause at end



----------------------------------------------------------------
--Define ALL THE FUNCTIONS
--Event System Functions
function eventSetInsertionPoint(num)
  eventInsertionPoint = num or 1
end
function eventAddAt(pos, ...)
  return table.insert(events,pos, {...}) or true
end
function eventAdd(...) --Just a wrapper
  return eventAddAt(eventInsertionPoint, ...)
end
function eventGet(pos)
  return events[tonumber(pos) or #events]
end
function eventPop(pos)
  return table.remove(events,tonumber(pos) or #events) or false --This will return value popped, tonumber returns nil if fail, so default to end
end
function eventRun(value, ...)
  local argsList = {...}
  if type(value) == "string" then
    if value:sub(-1) ~= ")" then --So supports both "up()" and "up"
      value = value .. "("
      for a, b in pairs(argsList) do --Appending arguments
        local toAppend
        if type(b) == "table" then toAppend = textutils.serialize(b)
        elseif type(b) == "string" then toAppend = "\""..tostring(b).."\"" --They weren't getting strings around them
        else toAppend = tostring(b) end
        value = value .. (toAppend or "true") .. ", "
      end
      if value:sub(-1) ~= "(" then --If no args, do not want to cut off
        value = value:sub(1,-3)..""
      end
      value = value .. ")"
    end
    --print(value) --Debug
    local func = loadstring(value)
    setfenv(func, getfenv(1))
    return func()
  end
end
function eventClear(pos)
  if pos then events[pos] = nil else events = {} end
end
function runAllEvents()
  while #events > 0 do
    local toRun = eventGet()
    --print(toRun[1]) --Debug
    eventRun(unpack(toRun))
    eventPop()
  end
end

--Display Related Functions
function display() --This is just the last screen that displays at the end
  screen(1,1)
  print("Total Blocks Mined: "..mined)
  print("Current Fuel Level: "..checkFuel())
  print("Cobble: "..totals.cobble)
  print("Usable Fuel: "..totals.fuel)
  print("Other: "..totals.other)
  if rednetEnabled then
    print("")
    print("Sent Stop Message")
    if legacyRednet then --This was the traditional stopping signal
      print("Sent Legacy Stop")
      sendMessage(channels.send, channels.receive, "stop")
    end
    local finalTable = {mined = mined, cobble = totals.cobble, fuelblocks = totals.fuel,
        other = totals.other, fuel = checkFuel(), isDone = true }
    if preciseTotals then
      finalTable.preciseTotals = exactTotals --This table doubles as a flag.
    end
    sendMessage(channels.send,channels.receive, finalTable)
    modem.close(channels.receive)
  end
  if doBackup then
    fs.delete(saveFile)
    if autoResume then --Getting rid of the original startup files and replacing
      fs.delete(startupName)
      if fs.exists(startupRename) then
        fs.move(startupRename, startupName)
      end
    end
  end
end
function updateDisplay() --Runs in Mine(), display information to the screen in a certain place
screen(1,1)
print("Blocks Mined")
print(mined)
print("Percent Complete")
print(percent.."%")
print("Fuel")
print(checkFuel())
  -- screen(1,1)
  -- print("Xpos: ")
  -- print(xPos)
  -- print("RelXPos: ")
  -- print(relxPos)
  -- print("Z Pos: ")
  -- print(zPos)
  -- print("Y pos: ")
  -- print(yPos)
if rednetEnabled then
screenLine(1,7)
print("Connected: "..tostring(connected))
end
end
--Utility functions
local function pad(str, length, side)
  toRet = ""
  if side == "right" then
    toRet = str
  end
  for i=1, length-#str do
    toRet = toRet.." "
  end
  if side == "left" then
    toRet = toRet..str
  end
  return toRet
end
function logMiningRun(textExtension, extras) --Logging mining runs
  if not logging then return end
  local number, name = 0
  if not fs.isDir(logFolder) then
    fs.delete(logFolder)
    fs.makeDir(logFolder)
  end
  repeat
    number = number + 1 --Number will be at least 2
    name = logFolder.."/Quarry_Log_"..tostring(number)..(textExtension or "")
  until not fs.exists(name)
  local handle = fs.open(name,"w")
  local function write(...)
    for a, b in ipairs({...}) do
      handle.write(tostring(b))
    end
    handle.write("\n")
  end
  local function boolToText(bool) if bool then return "Yes" else return "No" end end
  write("Welcome to the Quarry Logs!")
  write("Entry Number: ",number)
  write("Quarry Version: ",VERSION)
  write("Dimensions (X Z Y): ",x," ",z," ", y)
  write("Blocks Mined: ", mined)
  write("  Cobble: ", totals.cobble)
  write("  Usable Fuel: ", totals.fuel)
  write("  Other: ",totals.other)
  write("Total Fuel Used: ",  (originalFuel or (neededFuel + checkFuel()))- checkFuel()) --Protect against errors with some precision
  write("Expected Fuel Use: ", neededFuel)
  write("Days to complete mining run: ",os.day()-originalDay)
  write("Day Started: ", originalDay)
  write("Number of times resumed: ", numResumed)
  write("Was an ore quarry? ",boolToText(oreQuarry or oldOreQuarry))
  write("Was inverted? ",boolToText(invert))
  write("Was using rednet? ",boolToText(rednetEnabled))
  write("Chest was on the ",dropSide," side")
  if startDown > 0 then write("Started ",startDown," blocks down") end
  if exactTotals then
    write("\n==DETAILED TOTALS==")
    for a,b in pairs(exactTotals) do
      write(pad(a, 15, "right"),":",pad(tostring(b),({term.getSize()})[1]-15-1, "left"))
    end
  end
  handle.close()
end
--Inventory related functions
function isFull(slots) --Checks if there are more than "slots" used inventory slots.
  slots = slots or inventoryMax
  local numUsed = 0
  sleep(0)
  for i=1, inventoryMax do
    if turtle.getItemCount(i) > 0 then numUsed = numUsed + 1 end
  end
  if numUsed > slots then
    return true
  end
  return false
end
function countUsedSlots() --Returns number of slots with items in them, as well as a table of item counts
  local toRet, toRetTab = 0, {}
  for i=1, inventoryMax do
    local a = turtle.getItemCount(i)
    if a > 0 then toRet = toRet + 1 end
    table.insert(toRetTab, a)
  end
  return toRet, toRetTab
end
function getSlotsTable() --Just get the table from above
  local _, toRet = countUsedSlots()
  return toRet
end
function getChangedSlots(tab1, tab2) --Returns a table of changed slots. Format is {slotNumber, numberChanged}
  local toRet = {}
  for i=1, math.min(#tab1, #tab2) do
    diff = math.abs(tab2[i]-tab1[i])
    if diff > 0 then
      table.insert(toRet, {i, diff})
    end
  end
  return toRet
end
function getFirstChanged(tab1, tab2) --Just a wrapper. Probably not needed
  local a = getChangedSlots(tab1,tab2)
  return (a[1] or {"none"})[1]
end

function getRep(which, list) --Gets a representative slot of a type. Expectation is a sequential table of types
  for a,b in pairs(list) do
    if b == which then return a end
  end
  return false
end
function assignTypes(types, count) --The parameters allow a preexisting table to be used, like a table from the original compareSlots...
  types, count = types or {1}, count or 1 --Table of types and current highest type
  for i=1, inventoryMax do
    if turtle.getItemCount(i) > 0 and not specialSlots[i] then --Not special slots so we don't count ender chests
      select(i)
      for k=1, count do
        if turtle.compareTo(getRep(k, types)) then types[i] = k end
      end
      if not types[i] then
        count = count + 1
        types[i] = count
      end
      if oreQuarry then
        if blacklist[turtle.getItemDetail().name] then
          dumpSlots[i] = true
        else
          dumpSlots[i] = false
        end
      end
    end
  end
  select(1)
  return types, count
end
function getTableOfType(which, list) --Returns a table of all the slots of which type
  local toRet = {}
  for a, b in pairs(list) do
    if b == which then
      table.insert(toRet, a)
    end
  end
  return toRet
end

--This is so the turtle will properly get types, otherwise getRep of a type might not be a dumpSlot, even though it should be.
if not restoreFoundSwitch then --We only want this to happen once
  if oldOreQuarry then --If its not ore quarry, this screws up type assigning
    initialTypes, initialCount = assignTypes()
  else
    initialTypes, initialCount = {1}, 1
  end
end

function count(add) --Done any time inventory dropped and at end, true=add, false=nothing, nil=subtract
  local mod = -1
  if add then mod = 1 end
  if add == false then mod = 0 end
  slot = {}        --1: Filler 2: Fuel 3:Other --[1] is type, [2] is number
  for i=1, inventoryMax do
    slot[i] = {}
    slot[i][2] = turtle.getItemCount(i)
  end

  local function iterate(toSet , rawTypes, set)
    for _, a in pairs(getTableOfType(toSet, rawTypes)) do --Get all slots matching type
      slot[a][1] = set --Set official type to "set"
    end
  end

  --This assigns "dumb" types to all slots based on comparing, then based on knowledge of dump type slots, changes all slots matching a dump type to one. Otherwise, if the slot contains fuel, it is 2, else 3
  local rawTypes, numTypes = assignTypes(copyTable(initialTypes), initialCount) --This gets increasingly numbered types, copyTable because assignTypes will modify it

  for i=1, numTypes do
    if (select(getRep(i, rawTypes)) or true) and turtle.refuel(0) then --Selects the rep slot, checks if it is fuel
      iterate(i, rawTypes, 2) --This type is fuel
    elseif dumpSlots[getRep(i,(oreQuarry and rawTypes) or initialTypes)] then --If the rep of this slot is a dump item. This is initial types so that the rep is in dump slots. rawTypes if oreQuarry to get newly assigned dumps
      iterate(i, rawTypes, 1) --This type is cobble/filler
    else
      iterate(i, rawTypes, 3) --This type is other
    end
  end

  for i=1,inventoryMax do
    if not specialSlots[i] then --Do nothing for specialSlots!
      if exactTotals and slot[i][2] > 0 then
        local data = turtle.getItemDetail(i)
        exactTotals[data.name] = (exactTotals[data.name] or 0) + (data.count * mod)
      end
      if slot[i][1] == 1 then totals.cobble = totals.cobble + (slot[i][2] * mod)
      elseif slot[i][1] == 2 then totals.fuel = totals.fuel + (slot[i][2] * mod)
      elseif slot[i][1] == 3 then totals.other = totals.other + (slot[i][2] * mod) end
    end
  end

  select(1)
end

--Refuel Functions
function emergencyRefuel(forceBasic)
  local continueEvac = true --This turns false if more fuel is acquired
  if fuelChest then --This is pretty much the only place that this will be used
    if not fuelChestPhase then --Since I want to do things with return of enderRefuel, I will just make a special system. All of this is for backup safety.
      fuelChestPhase = 0 --Global variable will be saved
      fuelChestProperFacing = facing
    end
    if fuelChestPhase == 0 then
      turnTo(coterminal(fuelChestProperFacing+2))
      dig(false)
      fuelChestPhase = 1
      saveProgress()
    end
    if fuelChestPhase == 1 then
      select(specialSlots.fuelChest)
      turtle.place()
      fuelChestPhase = 2
      saveProgress()
    end
    if fuelChestPhase == 2 then
      if not enderRefuel() then --Returns false if slots are full
        select(specialSlots.fuelChest)
        turtle.drop() --Somehow stuff got in here...
      end
      fuelChestPhase = 3
      saveProgress()
    end
    if fuelChestPhase == 3 then
      select(specialSlots.fuelChest)
      dig(false)
      select(1)
      fuelChestPhase = 4
      saveProgress()
    end
    if fuelChestPhase == 4 then
      turnTo(fuelChestProperFacing)
      fuelChestProperFacing = nil --Getting rid of saved values
      fuelChestPhase = nil
      continueEvac = false
    end
  elseif quadEnabled then --Ask for a quadRotor
    screen()
    print("Attempting an emergency Quad Rotor refuel")
    print("The turtle will soon send a message, then wait ",quadTimeout," seconds before moving on")
    print("Press any key to break timer")
    biometrics(nil, true)
    local timer, counter, counterID, event, id  = os.startTimer(quadTimeout), 0, os.startTimer(1)
    local startInventory = getSlotsTable()
    repeat
      if id == counterID then counter = counter + 1; counterID = os.startTimer(1) end
      screenLine(1,6)
      print("Seconds elapsed: ",counter)
      event, id = os.pullEvent() --Waits for a key or fuel or the timer
    until (event == "timer" and id == timer) or event == "key" or event == "turtle_inventory" --Key event just makes turtle go back to start
    if event == "turtle_inventory" then --If fuel was actually delivered
      local slot = getFirstChanged(startInventory, getSlotsTable())
      select(slot)
      local initialFuel = checkFuel()
      midRunRefuel(slot)
      if checkFuel() > initialFuel then
        print("Fuel delivered! Evac aborted")
        continueEvac = false
      else
        print("What did you send the turtle? Not fuel >:(")
        print("Continuing evac")
      end
      sleep(1)
    end
  elseif doRefuel or forceBasic then --Attempt an emergency refueling
    screen()
    print("Attempting an emergency refuel")
    print("Fuel Level:    ",checkFuel())
    print("Distance Back: ",(xPos+zPos+yPos+1))
    print("Categorizing Items")
    count(false) --Do not add count, but categorize
    local fuelSwitch, initialFuel = false, checkFuel() --Fuel switch so we don't go over limit (in emergency...)
    print("Going through available fuel slots")
    for i=1, inventoryMax do
      if fuelSwitch then break end
      if turtle.getItemCount(i) > 0 and slot[i][1] == 2 then --If there are items and type 2 (fuel)
        select(i)
        fuelSwitch = midRunRefuel(i) --See above "function drop" for usage
      end
    end
    select(1) --Cleanup
    print("Done fueling")
    if checkFuel() > initialFuel then
      continueEvac = false
      print("Evac Aborted")
    else
      print("Evac is a go, returning to base")
      sleep(1.5) --Pause for reading
    end
  end
  return continueEvac
end

function lavaRefuel(suckDir)
  if checkFuel() + lavaBuffer >= checkFuelLimit() then return false end -- we don't want to constantly over-fuel the turtle.
  local suckFunc
  if suckDir == "up" then suckFunc = turtle.placeUp
  elseif suckDir == "down" then suckFunc = turtle.placeDown
  else suckFunc = turtle.place end
  
  select(specialSlots.lavaBucket)
  if suckFunc() then
    midRunRefuel(specialSlots.lavaBucket, 0) --0 forces it to refuel, even though allowed items[slot] is 1
  end
  select(1)
  return true
end

--Mining functions
function dig(doAdd, mineFunc, inspectFunc, suckDir) --Note, turtle will not bother comparing if not given an inspectFunc
  if doAdd == nil then doAdd = true end
  mineFunc = mineFunc or turtle.dig
  local function retTab(tab) if type(tab) == "table" then return tab end end --Please ignore the stupid one-line trickery. I felt special writing that. (Unless it breaks, then its cool)
    --Mine if not in blacklist. inspectFunc returns success and (table or string) so retTab filters out the string and the extra table prevents errors.
  local mineFlag = false
  if oreQuarry and inspectFunc then
    local worked, data = inspectFunc()
    if data then
      mineFlag = not blacklist[data.name]
      if data.name == chestID then
        emptyChest(suckDir)
      end
      if lavaBucket and data.name == lavaID and data.metadata == lavaMeta then
        lavaRefuel(suckDir)
      end
    end
  end
  if not oreQuarry or not inspectFunc or mineFlag then --Mines if not oreQuarry, or if the inspect passed
   if mineFunc() then
     if doAdd then
       mined = mined + 1
     end
     return true
   else
     return false
   end
  end
  return true --This only runs if oreQuarry but item not in blacklist. true means succeeded in duty, not necessarily dug block
end

function digUp(doAdd, ignoreInspect)--Regular functions :) I switch definitions for optimization (I think)
  return dig(doAdd, turtle.digUp, (not ignoreInspect and turtle.inspectUp) or nil, "up")
end
function digDown(doAdd, ignoreInspect)
  return dig(doAdd, turtle.digDown, (not ignoreInspect and turtle.inspectDown) or nil, "down")
end
if inverted then --If inverted, switch the options
  digUp, digDown = digDown, digUp
end

function smartDig(doDigUp, doDigDown) --This function is used only in mine when oldOreQuarry
  if inverted then doDigUp, doDigDown = doDigDown, doDigUp end --Switching for invert
  local blockAbove, blockBelow = doDigUp and turtle.detectUp(), doDigDown and turtle.detectDown() --These control whether or not the turtle digs
  local index = 1
  for i=1, #compareSlots do
    if not (blockAbove or blockBelow) then break end --We don't want to go selecting if there is nothing to dig
    index = i --To access out of scope
    select(compareSlots[i])
    if blockAbove and turtle.compareUp() then blockAbove = false end
    if blockBelow and turtle.compareDown() then blockBelow = false end
  end
  if compareChest then
    local flag = false
    select(specialSlots.compareChest)
    if turtle.compareUp() then emptyChest("up") end --Impressively, this actually works with session persistence. I'm gooood (apparently :P )
    if turtle.compareDown() then emptyChest("down") end --Looking over the code, I see no reason why that works... Oh well.
  end
  table.insert(compareSlots, 1, table.remove(compareSlots, index)) --This is so the last selected slot is the first slot checked, saving a select call
  if blockAbove then dig(true, turtle.digUp) end
  if blockBelow then dig(true, turtle.digDown) end
end

function relxCalc()
  if layersDone % 2 == 1 then
    relzPos = zPos
  else
    relzPos = (z-zPos) + 1
  end
  if relzPos % 2 == 1 then
    relxPos = xPos
  else
    relxPos = (x-xPos)+1
  end
  if layersDone % 2 == 0 and z % 2 == 1 then
    relxPos = (x-relxPos)+1
  end
end
function horizontalMove(movement, posAdd, doAdd)
  if doAdd == nil then doAdd = true end
  if movement() then
    if doAdd then
      moved = moved + 1
    end
    if facing == 0 then
      xPos = xPos + 1
    elseif facing == 1 then
      zPos = zPos + 1
    elseif facing == 2 then
      xPos = xPos - 1
    elseif facing == 3 then
      zPos = zPos - 1
    else
      error("Function forward, facing should be 0 - 3, got "..tostring(facing),2)
    end
    relxCalc()
    return true
  end
  return false
end
function forward(doAdd)
  return horizontalMove(turtle.forward, 1, doAdd)
end
function back(doAdd)
  return horizontalMove(turtle.back, -1, doAdd)
end
function verticalMove(moveFunc, yDiff, digFunc, attackFunc)
  local count = 0
  while not moveFunc() do
    if not digFunc(true, true) then --True True is doAdd, and ignoreInspect
      attackFunc()
      sleep(0.5)
      count = count + 1
      if count > maxTries and yPos > (startY-7) then bedrock() end
    end
  end
  yPos = yDiff + yPos
  saveProgress()
  biometrics()
  return true
end
function up() --Uses other function if inverted
  verticalMove(inverted and turtle.down or turtle.up, -1, digUp, attackUp) --Other functions deal with invert already
end
function down()
  verticalMove(inverted and turtle.up or turtle.down, 1, digDown, attackDown)
end


function right(num)
  num = num or 1
  for i=1, num do
    facing = coterminal(facing+1)
    saveProgress()
    if not goLeftNotRight then turtle.turnRight() --Normally
    else turtle.turnLeft() end --Left Quarry
  end
end
function left(num)
  num = num or 1
  for i=1, num do
  facing = coterminal(facing-1)
  saveProgress()
  if not goLeftNotRight then turtle.turnLeft() --Normally
  else turtle.turnRight() end --Left Quarry
end
end

function attack(doAdd, func)
  doAdd = doAdd or true
  func = func or turtle.attack
  if func() then
    if doAdd then
      attacked = attacked + 1
    end
    return true
  end
  return false
end
function attackUp(doAdd)
  if inverted then
    return attack(doAdd, turtle.attackDown)
  else
    return attack(doAdd, turtle.attackUp)
  end
end
function attackDown(doAdd)
  if inverted then
    return attack(doAdd, turtle.attackUp)
  else
    return attack(doAdd, turtle.attackDown)
  end
end

function detect(func)
  func = func or turtle.detect
  return func()
end
function detectUp(ignoreInvert)
  if inverted and not ignoreInvert then return detect(turtle.detectDown)
  else return detect(turtle.detectUp) end
end
function detectDown(ignoreInvert)
  if inverted and not ignoreInvert then return detect(turtle.detectUp)
  else return detect(turtle.detectDown) end
end



function mine(doDigDown, doDigUp, outOfPath,doCheckInv) -- Basic Move Forward
  if doCheckInv == nil then doCheckInv = true end
  if doDigDown == nil then doDigDown = true end
  if doDigUp == nil then doDigUp = true end
  if outOfPath == nil then outOfPath = false end
  isInPath = (not outOfPath) --For rednet
  if not outOfPath and (checkFuel() <= xPos + zPos + yPos + 5) then --If the turtle can just barely get back to the start, we need to get it there. We don't want this to activate coming back though...
    local continueEvac = false --It will be set true unless at start
    if xPos ~= 0 then
      continueEvac = emergencyRefuel() --This is a huge list of things to do in an emergency
    end
    if continueEvac then
      eventClear() --Clear any annoying events for evac
      local currPos = yPos
      endingProcedure() --End the program
      print("Turtle ran low on fuel so was brought back to start for you :)\n\nTo resume where you left off, use '-startDown "..tostring(currPos-1).."' when you start")
      error("",0)
    end
  end
  if frontChest and not outOfPath then
    if turtle.inspect then
      local check, data = turtle.inspect()
      if check and data.name == chestID then
        emptyChest("front")
      end
    else
      local flag = false
      select(specialSlots.compareChest)
      if turtle.compare() then flag = true end
      select(1)
      if flag then
        emptyChest("front")
      end
    end
  end
  
  local count = 0
  if not outOfPath then dig() end  --This speeds up the quarry by a decent amount if there are more mineable blocks than air
  while not forward(not outOfPath) do
    sleep(0) --Calls coroutine.yield to prevent errors
    count = count + 1
    if not dig() then
      attack()
    end
    if count > 10 then
      attack()
      sleep(0.2)
    end
    if count > maxTries then
      if checkFuel() == 0 then --Don't worry about inf fuel because I modified this function
        saveProgress({doCheckFuel = true, doRefuel = true}) --This is emergency because this should never really happen.
        os.reboot()
      elseif yPos > (startY-7) and turtle.detect() then --If it is near bedrock
        bedrock()
      else --Otherwise just sleep for a bit to avoid sheeps
        sleep(1)
      end
    end
  end
  checkSanity() --Not kidding... This is necessary
  saveProgress(tab)

  if not oldOreQuarry then
    if doDigUp then--The digging up and down part
      sleep(0) --Calls coroutine.yield
      if not digUp(true) and detectUp() then --This is relative: will dig down first on invert
        if not attackUp() then
          if yPos > (startY-7) then bedrock() end --Checking for bedrock, but respecting user wishes
        end
      end
    end
    if doDigDown then
     digDown(true) --This needs to be absolute as well
    end
  else --If oldQuarry
    smartDig(doDigUp,doDigDown)
  end
  percent = math.ceil(moved/moveVolume*100)
  updateDisplay()
  if doCheckInv and careAboutResources then
    if isFull(inventoryMax-keepOpen) then
      if not ((oreQuarry or oldOreQuarry) and dumpCompareItems) then
        dropOff()
      else
        local currInv = getSlotsTable()
        drop(nil, false, true) --This also takes care of counting.
        if #getChangedSlots(currInv, getSlotsTable()) <= 2 then --This is so if the inventory is full of useful stuff, it still has to drop it
          dropOff()
        end
      end
    end
  end
  biometrics()
end
--Insanity Checking
function checkSanity()
  if not isInPath then --I don't really care if its not in the path.
    return true
  end
  if not (facing == 0 or facing == 2) and #events == 0 then --If mining and not facing proper direction and not in a turn
    turnTo(0)
    rowCheck = true
  end
  if xPos < 0 or xPos > x or zPos < 0 or zPos > z or yPos < 0 then
    saveProgress()
    print("I have gone outside boundaries, attempting to fix (maybe)")
    if xPos > x then goto(x, zPos, yPos, 2) end --I could do this with some fancy math, but this is much easier
    if xPos < 0 then goto(1, zPos, yPos, 0) end
    if zPos > z then goto(xPos, z, yPos, 3) end
    if zPos < 0 then goto(xPos, 1, yPos, 1) end
    relxCalc() --Get relxPos properly
    eventClear()

    --[[
    print("Oops. Detected that quarry was outside of predefined boundaries.")
    print("Please go to my forum thread and report this with a short description of what happened")
    print("If you could also run \"pastebin put Civil_Quarry_Restore\" and give me that code it would be great")
    error("",0)]]
  end
end

local function fromBoolean(input) --Like a calculator
if input then return 1 end
return 0
end
local function multBoolean(first,second) --Boolean multiplication
return (fromBoolean(first) * fromBoolean(second)) == 1
end
function coterminal(num, limit) --I knew this would come in handy :D
limit = limit or 4 --This is for facing
return math.abs((limit*fromBoolean(num < 0))-(math.abs(num)%limit))
end
if tArgs["-manualpos"] then
  facing = coterminal(facing) --Done to improve support for "-manualPos"
  if facing == 0 then rowCheck = true elseif facing == 2 then rowCheck = false end --Ditto
  relxCalc() --Ditto
end

--Direction: Front = 0, Right = 1, Back = 2, Left = 3
function turnTo(num)
  num = num or facing
  num = coterminal(num) --Prevent errors
  local turnRight = true
  if facing-num == 1 or facing-num == -3 then turnRight = false end --0 - 1 = -3, 1 - 0 = 1, 2 - 1 = 1
  while facing ~= num do          --The above is used to smartly turn
    if turnRight then
      right()
    else
      left()
    end
  end
end
function goto(x,z,y, toFace, destination)
  --Will first go to desired z pos, then x pos, y pos varies
  x = x or 1; y = y or 1; z = z or 1; toFace = toFace or facing
  gotoDest = destination or "" --This is used by biometrics.
  statusString = "Going to ".. (destination or "somewhere")
  --Possible destinations: layerStart, quarryStart
  if yPos > y then --Will go up first if below position
    while yPos~=y do up() end
  end
  if zPos > z then
    turnTo(3)
  elseif zPos < z then
    turnTo(1)
  end
  while zPos ~= z do mine(false,false,true,false) end
  if xPos > x then
    turnTo(2)
  elseif xPos < x then
    turnTo(0)
  end
  while xPos ~= x do mine(false,false,true,false) end
  if yPos < y then --Will go down after if above position
    while yPos~=y do down() end
  end
  turnTo(toFace)
  saveProgress()
  gotoDest = ""
  statusString = nil
end
function getNumOpenSlots()
  local toRet = 0
  for i=1, inventoryMax do
    if turtle.getItemCount(i) == 0 then
      toRet = toRet + 1
    end
  end
  return toRet
end
function emptyChest(suckDirection)
  eventAdd("emptyChest",suckDirection)
  eventSetInsertionPoint(2) --Because dropOff adds events we want to run first
  local suckFunc
  if suckDirection == "up" then
    suckFunc = turtle.suckUp
  elseif suckDirection == "down" then
    suckFunc = turtle.suckDown
  else
    suckFunc = turtle.suck
  end
  repeat
    if inventoryMax - countUsedSlots() <= 0 then --If there are no slots open, need to empty
      dropOff()
    end
  until not suckFunc()
  eventClear()
  eventSetInsertionPoint()
end

--Ideas: Bring in inventory change-checking functions, count blocks that have been put in, so it will wait until all blocks have been put in.
local function waitDrop(slot, allowed, whereDrop) --This will just drop, but wait if it can't
  allowed = allowed or 0
  while turtle.getItemCount(slot) > allowed do --No more half items stuck in slot!
    local tries = 1
    while not whereDrop(turtle.getItemCount(slot)-allowed) do --Drop off only the amount needed
      screen(1,1)
      print("Chest Full, Try "..tries)
      chestFull = true
      biometrics()--To send that the chest is full
      tries = tries + 1
      sleep(2)
    end
    chestFull = false
  end
end

function midRunRefuel(i, allowed)
  allowed = allowed or allowedItems[i]
  local numToRefuel = turtle.getItemCount(i)-allowed
  if checkFuel() >= checkFuelLimit() then return true end --If it doesn't need fuel, then signal to not take more
  local firstCheck = checkFuel()
  if numToRefuel > 0 then turtle.refuel(1)  --This is so we can see how many fuel we need.
    else return false end --Bandaid solution: If won't refuel, don't try.
  local singleFuel
  if checkFuel() - firstCheck > 0 then singleFuel = checkFuel() - firstCheck else singleFuel = math.huge end --If fuel is 0, we want it to be huge so the below will result in 0 being taken
  --Refuel      The lesser of   max allowable or         remaining fuel space         /    either inf or a single fuel (which can be 0)
  turtle.refuel(math.min(numToRefuel-1, math.ceil((checkFuelLimit()-checkFuel()) / singleFuel))) --The refueling part of the the doRefuel option
  if checkFuel() >= checkFuelLimit() then return true end --Do not need any more fuel
  return false --Turtle can still be fueled
end

function enderRefuel() --Assumes a) An enderchest is in front of it b) It needs fuel
  local slot
  for a,b in ipairs(getSlotsTable()) do
    if b == 0 then slot = a; break end
  end
  if not slot then return false end --No room for fueling
  select(slot)
  repeat
    print("Required Fuel: ",checkFuelLimit())
    print("Current Fuel: ",checkFuel())
    local tries = 0
    while not turtle.suck() do
      sleep(1)
      statusString = "No Fuel in Ender Chest"
      biometrics() --Let user know that fuel chest is empty
      print(statusString,". Try: ",tries)
      tries = tries + 1
    end
    statusString = nil
  until midRunRefuel(slot, 0) --Returns true when should not refuel any more
  if not turtle.drop() then turtle.dropDown() end --If cannot put fuel back, just drop it, full fuel chest = user has too much fuel already
  return true -- :D
end


function drop(side, final, compareDump)
  side = sides[side] or "front"
  local dropFunc, detectFunc, dropFacing = turtle.drop, turtle.detect, facing+2
  if side == "top" then dropFunc, detectFunc = turtle.dropUp, turtle.detectUp end
  if side == "bottom" then dropFunc, detectFunc = turtle.dropDown, turtle.detectDown end
  if side == "right" then turnTo(1); dropFacing = 0 end
  if side == "left" then turnTo(3); dropFacing = 0 end
  local properFacing = facing --Capture the proper direction to be facing

  count(true) --Count number of items before drop. True means add. This is before chest detect, because could be final

  while not compareDump and not detectFunc() do
    if final then return end --If final, we don't need a chest to be placed, but there can be
    chestFull = true
    biometrics() --Let the user know there is a problem with chest
    screen(1,1) --Clear screen
    print("Waiting for chest placement on ",side," side (when facing quarry)")
    sleep(2)
  end
  chestFull = false

  local fuelSwitch = false --If doRefuel, this can switch so it won't overfuel
  for i=1,inventoryMax do
    --if final then allowedItems[i] = 0 end --0 items allowed in all slots if final ----It is already set to 1, so just remove comment if want change
    if turtle.getItemCount(i) > 0 then --Saves time, stops bugs
      if slot[i][1] == 1 and dumpCompareItems then turnTo(dropFacing) --Turn around to drop junk, not store it. dumpComapareItems is global config
      else turnTo(properFacing) --Turn back to proper position... or do nothing if already there
      end
      select(i)
      if slot[i][1] == 2 then --Intelligently refuels to fuel limit
        if doRefuel and not fuelSwitch then --Not in the conditional because we don't want to waitDrop excess fuel. Not a break so we can drop junk
          fuelSwitch = midRunRefuel(i)
        else
          waitDrop(i, allowedItems[i], dropFunc)
        end
        if fuelSwitch then
          waitDrop(i, allowedItems[i], dropFunc)
        end
      elseif not compareDump or (compareDump and slot[i][1] == 1) then --This stops all wanted items from being dropped off in a compareDump
        waitDrop(i, allowedItems[i], dropFunc)
      end
    end
  end

  if compareDump then
    for i=2, inventoryMax do
      if not specialSlots[i] then --We don't want to move buckets and things into earlier slots
        select(i)
        for j=1, i-1 do
          if turtle.getItemCount(i) == 0 then break end
          turtle.transferTo(j)
        end
      end
    end
    select(1)
  end
  if oldOreQuarry or compareDump then count(nil) end--Subtract the items still there if oreQuarry
  resetDumpSlots() --So that slots gone aren't counted as dump slots next

  select(1) --For fanciness sake

end

function dropOff() --Not local because called in mine()
  local currX,currZ,currY,currFacing = xPos, zPos, yPos, facing
  if careAboutResources then
    if not enderChest then --Regularly
      eventAdd("goto", 1,1,currY,2, "drop off") --Need this step for "-startDown"
      eventAdd('goto(0,1,1,2,"drop off")')
      eventAdd("drop", dropSide,false)
      eventAdd("turnTo(0)")
      eventAdd("mine",false,false,true,false)
      eventAdd("goto(1,1,1, 0)")
      eventAdd("goto", 1, 1, currY, 0)
      eventAdd("goto", currX,currZ,currY,currFacing)
    else --If using an enderChest
      if turtle.getItemCount(specialSlots.enderChest) ~= 1 then eventAdd("promptSpecialSlot('enderChest','Ender Chest')") end
      eventAdd("turnTo",currFacing-2)
      eventAdd("dig",false)
      eventAdd("select",specialSlots.enderChest)
      eventAdd("turtle.place")
      eventAdd("drop","front",false)
      eventAdd("turnTo",currFacing-2)
      eventAdd("select", specialSlots.enderChest)
      eventAdd("dig",false)
      eventAdd("turnTo",currFacing)
      eventAdd("select(1)")
    end
    runAllEvents()
    numDropOffs = numDropOffs + 1 --Analytics tracking
  end
  return true
end
function endingProcedure() --Used both at the end and in "biometrics"
  eventAdd("goto",1,1,yPos,2,"quarryStart") --Allows for startDown variable
  eventAdd("goto",0,1,1,2, "quarryStart") --Go back to base
  runAllEvents()
  --Output to a chest or sit there
  if enderChest then
    if dropSide == "right" then eventAdd("turnTo(1)") end --Turn to proper drop side
    if dropSide == "left" then eventAdd("turnTo(3)") end
    eventAdd("dig(false)") --This gets rid of a block in front of the turtle.
    eventAdd("select",specialSlots.enderChest)
    eventAdd("turtle.place")
    eventAdd("select(1)")
  end
  eventAdd("drop",dropSide, true)
  eventAdd("turnTo(0)")

  --Display was moved above to be used in bedrock function
  eventAdd("display")
  --Log current mining run
  eventAdd("logMiningRun",logExtension)
  toQuit = true --I'll use this flag to clean up (legacy)
  runAllEvents()
end
function bedrock()
  foundBedrock = true --Let everyone know
  if rednetEnabled then biometrics() end
  if checkFuel() == 0 then error("No Fuel",0) end
  local origin = {x = xPos, y = yPos, z = zPos}
  print("Bedrock Detected")
  if turtle.detectUp() and not turtle.digUp() then
    print("Block Above")
    turnTo(facing+2)
    repeat
      if not forward(false) then --Tries to go back out the way it came
        if not attck() then --Just making sure not mob-blocked
          if not dig() then --Now we know its bedrock
            turnTo(facing+1) --Try going a different direction
          end
        end
      end
    until not turtle.detectUp() or turtle.digUp() --These should be absolute and we don't care about about counting resources here.
  end
  up() --Go up two to avoid any bedrock.
  up()
  eventClear() --Get rid of any excess events that may be run. Don't want that.
  endingProcedure()
  print("\nFound bedrock at these coordinates: ")
  print(origin.x," Was position in row\n",origin.z," Was row in layer\n",origin.y," Blocks down from start")
  error("",0)
end

function endOfRowTurn(startZ, wasFacing, mineFunctionTable)
local halfFacing = ((layersDone % 2 == 1) and 1) or 3
local toFace = coterminal(wasFacing + 2) --Opposite side
if zPos == startZ then
  if facing ~= halfFacing then turnTo(halfFacing) end
  mine(unpack(mineFunctionTable or {}))
end
if facing ~= toFace then
  turnTo(toFace)
end
end


-------------------------------------------------------------------------------------
--Pre-Mining Stuff dealing with session persistence
runAllEvents()
if toQuit then error("",0) end --This means that it was stopped coming for its last drop

local doDigDown, doDigUp = (lastHeight ~= 1), (lastHeight == 0) --Used in lastHeight
if not restoreFoundSwitch then --Regularly
  --Check if it is a mining turtle
  if not isMiningTurtle then
    local a, b = turtle.dig()
    if a then
      mined = mined + 1
      isMiningTurtle = true
    elseif b == "Nothing to dig with" or b == "No tool to dig with" then
      print("This is not a mining turtle. To make a mining turtle, craft me together with a diamond pickaxe")
      error("",0)
    end
  end
  
  if checkFuel() == 0 then --Some people forget to start their turtles with fuel
    screen(1,1)
    print("I have no fuel and doCheckFuel is off!")
    print("Starting emergency fueling procedures!\n")
    emergencyRefuel()
    if checkFuel() == 0 then
      print("I have no fuel and can't get more!")
      print("Try using -doRefuel or -fuelChest")
      print("I have no choice but to quit.")
      error("",0)
    end
  end
  
  mine(false,false,true) --Get into quarry by going forward one
  if gpsEnabled and not restoreFoundSwitch then --The initial locate is done in the arguments. This is so I can figure out what quadrant the turtle is in.
    gpsSecondPos = {gps.locate(gpsTimeout)} --Note: Does not run this if it has already been restarted.
  end
  for i = 1, startDown do
    eventAdd("down") --Add a bunch of down events to get to where it needs to be.
  end
  runAllEvents()
  if flatBedrock then
    while (detectDown() and digDown(false, true)) or not detectDown() do --None of these functions are non-invert protected because inverse always false here
      down()
      startDown = startDown + 1
    end
    startDown = startDown - y + 1
    for i=1, y-2 do
      up() --It has hit bedrock, now go back up for proper 3 wide mining
    end
  elseif not(y == 1 or y == 2) then
    down() --Go down to align properly. If y is one or two, it doesn't need to do this.
  end
else --restore found
  if not(layersDone == layers and not doDigDown) then digDown() end
  if not(layersDone == layers and not doDigUp) then digUp() end  --Get blocks missed before stopped
end
--Mining Loops--------------------------------------------------------------------------
select(1)
while layersDone <= layers do -------------Height---------
local lastLayer = layersDone == layers --If this is the last layer
local secondToLastLayer = (layersDone + 1) == layers --This is a check for going down at the end of a layer.
moved = moved + 1 --To account for the first position in row as "moved"
if not(layersDone == layers and not doDigDown) then digDown() end --This is because it doesn't mine first block in layer
if not restoreFoundSwitch and layersDone % 2 == 1 then rowCheck = true end
relxCalc()
while relzPos <= z do -------------Width----------
while relxPos < x do ------------Length---------
mine(not lastLayer or (doDigDown and lastLayer), not lastLayer or (doDigUp and lastLayer)) --This will be the idiom that I use for the mine function
end ---------------Length End-------
if relzPos ~= z then --If not on last row of section
  local func
  if rowCheck == true then --Switching to next row
  func = "right"; rowCheck = false; else func = false; rowCheck = true end --Which way to turn
    eventAdd("endOfRowTurn", zPos, facing , {not lastLayer or (doDigDown and lastLayer), not lastLayer or (doDigUp and lastLayer)}) --The table is passed to the mine function
    runAllEvents()
else break
end
end ---------------Width End--------
if layersDone % 2 == 0 then --Will only go back to start on non-even layers
  eventAdd("goto",1,1,yPos,0, "layerStart") --Goto start of layer
else
  eventAdd("turnTo",coterminal(facing-2))
end
if not lastLayer then --If there is another layer
  for i=1, 2+fromBoolean(not(lastHeight~=0 and secondToLastLayer)) do eventAdd("down()") end --The fromBoolean stuff means that if lastheight is 1 and last and layer, will only go down two
end
eventAdd("relxCalc")
layersDone = layersDone + 1
restoreFoundSwitch = false --This is done so that rowCheck works properly upon restore
runAllEvents()
end ---------------Height End-------

endingProcedure() --This takes care of getting to start, dropping in chest, and displaying ending screen
