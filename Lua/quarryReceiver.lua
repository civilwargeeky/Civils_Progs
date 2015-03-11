--Quarry Receiver Version 3.6.4
--Made by Civilwargeeky
--[[
Recent Changes:
  Completely Remade!
]]


--Config
local doDebug = false --For testing purposes
local ySizes = 3 --There are 3 different Y Screen Sizes right now
local quadEnabled = false --This is for the quadrotors mod by Lyqyd
local autoRestart = false --If true, will reset screens instead of turning them off. For when reusing turtles.

--Initializing Program-Wide Variables
local expectedMessage = "Civil's Quarry" --Expected initial message
local expectedFingerprint = "quarry"
local replyMessage = "Turtle Quarry Receiver" --Message to respond to  handshake with
local replyFingerprint = "quarryReceiver"
local stopMessage = "stop"
local expectedFingerprint = "quarry"
local themeFolder = "quarryResources/receiverThemes/"
local modemSide --User can specify a modem side, but it is not necessary
local modem --This will be the table for the modem
local computer --The main screen is special. It gets defined first :3
local continue = true --This keeps the main while loop going
local quadDirection = "north"
local quadDirections = {n = "north", s = "south", e = "east", w = "west"}
local quadBase, computerLocation
local tArgs = {...}
--These two are used by controller in main loop
local commandString = "" --This will be a command string sent to turtle. This var is stored for display
local lastCommand --If a command needs to be sent, this gets set
local defaultSide
local defaultCommand
local stationsList = {}

for i=1, #tArgs do --Parameters that must be set before rest of program for proper debugging
  local val = tArgs[i]:lower()
  if val == "-v" or val == "-verbose" then
    doDebug = true
  end
  if val == "-q" or val == "-quiet" then
    doDebug = false
  end
end

local keyMap = {[57] = " ", [11] = "0", [12] = "_", [52] = ".", [82] = "0", [83] = "."} --This is for command string
for i=2,10 do keyMap[i] = tostring(i-1) end --Add top numbers
for a=0,2 do --All the numpad numbers
  for b=0,2 do
    keyMap[79-(4*a)+b] = tostring(b + 1 + a*3) --Trust me, this just works
  end
end
for a,b in pairs(keys) do --Add all letters from keys api
  if #a == 1 then
    keyMap[b] = a:upper()
  end
end
keyMap[keys.enter] = "enter"
keyMap[156] = "enter" --Numpad enter
keyMap[keys.backspace] = "backspace"
keyMap[200] = "up"
keyMap[208] = "down"
keyMap[203] = "left"
keyMap[205] = "right"

local helpResources = { --$$ is a new page
main = [[$$Hello and welcome to
Quarry Receiver Help!

This goes over everything there is to know about the receiver

Use the arrow keys to navigate!
Press '0' to come back here!
Press 'q' to quit!

Press a section number at any time to go the beginning of that section
 1. Basic Use
 2. Parameters
 3. Commands
 4. Turtle Commands
 
$$A secret page!
You found it! Good job :)
]],
[[$$Your turtle and you!

To use this program, you need a wireless modem on both this computer and the turtle

Make sure they are attached to both the turtle and this computer
$$Using your new program!

Once you have done that, start the turtle and when it says "Rednet?", say "Yes"
  Optionally, you can use the parameter "-rednet true"
Then remember the channel it tells you to open.

Come back to this computer, and run the program. Follow onscreen directions.
  Optionally, you can use the parameter "-receiveChannel"
  
Check out the other help sections for more parameters
$$Adding Screens!
You can add screens with the "-screen" parameter or the "SCREEN" command
An example would be "SCREEN LEFT" for a screen on the left side.

You can connect screens over wired modems. Attach a modem to the computer and screen, then right click the modem on the screen.
Then you can say "SCREEN MONITOR_0" or whatever it says

]],
[[$$Parameters!
  note: {} means required, [] means optional

-help/help/-?/?/-usage/usage: That's this!

-receiveChannel/channel {channel}: Sets the main screen's receive channel

-theme {name}: sets the "default" theme that screens use when they don't have a set theme

-screen {side} [channel] [theme]: makes a new screen on the given side with channel and theme
$$Parameters!
  note: {} means required, [] means optional

-station: makes the main computer a "station" that monitors all screens
 
-auto [channel list]: This finds all attached monitors and initializes them. The channel list assigns channels to screens sequentially
  example: -auto 1 2 5 9   This looks for screens and automatically gives them channels 1, 2, 5, and 9

-colorEditor: makes the main screen a color editor that just prints the current colors. Good for theme making
current typeColors: title, subtitle, pos, dim, extra, error, info, inverse, command, help, background
$$Parameters!
-modem {side}: Sets the modem side to side

-v/-verbose: turns on debug

-q/-quiet: turns off debug
]],
[[$$Commands!
  These commands can use the "side" command

COMMAND [screen] [text]: Sends text to the connected turtle. See turtle commands for valid commands

REMOVE [screen]: Removes the selected screen (cannot remove the main screen)

THEME [screen] [name]: Sets the theme of the given screen. THEME [screen] resets the screen to default theme
$$Commands!
  These commands can use the "side" command

COLOR [screen] [typeName] [textColor] [backColor]: Changes the local theme of the screen. If the screen has no theme, it changes the global default theme. See notes on "colorEditor" parameter for more info

RECEIVE [screen] [channel]: Changes the receive channel of the given screen

SEND [screen] [channel]: Changes the send channel of the given screen (for whatever reason)
$$Commands!
  These are regular commands

SET [text]: Sets a default command that can be backspaced. Useful for color editing or command sending

SIDE [screen]: Sets a default screen for "sided" commands

EXIT/QUIT: Quits the program gracefully

THEME [name]: Sets the default theme.
$$Commands!
  These are regular commands

COLOR [themeName] [typeColor] [textColor] [backColor]: Sets the the text and background colors of the given typeColor of the given theme. See notes on "colorEditor" parameter for more info

SAVETHEME [themeName] [fileName]: Saves the given theme as fileName for later use

AUTO [channelList]: Automatically searches for nearby screens, providing them sequentially with channels if a channel list is given
  Example Use: AUTO 1 2 5 9
$$Commands!
  These are regular commands
  
HELP: Displays this again!

VERBOSE: Turns debug on

QUIET: Turns debug off

]],
[[$$Turtle Commands!

Stop: Stops the turtle where it is

Return: The turtle will return to its starting point, drop off its load, and stop

Drop: Turtle will immediately go and drop its inventory

Pause: Pauses the turtle

Resume: Resumes paused turtles
]]
}

--Generic Functions--
local function debug(...)
  --if doDebug then return print(...) end --Basic
  if doDebug then
    print("\nDEBUG: ",...)
    os.pullEvent("char")
  end
end
local function clearScreen(x,y, periph)
  periph, x, y = periph or term, x or 1, y or 1
  periph.clear()
  periph.setCursorPos(x,y)
end
  
local function swapKeyValue(tab)
  for a,b in pairs(tab) do
    tab[b] = a
  end
  return tab
end
local function copyTable(tab)
  local toRet = {}
  for a,b in pairs(tab) do
    toRet[a] = b
  end
  return toRet
end
local function checkChannel(num)
  num = tonumber(num) 
  if not num then return false end
  if 1 <= num and num <= 65535 then
    return num
  end
  return false
end
local function truncate(text, xDim)
  return text:sub(1,xDim-3).."..."
end
local function align(text, xDim, direction)
  text = tostring(text or "None")
  if #text >= xDim then return truncate(text,xDim) end
  for i=1, xDim-#text do
    if direction == "right" then
      text = " "..text
    elseif direction == "left" then
      text = text.." "
    end
  end
  return text
end
local function alignR(text, xDim)
  return align(text, xDim, "right")
end
local function alignL(text, xDim)
  return align(text, xDim, "left")
end
local function center(text, xDim)
  xDim = xDim or dim[1] --Temp fix
  local a = (xDim-#text)/2
  for i=1, a do
    text = " "..text.." "
  end
  return text  
end
local function roundNegative(num) --Rounds numbers up to 0
  if num >= 0 then return num else return 0 end
end
local function displayHelp()
  local tab = {}
  local indexOuter = "main"
  local indexInner = 1
  for key, value in pairs(helpResources) do
    tab[key] = {}
    for a in value:gmatch("$$([^$]+)") do
      table.insert(tab[key], a) --Just inserting pages
    end
  end
  while true do
    clearScreen()
    print(tab[indexOuter][indexInner])
    local text = tostring(indexInner).."/"..tostring(#tab[indexOuter])
    term.setCursorPos(({term.getSize()})[1]-#text,1)
    term.write(text) --Print the current page number
    local event, key = os.pullEvent("key")
    key = keyMap[key]
    if tonumber(key) and tab[tonumber(key)] then
      indexOuter = tonumber(key)
      indexInner = 1
    elseif key == "Q" then
      os.pullEvent("char") --Capture extra event (note: this always works because only q triggers this)
      return true
    elseif key == "0" then --Go back to beginning
      indexOuter, indexInner = "main",1
    elseif key == "up" and indexInner > 1 then
      indexInner = indexInner-1
    elseif key == "down" and indexInner < #tab[indexOuter] then
      indexInner = indexInner + 1
    end
  end
    
end


local function testPeripheral(periph, periphFunc)
  if type(periph) ~= "table" then return false end
  if type(periph[periphFunc]) ~= "function" then return false end
  if periph[periphFunc]() == nil then --Expects string because the function could access nil
    return false
  end
  return true
end

local function initModem() --Sets up modem, returns true if modem exists
  if not testPeripheral(modem, "isWireless") then
    if modemSide then
      if peripheral.getType(modemSide) == "modem" then
        modem = peripheral.wrap(modemSide)    
        if modem.isWireless and not modem.isWireless() then --Apparently this is a thing
          modem = nil
          return false
        end
        return true
      end
    end
    if peripheral.find then
      modem = peripheral.find("modem", function(side, obj) return obj.isWireless() end)
    end
    return modem and true or false
  end
  return true
end

--COLOR/THEME RELATED
for a, b in pairs(colors) do --This is so commands color commands can be entered in one case
  colors[a:lower()] = b
end
colors.none = 0 --For adding things

local requiredColors = {"default","title", "subtitle", "pos", "dim", "extra", "error", "info", "inverse", "command", "help", "background"}

local function checkColor(name, text, back) --Checks if a given color works
  local flag = false
  for a, b in ipairs(requiredColors) do
    if b == name then
      flag = true
      break
    end
  end
  if not flag or not (tonumber(text) or colors[text]) or not (tonumber(back) or colors[back]) then return false end
  return true
end
  

local themes = {} --Loaded themes, gives each one a names
local function newTheme(name)
  name = name:lower() or "none"
  local self = {name = name}
  self.addColor = function(self, colorName, text, back) --Colors are optional. Will default to "default" value. Make sure default is a color
    if colorName == "default" and (not text or not back) then return self end
    if not text then text = 0 end
    if not back then back = 0 end
    if not checkColor(colorName, text, back) then debug("Color check failed: ",name," ",text," ",back); return self end --Back or black because optional
    colorName = colorName or "none"
    self[colorName] = {text = text, background = back}
    return self --Allows for chaining :)
  end
  themes[name] = self
  return self
end

local function parseTheme(file)
  local addedTheme = newTheme(file:match("^.-\n") or "newTheme") --Initializes the new theme to the first line
  file:sub(file:find("\n") or 1) --If there is a newLine, this cuts everything before it. I don't care that the newLine is kept
  for line in file:gmatch("[^\n]+\n") do --Go through all the color lines (besides first one)
    local args = {}
    for word in line:gmatch("%S+") do
      table.insert(args,word)
    end
    addedTheme:addColor(args[1]:match("%a+") or "nothing", tonumber(args[2]) or colors[args[2]], tonumber(args[3]) or colors[args[3]]) --"nothing" will never get used, so its just lazy error prevention
  end
  local flag = true --Make sure a theme has all required elements
  for a,b in ipairs(requiredColors) do
    if not addedTheme[b] then
      flag = false 
      debug("Theme is missing color '",b,"'")
    end
  end
  if not flag then
    themes[addedTheme.name] = nil
    debug("Failed to load theme")
    return false
  end
  return addedTheme
end
--This is how adding colors will work
--regex for adding:
--(\w+) (\w+) (\w+)
--  \:addColor\(\"\1\"\, \2\, \3\)


newTheme("default")
  :addColor("default",colors.white, colors.black)
  :addColor("title", colors.green, colors.gray)
  :addColor("subtitle", colors.white, colors.black)
  :addColor("pos", colors.green, colors.black)
  :addColor("dim", colors.lightBlue, colors.black)
  :addColor("extra", colors.lightGray, colors.black)
  :addColor("error", colors.red, colors.white)
  :addColor("info", colors.blue, colors.lightGray)
  :addColor("inverse", colors.yellow, colors.blue)
  :addColor("command", colors.lightBlue, colors.black)
  :addColor("help", colors.red, colors.white)
  :addColor("background", colors.white, colors.black)
  
newTheme("blue")
  :addColor("default",colors.white, colors.blue)
  :addColor("title", 2048, 8192)
  :addColor("subtitle", 1, 2048)
  :addColor("pos", 16, 2048)
  :addColor("dim", 4096, 2048)
  :addColor("extra", 8, 2048)
  :addColor("error",  8, 16384)
  :addColor("info", 2048, 256)
  :addColor("inverse", 2048, 1)
  :addColor("command", 2048, 8)
  :addColor("help", 16384, 1)
  :addColor("background", 1, 2048)
  
newTheme("seagle")
  :addColor("default",colors.white, colors.black)
  :addColor("title", colors.white, colors.black)
  :addColor("subtitle", colors.red, colors.black)
  :addColor("pos", colors.gray, colors.black)
  :addColor("dim", colors.lightBlue, colors.black)
  :addColor("extra", colors.lightGray, colors.black)
  :addColor("error", colors.red, colors.white)
  :addColor("info", colors.blue, colors.lightGray)
  :addColor("inverse", colors.yellow, colors.lightGray)
  :addColor("command", colors.lightBlue, colors.black)
  :addColor("help", colors.red, colors.white)
  :addColor("background", colors.white, colors.black)
  
newTheme("random")
  :addColor("default",colors.white, colors.black)
  :addColor("title", colors.pink, colors.blue)
  :addColor("subtitle", colors.black, colors.white)
  :addColor("pos", colors.green, colors.black)
  :addColor("dim", colors.lightBlue, colors.black)
  :addColor("extra", colors.lightGray, colors.lightBlue)
  :addColor("error", colors.white, colors.yellow)
  :addColor("info", colors.blue, colors.lightGray)
  :addColor("inverse", colors.yellow, colors.lightGray)
  :addColor("command", colors.green, colors.lightGray)
  :addColor("help", colors.white, colors.yellow)
  :addColor("background", colors.white, colors.red)
  
newTheme("rainbow")
  :addColor("dim", 32, 0)
  :addColor("background", 16384, 0)
  :addColor("extra", 2048, 0)
  :addColor("info", 2048, 0)
  :addColor("inverse", 32, 0)
  :addColor("subtitle", 2, 0)
  :addColor("title", 16384, 0)
  :addColor("error", 1024, 0)
  :addColor("default", 1, 512)
  :addColor("command", 16, 0)
  :addColor("pos", 16, 0)
  :addColor("help", 2, 0)
  
--If you modify a theme a bunch and want to save it
local function saveTheme(theme, fileName)
  if not theme or not type(fileName) == "string" then return false end
  local file = fs.open(fileName,"w")
  if not file then return false end
  file.writeLine(fileName)
  for a,b in pairs(theme) do
    if type(b) == "table" then --If it contains color objects
      file.writeLine(a.." "..tostring(b.text).." "..tostring(b.background))
    end
  end
  file.close()
  return true
end

  
--==SCREEN CLASS FUNCTIONS==
local screenClass = {} --This is the class for all monitor/screen objects
screenClass.screens = {} --A simply numbered list of screens
screenClass.sides = {} --A mapping of screens by their side attached
screenClass.channels = {} --A mapping of receiving channels that have screens attached. Used for the receiver part
screenClass.sizes = {{7,18,29,39,50}, {5,12,19} , computer = {51, 19}, turtle = {39,13}, pocket = {26,20}}

screenClass.setTextColor = function(self, color) --Accepts raw color
  if color and self.term.isColor() then
    self.textColor = color
    self.term.setTextColor(color)
    return true
  end
  return false
end
screenClass.setBackgroundColor = function(self, color) --Accepts raw color
  if color and self.term.isColor() then
    self.backgroundColor = color
    self.term.setBackgroundColor(color)
    return true
  end
  return false
end
screenClass.setColor = function(self, color) --Wrapper, accepts themecolor objects
  if type(color) ~= "table" then error("Set color received a non-table",2) end
  local text, back = color.text, color.background
  if not text or text == 0 then text = self.theme.default.text end
  if not back or back == 0  then back = self.theme.default.background end
  return self:setTextColor(text) and self:setBackgroundColor(back)
end

screenClass.themeName = "default" --Setting super for fallback
screenClass.theme = themes.default


screenClass.new = function(side, receive, themeFile)
  local self = {}
  setmetatable(self, {__index = screenClass}) --Establish Hierarchy
  self.side = side
  if side == "computer" then
    self.term = term
  else
    self.term = peripheral.wrap(side)
    if not (self.term and peripheral.getType(side) == "monitor") then --Don't create an object if it doesn't exist
      if doDebug then
        error("No monitor on side "..tostring(side))
      end
      self = nil --Save memory?
      return false
    end
  end
  
  --Channels and ids
  self.receive = tonumber(receive) --Receive Channel
  self.send = nil --Reply Channel, obtained in handshake
  self.id = #screenClass.screens+1
  --Colors
  self.themeName = nil --Will be set by setTheme
  self.theme = nil 
  self.isColor = self.term.isColor() --Just for convenience
  --Other Screen Properties
  self.dim = {self.term.getSize()} --Raw dimensions
  --Initializations
  self.isDone = false --Flag for when the turtle is done transmitting
  self.size = {} --Screen Size, assigned in setSize
  self.textColor = colors.white --Just placeholders until theme is loaded and run
  self.backColor = colors.black
  self.toPrint = {}
  self.isComputer = false
  self.isTurtle = false
  self.isPocket = false
  self.acceptsInput = false
  self.legacy = false --Whether it expects tables or strings
  self.rec = { --Initial values for all displayed numbers
    label = "Quarry Bot",
    id = 1, 
    percent = 0,
    xPos = 0,
    zPos = 0,
    layersDone = 0,
    x = 0,
    z = 0,
    layers = 0,
    openSlots = 0,
    mined = 0,
    moved = 0,
    chestFull = false,
    isAtChest = false,
    isGoingToNextLayer = false,
    foundBedrock = false,
    fuel = 0,
    volume = 0,
    distance = 0,
    yPos = 0
    --Maybe add in some things like if going to then add a field
  }
  
  screenClass.screens[self.id] = self
  screenClass.sides[self.side] = self
  if self.receive then
    modem.open(self.receive) --Modem should be defined by the time anything is open
    screenClass.channels[self.receive] = self --If anyone ever asked, you could have multiple screens per channel, but its silly if no one ever needs it
  end
  self:setSize() --Finish Initialization
  self:setTheme(themeFile)
  return self
end

screenClass.remove = function(tab) --Cleanup function
  if type(tab) == "number" then --Expects table, can take id (for no apparent reason)
    tab = screenClass.screens[tab]
  end
  tab:removeStation()
  if tab.side == "REMOVED" then return end
  if tab.side == "computer" then error("Tried removing computer screen",2) end --This should never happen
  tab:reset() --Clear screen
  tab:say("Removed", tab.theme.info, 1) --Let everyone know whats up
  screenClass.screens[tab.id] = {side = "REMOVED"} --Not nil because screw up len()
  screenClass.sides[tab.side] = nil
  tab:removeChannel()
end

--Init Functions
screenClass.removeChannel = function(self)
  self.send = nil
  if self.receive then
    screenClass.channels[self.receive] = nil
    if modem and modem.isOpen(self.receive) then
      modem.close(self.receive)
    end
    self.receive = nil
  end
end

screenClass.setChannel = function(self, channel)
  if self.isStation then return false end --Don't want to set channel station
  self:removeChannel()
  if type(channel) == "number" then
    self.receive = channel
    screenClass.channels[self.receive] = self
    if modem and not modem.isOpen(channel) then modem.open(channel) end
  end
end

screenClass.removeStation = function(self)
  if self.isStation then
    for i=1, #stationsList do --No IDs so have to do a linear traversal
      if stationsList[i] == self then table.remove(stationsList, i) end
    end
  end
  self.isStation = false
end
  
screenClass.setSize = function(self) --Sets screen size
  if self.side ~= "computer" and not self.term then self.term = peripheral.wrap(self.side) end
  if not self.term.getSize() then --If peripheral is having problems/not there. Don't go further than term, otherwise index nil (maybe?)
    debug("There is no term...")
    self.updateDisplay = function() end --Do nothing on screen update, overrides class
    return true
  elseif not self.receive then
    self:setBrokenDisplay() --This will prompt user to set channel
  elseif self.send then --This allows for class inheritance
    self:setNormalDisplay() --In case objects have special updateDisplay methods --Remove function in case it exists, defaults to super
  else --If the screen needs to have a handshake display
    self:setHandshakeDisplay()
  end
  self.dim = { self.term.getSize()}
  local tab = screenClass.sizes
  for a=1, 2 do --Want x and y dim
    for b=1, #tab[a] do --Go through all normal sizes, x and y individually
      if tab[a][b] <= self.dim[a] then --This will set size higher until false
        self.size[a] = b
      end
    end
  end
  local function isThing(toCheck, thing) --E.G. isThing(self.dim,"computer")
    return toCheck[1] == tab[thing][1] and toCheck[2] == tab[thing][2]
  end
  self.isComputer = isThing(self.dim, "computer")
  self.isTurtle = isThing(self.dim, "turtle")
  self.isPocket = isThing(self.dim, "pocket")
  self.acceptsInput = self.isComputer or self.isTurtle or self.isPocket
  return self
end

screenClass.setTheme = function(self, themeName, stopReset)
  if not themes[themeName] then --If we don't have it already, try to load it
    local fileName = themeName or ".." --.. returns false and I don't think you can name a file this
    if fs.exists(themeFolder) then fileName = themeFolder..fileName end
    if fs.exists(fileName) then
      debug("Loading theme: ",fileName)
      local file = fs.open(fileName, "r")
      if not file then debug("Could not load theme '",themeName,"' file not found") end
      parseTheme(file.readAll()) --Parses the text to make a theme, returns theme
      file.close()
      self.themeName = themeName:lower() --We can now set our themeName to the fileName
    else
      --Resets theme to super
      if not stopReset then --This exists so its possible to set default theme without breaking world
        self.themeName = nil
        self.theme = nil
      end
      return false
    end
   else
    self.themeName = themeName:lower()
   end
   self.theme = themes[self.themeName] --Now the theme is loaded or the function doesn't get here
   return true
end

--Adds text to the screen buffer
screenClass.tryAddRaw = function(self, line, text, color, ...) --This will try to add text if Y dimension is a certain size
  local doAdd = {...} --booleans for small, medium, and large
  if type(text) ~= "string" then error("tryAddRaw got "..type(text)..", expected string",2) end
  if not text then
    debug("tryAddRaw got no string on line ",line)
    return false
  end
  if type(color) ~= "table" then error("tryAddRaw did not get a color",2) end
  --color = color or {text = colors.white}
  for i=1, ySizes do --As of now there are 3 Y sizes
    local test = doAdd[i]
    if test == nil then test = doAdd[#doAdd] end --Set it to the last known setting if doesn't exist
    if test and self.size[2] == i then --If should add this text for this screen size and the monitor is this size
      if #text <= self.dim[1] then
        self.toPrint[line] = {text = text, color = color}
        return true
      else
        debug("Tried adding '",text,"' on line ",line," but was too long: ",#text," vs ",self.dim[1])
      end
    end
  end
  return false
end
screenClass.tryAdd = function(self, text, color,...) --Just a wrapper
  return self:tryAddRaw(#self.toPrint+1, text, color, ...)
end
screenClass.tryAddC = function(self, text, color, ...) --Centered text
  return self:tryAdd(center(text, self.dim[1]), color, ...)
end

screenClass.reset = function(self,color)
  color = color or self.theme.background
  self:setColor(color)
  self.term.clear()
  self.term.setCursorPos(1,1)
end
screenClass.say = function(self, text, color, line)
  local currColor = self.backgroundColor
  color = color or debug("Printing ",text," but had no themeColor: ",self.theme.name) or {} --Set default for nice error, alert that errors occur
  self:setColor(color)
  local line = line or ({self.term.getCursorPos()})[2] or self:setSize() or 1 --If current yPos not found, sets screen size and moves cursor to 1
  if doDebug and #text > self.dim[1] then error("Tried printing: '"..text.."', but was too big") end
  self.term.setCursorPos(1,line)
  for i=1, self.dim[1]-#text do --This is so the whole line's background gets filled.
    text = text.." "
  end
  self.term.write(text)
  self.term.setCursorPos(1, line+1)
end
screenClass.pushScreenUpdates = function(self)
  for i=1, self.dim[2] do
    local tab = self.toPrint[i]
    if tab then
      self:say(tab.text, tab.color, i)
    end
  end
  self.term.setCursorPos(1,self.dim[2]) --So we can see errors
end

screenClass.updateNormal = function(self) --This is the normal updateDisplay function
  local str = tostring
  self.toPrint = {} --Reset table
  local message, theme = self.rec, self.theme
  
  if not self.isDone then --Normally
    
      
    if self.size[1] == 1 then --Small Width Monitor
      if not self:tryAdd(message.label, theme.title, false, false, true) then --This will be a title, basically
        self:tryAdd("Quarry!", theme.title, false, false, true)
      end
      
      self:tryAdd("-Fuel-", theme.subtitle , false, true, true)
      if not self:tryAdd(str(message.fuel), theme.extra, false, true, true) then --The fuel number may be bigger than the screen
        self:tryAdd("A lot", theme.extra, false, true, true)
      end
      
      self:tryAdd("--%%%--", theme.subtitle, false, true, true)
      self:tryAdd(alignR(str(message.percent).."%", 7), theme.pos , false, true, true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
      self:tryAdd(center(str(message.percent).."%", self.dim[1]), theme.pos, true, false) --I want it to be centered on 1x1
      
      self:tryAdd("--Pos--", theme.subtitle, false, true, true)
      self:tryAdd("X:"..alignR(str(message.xPos), 5), theme.pos, true)
      self:tryAdd("Z:"..alignR(str(message.zPos), 5), theme.pos , true)
      self:tryAdd("Y:"..alignR(str(message.layersDone), 5), theme.pos , true)
      
      if not self:tryAdd(str(message.x).."x"..str(message.z).."x"..str(message.layers), theme.dim , true, false) then --If you can't display the y, then don't
        self:tryAdd(str(message.x).."x"..str(message.z), theme.dim , true, false)
      end
      self:tryAdd("--Dim--", theme.subtitle, false, true, true)
      self:tryAdd("X:"..alignR(str(message.x), 5), theme.dim, false, true, true)
      self:tryAdd("Z:"..alignR(str(message.z), 5), theme.dim, false, true, true)
      self:tryAdd("Y:"..alignR(str(message.layers), 5), theme.dim, false, true, true)
      
      self:tryAdd("-Extra-", theme.subtitle, false, false, true)
      self:tryAdd(alignR(textutils.formatTime(os.time()):gsub(" ","").."", 7), theme.extra, false, false, true) --Adds the current time, formatted, without spaces.
      self:tryAdd("Open:"..alignR(str(message.openSlots),2), theme.extra, false, false, true)
      self:tryAdd("Dug"..alignR(str(message.mined), 4), theme.extra, false, false, true)
      self:tryAdd("Mvd"..alignR(str(message.moved), 4), theme.extra, false, false, true)
      if message.chestFull then
        self:tryAdd("ChstFll", theme.error, false, false, true)
      end
      
    end
    if self.size[1] == 2 then --Medium Monitor
      if not self:tryAdd(message.label, theme.title, false, false, true) then --This will be a title, basically
        self:tryAdd("Quarry!", theme.title, false, false, true)
      end
      
      self:tryAdd("-------Fuel-------", theme.subtitle , false, true, true)
      if not self:tryAdd(str(message.fuel), theme.extra, false, true, true) then --The fuel number may be bigger than the screen
        self.toPrint[#self.toPrint] = nil
        self:tryAdd("A lot", theme.extra, false, true, true)
      end
      
      self:tryAdd(str(message.percent).."% Complete", theme.pos , true) --This can be an example. Print (receivedMessage).percent in blue on all different screen sizes
      
      self:tryAdd("-------Pos--------", theme.subtitle, false, true, true)
      self:tryAdd("X Coordinate:"..alignR(str(message.xPos), 5), theme.pos, true)
      self:tryAdd("Z Coordinate:"..alignR(str(message.zPos), 5), theme.pos , true)
      self:tryAdd("On Layer:"..alignR(str(message.layersDone), 9), theme.pos , true)
      
      if not self:tryAdd("Size: "..str(message.x).."x"..str(message.z).."x"..str(message.layers), theme.dim , true, false) then --This is already here... I may as well give an alternative for those people with 1000^3quarries
        self:tryAdd(str(message.x).."x"..str(message.z).."x"..str(message.layers), theme.dim , true, false)
      end
      self:tryAdd("-------Dim--------", theme.subtitle, false, true, true)
      self:tryAdd("Total X:"..alignR(str(message.x), 10), theme.dim, false, true, true)
      self:tryAdd("Total Z:"..alignR(str(message.z), 10), theme.dim, false, true, true)
      self:tryAdd("Total Layers:"..alignR(str(message.layers), 5), theme.dim, false, true, true)
      self:tryAdd("Volume"..alignR(str(message.volume),12), theme.dim, false, false, true)
      
      self:tryAdd("------Extras------", theme.subtitle, false, false, true)
      self:tryAdd("Time: "..alignR(textutils.formatTime(os.time()):gsub(" ","").."", 12), theme.extra, false, false, true) --Adds the current time, formatted, without spaces.
      self:tryAdd("Used Slots:"..alignR(str(16-message.openSlots),7), theme.extra, false, false, true)
      self:tryAdd("Blocks Mined:"..alignR(str(message.mined), 5), theme.extra, false, false, true)
      self:tryAdd("Spaces Moved:"..alignR(str(message.moved), 5), theme.extra, false, false, true)
      if message.status then
        self:tryAdd(message.status, theme.info, false, false, true)
      end
      if message.chestFull then
        self:tryAdd("Chest Full, Fix It", theme.error, false, true, true)
      end
    end
    if self.size[1] >= 3 then --Large or larger screens
      if not self:tryAdd(message.label..alignR(" Turtle #"..str(message.id),self.dim[1]-#message.label), theme.title, true) then
        self:tryAdd("Your turtle's name is long...", theme.title, true)
      end
      self:tryAdd("Fuel: "..alignR(str(message.fuel),self.dim[1]-6), theme.extra, true)
      
      self:tryAdd("Percentage Done: "..alignR(str(message.percent).."%",self.dim[1]-17), theme.pos, true)
      
      local var1 = math.max(#str(message.x), #str(message.z), #str(message.layers))
      local var2 = (self.dim[1]-6-var1+3)/3
      self:tryAdd("Pos: "..alignR(" X:"..alignR(str(message.xPos),var1),var2)..alignR(" Z:"..alignR(str(message.zPos),var1),var2)..alignR(" Y:"..alignR(str(message.layersDone),var1),var2), theme.pos, true)
      self:tryAdd("Size:"..alignR(" X:"..alignR(str(message.x),var1),var2)..alignR(" Z:"..alignR(str(message.z),var1),var2)..alignR(" Y:"..alignR(str(message.layers),var1),var2), theme.dim, true)
      self:tryAdd("Volume: "..str(message.volume), theme.dim, false, true, true)
      self:tryAdd("",{}, false, false, true)
      self:tryAdd(center("____---- EXTRAS ----____",self.dim[1]), theme.subtitle, false, false, true)
      self:tryAdd(center("Time:"..alignR(textutils.formatTime(os.time()),8), self.dim[1]), theme.extra, false, true, true)
      self:tryAdd(center("Current Day: "..str(os.day()), self.dim[1]), theme.extra, false, false, true)
      self:tryAdd("Used Inventory Slots: "..alignR(str(16-message.openSlots),self.dim[1]-22), theme.extra, false, true, true)
      self:tryAdd("Blocks Mined: "..alignR(str(message.mined),self.dim[1]-14), theme.extra, false, true, true)
      self:tryAdd("Blocks Moved: "..alignR(str(message.moved),self.dim[1]-14), theme.extra, false, true, true)
      self:tryAdd("Distance to Turtle: "..alignR(str(message.distance), self.dim[1]-20), theme.extra, false, false, true)
      self:tryAdd("Actual Y Pos (Not Layer): "..alignR(str(message.yPos), self.dim[1]-26), theme.extra, false, false, true)
      
      if message.chestFull then
        self:tryAdd("Dropoff is Full, Please Fix", theme.error, false, true, true)
      end
      if message.foundBedrock then
        self:tryAdd("Found Bedrock! Please Check!!", theme.error, false, true, true)
      end
      if message.status then
        self:tryAdd("Turtle Status: "..message.status, theme.info, false, true, true)
      end
      if message.isAtChest then
        self:tryAdd("Turtle is at home chest", theme.info, false, true, true)
      end
      if message.isGoingToNextLayer then
        self:tryAdd("Turtle is going to next layer", theme.info, false, true, true)
      end
    end
  else --If is done
    if self.size[1] == 1 then --Special case for small monitors
      self:tryAdd("Done", theme.title, true)
      self:tryAdd("Dug"..alignR(str(message.mined),4), theme.pos, true)
      self:tryAdd("Fuel"..alignR(str(message.fuel),3), theme.pos, true)
      self:tryAdd("-------", theme.subtitle, false,true,true)
      self:tryAdd("Turtle", theme.subtitle, false, true, true)
      self:tryAdd(center("is", self.dim[1]), theme.subtitle, false, true, true)
      self:tryAdd(center("Done!", self.dim[1]), theme.subtitle, false, true, true)
    else
      self:tryAdd("Done!", theme.title, true)
      self:tryAdd("Curr Fuel: "..str(message.fuel), theme.pos, true)
      if message.preciseTotals then
        local tab = {}
        for a,b in pairs(message.preciseTotals) do --Sorting the table
          a = a:match(":(.+)")
          if #tab == 0 then --Have to initialize or rest does nothing :)
            tab[1] = {a,b}
          else
            for i=1, #tab do --This is a really simple sort. Probably not very efficient, but I don't care.
              if b > tab[i][2] then --Gets the second value from the table, which is the itemCount
                table.insert(tab, i, {a,b})
                break
              elseif i == #tab then --Insert at the end if not bigger than anything
                table.insert(tab,{a,b})
              end
            end
          end
        end
        for i=1, #tab do --Print all the blocks in order
          local firstPart = "#"..tab[i][1]..": "
          self:tryAdd(firstPart..alignR(tab[i][2], self.dim[1]-#firstPart), (i%2 == 0) and theme.inverse or theme.info, true, true, true) --Switches the colors every time
        end
      else
        self:tryAdd("Blocks Dug: "..str(message.mined), theme.inverse, true)
        self:tryAdd("Cobble Dug: "..str(message.cobble), theme.pos, false, true, true)
        self:tryAdd("Fuel Dug: "..str(message.fuelblocks), theme.pos, false, true, true)
        self:tryAdd("Others Dug: "..str(message.other), theme.pos, false, true, true)
      end
    end
  end
end
screenClass.updateHandshake = function(self)
  self.toPrint = {}
  local half = math.ceil(self.dim[2]/2)
  if self.size[1] == 1 then --Not relying on the parameter system because less calls
    self:tryAddRaw(half-2, "Waiting", self.theme.error, true)
    self:tryAddRaw(half-1, "For Msg", self.theme.error, true)
    self:tryAddRaw(half, "On Chnl", self.theme.error, true)
    self:tryAddRaw(half+1, tostring(self.receive), self.theme.error, true)
  else
    local str = "for"
    if self.size[1] == 2 then str = "4" end--Just a small grammar change
    self:tryAddRaw(half-2, "", self.theme.error, true) --Filler
    self:tryAddRaw(half-1, center("Waiting "..str.." Message", self.dim[1]), self.theme.error, true)
    self:tryAddRaw(half, center("On Channel "..tostring(self.receive), self.dim[1]), self.theme.error, true)
    self:tryAddRaw(half+1, "",self.theme.error, true)
  end
end
screenClass.updateBroken = function(self) --If screen needs channel
  self.toPrint = {}
  if self.size[1] == 1 then
    self:tryAddC("No Rec", self.theme.pos, false, true, true)
    self:tryAddC("Channel", self.theme.pos, false, true, true)
    self:tryAddC("-------", self.theme.title, false, true, true)
    self:tryAddC("On Comp", self.theme.info, true)
    self:tryAddC("Type:", self.theme.info, true)
    self:tryAddC("RECEIVE", self.theme.command, true)
    if not self:tryAddC(self.side:upper(), self.theme.command, true) then --If we can't print the full side
      self:tryAddC("[side]",self.theme.command, true)
    end
    self:tryAddC("[Chnl]", self.theme.command, true)
  else
    self:tryAddC("No receiving", self.theme.pos, false, true, true)
    self:tryAddC("channel for", self.theme.pos, false, true, true)
    self:tryAddC("this screen", self.theme.pos, false, true, true)
    self:tryAddC("-----------------", self.theme.title, false, true, true)
    self:tryAddC("On main computer,", self.theme.info, true)
    self:tryAddC("Type:", self.theme.info, true)
    self:tryAdd("", self.theme.command, false, true, true)
    self:tryAddC('"""', self.theme.command, false, true, true)
    self:tryAddC("RECEIVE", self.theme.command, true)
    if not self:tryAddC(self.side:upper(), self.theme.command, true) then --If we can't print the full side
      self:tryAddC("[side]",self.theme.command, true)
    end
    self:tryAddC("[desired channel]", self.theme.command, true)
    self:tryAddC('"""', self.theme.command, false, true, true)
  end
end
screenClass.updateStation = function(self)
  self.toPrint = {}
  sepChar = "| "
  local part = math.floor((self.dim[1]-3*#sepChar - 3)/3)
  self:tryAdd(alignL("ID",3)..sepChar..alignL("Side",part)..sepChar..alignL("Channel",part)..sepChar..alignL("Theme",part), self.theme.title, true, true, true)--Headings
  local line = ""
  for i=1, self.dim[1] do line = line.."-" end
  self:tryAdd(line, self.theme.title, false, true, true)
  for a,b in ipairs(screenClass.screens) do
    if b.side ~= "REMOVED" then
      self:tryAdd(alignL(b.id,3)..sepChar..alignL(b.side,part)..sepChar..alignL(b.receive, part)..sepChar..alignL(b.theme.name,part), self.theme.info, true, true, true)--Prints info about all screens
    end
  end
end

screenClass.updateDisplay = screenClass.updateNormal --Update screen method is normally this one

--Misc
screenClass.init = function(self) --Currently used by computer screen to replace its original method. This is called when instantiated and when unsetting station
  self.setNormalDisplay, self.setHandshakeDisplay, self.setBrokenDisplay = nil, nil, nil --Resets to super
  self:removeStation()
  self:setSize()
end 
screenClass.setNormalDisplay = function(self)
  self.updateDisplay = self.updateNormal --This defaults to super if doesn't exist
end
screenClass.setHandshakeDisplay = function(self)
  self.updateDisplay = self.updateHandshake --Sets update to handshake version, defaults to super if doesn't exist
end
screenClass.setBrokenDisplay = function(self)
  self.updateDisplay = self.updateBroken
end
screenClass.setStationDisplay = function(self) --Note: This only changes the "set" methods so that "update" methods remain intact per object :)
  self:removeChannel()
  self.setNormalDisplay = function(self) self.updateDisplay = self.updateStation end
  self.setHandshakeDisplay = self.setNormalDisplay
  self.setBrokenDisplay = self.setNormalDisplay
  self:setNormalDisplay()
  if not self.isStation then --Just in case this gets called more than once
    self.isStation = true
    table.insert(stationsList,self)
  end
end


local function wrapPrompt(prefix, str, dim) --Used to wrap the commandString
  return prefix..str:sub(roundNegative(#str+#prefix-computer.dim[1]+2), -1).."_" --it is str + 2 because we add in the "_"
end

local function updateAllScreens()
  for a, b in pairs(screenClass.sides) do
    b:updateDisplay()
    b:reset()
    b:pushScreenUpdates()
  end
end
--Rednet
local function newMessageID()
  return math.random(1,2000000000) --1 through 2 billion. Good enough solution
end
local function transmit(send, receive, message, legacy, fingerprint)
  fingerprint = fingerprint or replyFingerprint
  if legacy then
    modem.transmit(send, receive, message)
  else
    modem.transmit(send, receive, {message = message, id = newMessageID(), fingerprint = fingerprint})
  end
end

--QuadRotor
local function launchQuad(message)
  if quadEnabled and message.emergencyLocation then --This means the turtle is out of fuel. Also that it sent its two initial positions
    local movement = {}
    local function add(what) table.insert(movement,what) end
    add(quadDirection) --Get to the fuel chest
    add("suck")
    add(quadDirection) --So it can properly go down/up first
    local function go(dest, orig, firstMove) --Goes to a place. firstMove because I'm lazy. Its for getting away from computer. If false, its the second move so go one above turtle. If nothing then nothing
      local distX, distY, distZ = dest[1]-orig[1], dest[2]-orig[2], dest[3]-orig[3]
      if firstMove then
        distX = distX - 3 * (quadDirection == "east" and 1 or (quadDirection == "west" and -1 or 0))
        distZ = distZ - 3 * (quadDirection == "south" and 1 or (quadDirection == "north" and -1 or 0))
        distY = distY - 1 --Because the quad is a block above the first thing
      elseif firstMove == false then
        local num = 2
        if message.layersDone  <= 1 then
          num = 1
        end
        distY = distY + num * (distY < 0 and 1 or -1) --This is to be above the turtle and accounts for invert
      end
      add((distY > 0 and "up" or "down").." "..tostring(math.abs(distY)))
      add((distX > 0 and "east" or "west").." "..tostring(math.abs(distX))) 
      add((distZ > 0 and "south" or "north").." "..tostring(math.abs(distZ)))
      if firstMove == false and message.layersDone > 1 then
        add(distY < 0 and "down" or "up") --This is so it goes into the turtle's proper layer (invert may or may not work, actually)
      end
    end
    debug("Location Types")
    debug(computerLocation)
    debug(message.firstPos)
    debug(message.secondPos)
    debug(message.emergencyLocation)
    go(message.firstPos, computerLocation, true) --Get to original position of turtle
    go(message.secondPos,message.firstPos) --Get into quarry
    go(message.emergencyLocation, message.secondPos, false)
    
    add("drop")
    add("return")
    for a,b in pairs(movement) do
      debug(a,"   ",b)
    end
    quadBase.flyQuad(movement) --Note, if there are no quadrotors, nothing will happen and the turtle will sit forever
    
  end
end

--==SET UP==
clearScreen()
print("Welcome to Quarry Receiver!")
sleep(1)

--==ARGUMENTS==

--[[
Parameters:
  -help/-?/help/?
  -v/verbose --Turn on debugging
  -receiveChannel/channel [channel] --For only the main screen
  -theme --Sets a default theme
  -screen [side] [channel] [theme]
  -station
  -auto --Prompts for all sides, or you can supply a list of receive channels for random assignment!
  -colorEditor
  -quad [cardinal direction] --This looks for a quadrotor from the quadrotors mod. The direction is of the fuel chest.
  -autoRestart --Will reset any attached screen when done, instead of bricking them
]]

--tArgs init
local parameters = {} --Each command is stored with arguments

local function addParam(value)
  val = value:lower()
  if val:match("^%-") then
    parameters[#parameters+1] = {val:sub(2)} --Starts a chain with the command. Can be unpacked later
    parameters[val:sub(2)] = {} --Needed for force/before/after parameters
  elseif parameterIndex ~= 0 then
    table.insert(parameters[#parameters], value) --value because arguments should be case sensitive for filenames
    table.insert(parameters[parameters[#parameters][1]], value) --Needed for force/after parameters
  end
end

for a,b in ipairs(tArgs) do
  val = b:lower()
  if val == "help" or val == "-help" or val == "?" or val == "-?" or val == "usage" or val == "-usage" then
    displayHelp() --To make
    error("The End of Help",0)
  end
  addParam(b)
end

if parameters.v or parameters.verbose then --Why not
  doDebug = true
end

for i=1,#parameters do
  debug("Parameter: ",parameters[i][1])
end

--Options before screen loads
if parameters.theme then
  screenClass:setTheme(parameters.theme[1])
end

if parameters.modem then
  modemSide = parameters.modem[1]
end

if parameters.quad then
  if not parameters.quad[1] then parameters.quad[1] = "direction doesn't exist" end
  local dir = parameters.quad[1]:lower():sub(1,1)
  if quadDirections[dir] then
    quadEnabled = true
    quadDirection = quadDirections[dir]
  else
    clearScreen()
    print("Please specify the cardinal direction your quad station is in")
    print("Make sure you have a quad station on one side with a chest behind it, forming a line")
    print("Like this: [computer] [station] [fuel chest]")
    print("The program will now terminate")
    error("",0)
  end
end

if parameters.autorestart then
  local val = parameters.autorstart[1]
  if not val then
    autoRestart = true --Assume no value = force true
  else
   val = val:sub(1,1):lower()
   autoRestart = not (val == "n" or val == "f")
  end
end
    
--Init Modem
while not initModem() do
  clearScreen()
  print("No modem is connected, please attach one")
  if not peripheral.find then
    print("What side was that on?")
    modemSide = read()
  else
    os.pullEvent("peripheral")
  end
end
debug("Modem successfully connected!")

local function autoDetect(channels)
  if type(channels) ~= "table" then channels = {} end
  local tab = peripheral.getNames()
  local index = 1
  for i=1, #tab do
    if peripheral.getType(tab[i]) == "monitor" and not screenClass.sides[tab[i]] then
      screenClass.new(tab[i], channels[index]) --You can specify a list of channels in "auto" parameter
      index = index+1
    end
  end
end

--Init QuadRotor Station
if quadEnabled then
  local flag
  while not flag do
    for a,b in ipairs({"front","back","left","right","top"}) do
      if peripheral.isPresent(b) and peripheral.getType(b) == "quadbase" then
        quadBase = peripheral.wrap(b)
      end
    end
    clearScreen()
    if not quadBase then
      print("No QuadRotor Base Attached, please attach one")
    elseif quadBase.getQuadCount() == 0 then
      print("Please install at least one QuadRotor in the base")
      sleep(1) --Prevents screen flickering and overcalling gps
    else
      flag = true
      debug("QuadBase successfully connected!")
    end
    if not computerLocation and not gps.locate(5) then
      flag = false
      error("No GPS lock. Please make a GPS network to use quadrotors")
    else
      computerLocation = {gps.locate(5)}
      debug("GPS Location Acquired")
    end
  end
end

--Init Computer Screen Object (was defined at top)
computer = screenClass.new("computer", (parameters.receivechannel and parameters.receivechannel[1]) or (parameters.channel and parameters.channel[1]))--This sets channel, checking if parameter exists
computer.updateNormal = function(self)
  screenClass.upateNormal(self)
  computer:displayCommand()
end
computer.updateHandshake = function(self) --Not in setHandshake because that func checks object updateHandshake
  screenClass.updateHandshake(self)
  computer:displayCommand()
end
computer.updateBroken = function(self)
  screenClass.updateBroken(self)
  computer:displayCommand()
end
computer.updateStation = function(self)--This gets set in setSize
  screenClass.updateStation(self)
  self:displayCommand()
end


for i=1, #parameters do --Do actions for parameters that can be used multiple times
  local command, args = parameters[i][1], parameters[i] --For ease
  if command == "screen" then
    if not screenClass.sides[args[2]] then --Because this screwed up the computer
      local a = screenClass.new(args[2], args[3], args[4])
      debug(type(a))
    else
      debug("Overwriting existing screen settings for '",args[2],"'")
      local a = screenClass.sides[args[2]]
      a:setChannel(tonumber(args[3]))
      a:setTheme(args[4])
    end
  end
  if command == "station" then --This will set the screen update to display stats on all other monitors
    if not args[2] or args[2]:lower() == "computer" then
      computer:setStationDisplay() --This handles setting updateNormal, setHandshakeDisplay, etc
    else
      local a = screenClass.new(args[2], nil, args[3]) --This means syntax is -station [side] [theme]
      if a then --If the screen actually exists
        a:setStationDisplay()
      end
    end
  end
end

if parameters.auto then --This must go after computer declaration so computer ID is 1
  autoDetect(parameters.auto)
  addParam("-station") --Set computer as station
  addParam("computer") --Yes, I'm literally just feeding in more tArgs like from IO
end

computer.displayCommand = function(self)
  local sideString = ((defaultSide and " (") or "")..(defaultSide or "")..((defaultSide and ")") or "")
  if self.size == 1 then
    self:tryAddRaw(self.dim[2], wrapPrompt("Cmd"..sideString:sub(2,-2)..": ", commandString, self.dim[1]), self.theme.command, true)
  else
    self:tryAddRaw(self.dim[2], wrapPrompt("Command"..sideString..": ",commandString, self.dim[1]), self.theme.command, true) --This displays the last part of a string.
  end
end
--Initializing the computer screen
if parameters.coloreditor then

  computer:removeChannel() --So it doesn't receive messages
  computer.isStation = true --So we can't assign a channel
  
  computer.updateNormal = function(self) --This is only for editing colors
    self.toPrint = {}
    for i=1, #requiredColors do
      self:tryAdd(requiredColors[i], self.theme[requiredColors[i]],true)
    end
    self:displayCommand()
  end
  computer.updateHandshake = computer.updateNormal
  computer.updateBroken = computer.updateNormal
end
computer:setSize() --Update changes made to display functions

for a,b in pairs(screenClass.sides) do debug(a) end

--==FINAL CHECKS==

--Updating all screen for first time and making sure channels are open
for a, b in pairs(screenClass.sides) do
  if b.receive then --Because may not have channel
    if not modem.isOpen(b.receive) then modem.open(b.receive); debug("Opening channel ",b.receive) end
  end
  b:setSize()
  b:updateDisplay()--Finish initialization process
  b:reset()
  b:pushScreenUpdates()
end

--Handshake will be handled in main loop

--[[Workflow
  Wait for events
  modem_message
    if valid channel and valid message, update appropriate screen
  key
    if any letter, add to command string if room.
    if enter key
      if valid self command, execute command. Commands:
        command [side] [command] --If only one screen, then don't need channel. Send a command to a turtle
        screen [side] [channel] [theme] --Links a new screen to use.
        remove [side] --Removes a screen
        theme [themeName] --Sets the default theme
        theme [side] [themeName] --Changes this screen's theme
        savetheme [new name] [themeName]
        color [side/theme] [colorName] [textColor] [backgroundColor]
        side [side] --Sets a default side, added to prompts
        set [string] --Sets a default command, added to display immediately
        receive [side] [newChannel] --Changes the channel of the selected screen
        send [side] [newChannel]
        auto --Automatically adds screens not connected
        station --Sets the selected screen as a station (or resets if already a station)
        exit/quit/end
  peripheral_detach
    check what was lost, if modem, set to nil. If screen side, do screen:setSize()
  peripheral
    check if screen side already added
      reset screen size
  monitor_resize
    resize proper screen
  monitor_touch
    if screen already added
      select screen on main computer
    else
      add screen

]]

--Modes: 1 - Sided, 2 - Not Sided, 3 - Both sided and not
local validCommands = {command = 1, screen = 2, remove = 1, theme = 3, exit = 2, quit = 2, ["end"] = 2, color = 3, side = 2, set = 2, receive = 1, send = 1, savetheme = 2,
                       auto = 2, verbose = 2, quiet = 2, station = 1}
while continue do
  local event, par1, par2, par3, par4, par5 = os.pullEvent()
  ----MESSAGE HANDLING----
  if event == "modem_message" and screenClass.channels[par2] then --If we got a message for a screen that exists
    local screen = screenClass.channels[par2] --For convenience
    if not screen.send then --This is the handshake
      debug("\nChecking handshake. Received: ",par4)
      local flag = false
      if par4 == expectedMessage then --Legacy quarries don't accept receiver dropping in mid-run
        screen.legacy = true --Accepts serialized tables
        flag = true
      elseif type(par4) == "table" and par4.fingerprint == expectedFingerprint then --Don't care about expected message, allows us to start receiver mid-run, fingerprint should be pretty specific
        screen.legacy = false
        flag = true
      end
      
      if flag then
        screen.isDone = false
        debug("Screen ",screen.side," received a handshake")
        screen.send = par3
        screen:setSize() --Resets update method to proper since channel is set
        debug("Sending back on ",screen.send)
        transmit(screen.send,screen.receive, replyMessage, screen.legacy)
      end
    
    else --Everything else is for regular messages
      
      local rec
      if screen.legacy then --We expect strings here
        if type(par4) == "string" then --Otherwise its not ours
          if par4 == "stop" then --This is the stop message. All other messages will be ending ones
            screen.isDone = true
          elseif par4 == expectedMessage then --We support dropping in mid-run
            debug("Screen ",screen.side," received mid-run handshake")
            transmit(screen.send,screen.receive, replyMessage, screen.legacy)
          elseif textutils.unserialize(par4) then
            rec = textutils.unserialize(par4)
            rec.distance = par5
          end
        end
      elseif type(par4) == "table" and par4.fingerprint == expectedFingerprint then --Otherwise, we check if it is valid message
        
        if type(par4.message) == "table" then 
          rec = par4.message
          if not par4.distance then --This is cool because it can add distances from the repeaters
            rec.distance = par5
          else
            rec.distance = par4.distance + par5
          end
          if rec.isDone then
            screen.isDone = true
          end
        elseif par4.message == expectedMessage then
          debug("Screen ",screen.side," received mid-run handshake")
          transmit(screen.send,screen.receive, replyMessage, screen.legacy)
        else 
          debug("Message received did not contain table")
        end
      end
       
      if rec then
        rec.distance = math.floor(rec.distance)
        rec.label = rec.label or "Quarry!"
        screen.rec = rec --Set the table
        --Updating screen occurs outside of the if
        local toSend
        if screen.queuedMessage then
          toSend = screen.queuedMessage
          screen.queuedMessage = nil
        else
          toSend = replyMessage
        end
        transmit(screen.send,screen.receive, toSend, screen.legacy) --Send reply message for turtle
      end
      
    end
    
    launchQuad(screen.rec) --Launch the Quad! (This only activates when turtle needs it)
    
    screen:updateDisplay() --isDone is queried inside this
    screen:reset(screen.theme.background)
    screen:pushScreenUpdates() --Actually write things to screen
    if screen.isDone and not autoRestart then screen:removeChannel() end --Don't receive any more messages. Allows turtle to think connected. Done after message sending so no error :)
  
  ----KEY HANDLING----
  elseif event == "key" and keyMap[par1] then
    local key = keyMap[par1]
    if key ~= "enter" then --If we aren't submitting a command
      if key == "backspace" then
        if #commandString > 0 then
          commandString = commandString:sub(1,-2)
        end
      elseif key == "up" then
        commandString = lastCommand or commandString --Set to last command, or do nothing if it doesn't exist
      elseif key == "down" then
        commandString = "" --If key down, clear
      elseif #key == 1 then
        commandString = commandString..key
      end
    --ALL THE COMMANDS
    else --If we are submitting a command
      lastCommand = commandString --For using up arrow
      local args = {}
      for a in commandString:gmatch("%S+") do --This captures all individual words in the command string
        args[#args+1] = a:lower()
      end
      local command = args[1]
      if validCommands[command] then --If it is a valid command...
        local commandType = validCommands[command]
        if commandType == 1 or commandType == 3 then --If the command requires a "side" like transmitting commands, versus setting a default
          if defaultSide then table.insert(args, 2, defaultSide) end
          local screen 
          local test = screenClass.screens[tonumber(args[2])]
          if test and test.side ~= "REMOVED" then --This way we can specify IDs as well
            screen = test
          else
            screen = screenClass.sides[args[2]]
          end
          if screen then --If the side exists
            if command == "command" and screen.send then --If sending command to the turtle
              screen.queuedMessage = table.concat(args," ", 3) --Tells message handler to send appropriate message
              --transmit(screen.send, screen.receive, table.concat(args," ", 3), screen.legacy) --This transmits all text in the command with spaces. Duh this is handled when we get message
            end

            if command == "color" then
              screen.theme:addColor(args[3],colors[args[4]],colors[args[5]] )
              updateAllScreens() --Because we are changing a theme color which others may have
            end
            if command == "theme" then
              screen:setTheme(args[3])
            end
            if command == "send" then --This changes a send channel, and can also revert to handshake
              local chan = checkChannel(tonumber(args[3]) or -1)
              if chan then screen.send = chan else screen.send = nil end
              screen:setSize() --If on handshake, resets screen
            end
            if command == "receive" and not screen.isStation then
              local chan = checkChannel(tonumber(args[3]) or -1)
              if chan and not screenClass.channels[chan] then
                screen:setChannel(chan)
                screen:setSize() --Update broken status
              end
            end
            if command == "station" then
              if screen.isStation then screen:init() else screen:setStationDisplay() end
            end
            if command == "remove" and screen.side ~= "computer" then --We don't want to remove the main display!
              print()
              screen:remove()
            else --Because if removed it does stupid things
              screen:reset()
              debug("here")
              screen:updateDisplay()
              debug("Here")
              screen:pushScreenUpdates()
              debug("Hereer")
            end
          end
        end
        if commandType == 2 or commandType == 3 then--Does not require a screen side
          if command == "screen" and peripheral.getType(args[2]) == "monitor" then  --Makes sure there is a monitor on the screen side
            if not args[3] or not screenClass.channels[tonumber(args[3])] then --Make sure the channel doesn't already exist
              local mon = screenClass.new(args[2], args[3], args[4]) 
                --args[3] is the channel  and will set broken display if it doesn't exist
                --args[4] is the theme, and will default if doesn't exists.
              mon:updateDisplay()
              mon:reset()
              mon:pushScreenUpdates()
            end
          end
          if command == "theme" then
            screenClass:setTheme(args[2], true) --Otherwise this would set base theme to nil, erroring
            updateAllScreens()
          end
          if command == "color" and themes[args[2]] then
            themes[args[2]]:addColor(args[3],colors[args[4]],colors[args[5]])
            updateAllScreens() --Because any screen could have this theme
          end
          if command == "side" then
            if screenClass.sides[args[2]] then
              defaultSide = args[2]
            else
              defaultSide = nil
            end
          end
          if command == "set" then
            if args[2] then
              defaultCommand = table.concat(args," ",2)
              defaultCommand = defaultCommand:upper()
            else
              defaultCommand = nil
            end
          end
          if command == "savetheme" then
            if saveTheme(themes[args[2]], args[3]) then
              computer:tryAddRaw(computer.dim[2]-1, "Save Theme Succeeded!", computer.theme.inverse, true)
            else
              computer:tryAddRaw(computer.dim[2]-1, "Save Theme Failed!", computer.theme.inverse, true)
            end
            computer:reset()
            computer:pushScreenUpdates()
            sleep(1)
          end
          if command == "auto" then
            local newTab = copyTable(args) --This is so we can pass all additional words as channel numbers
            table.remove(newTab, 1)
            autoDetect(newTab)
            updateAllScreens()
          end
          if command == "verbose" then doDebug = true end
          if command == "quiet" then doDebug = false end
          if command == "quit" or command == "exit" or command == "end" then
            continue = false
          end
        end
      else
        debug("\nInvalid Command")
      end
      if defaultCommand then commandString = defaultCommand.." " else commandString = "" end --Reset command string because it was sent
    end
    
    
    --Update computer display (computer is only one that displays command string
    computer:updateDisplay() --Note: Computer's method automatically adds commandString to last line
    if not continue then computer:tryAddRaw(computer.dim[2]-1,"Program Exiting", computer.theme.inverse, false, true, true) end
    computer:reset()
    computer:pushScreenUpdates()
    
  elseif event == "monitor_resize" then
    local screen = screenClass.sides[par1]
    if screen then
      screen:setSize()
      screen:updateDisplay()
      screen:reset()
      screen:pushScreenUpdates()
    end
  elseif event == "monitor_touch" then
    local screen = screenClass.sides[par1]
    debug("Side: ",par1," touched")
    if screen then --This part is copied from the "side" command
      if defaultSide ~= par1 then
        defaultSide = par1
      else
        defaultSide = nil
      end
    else
      debug("Adding Screen")
      local mon = screenClass.new(par1)
      mon:reset()
      mon:updateDisplay()
      mon:pushScreenUpdates()
      
    end

  elseif event == "peripheral_detach" then
    local screen = screenClass.sides[par1]
    if screen then
      screen:setSize()
    end
    --if screen then
    --  screen:remove()
    --end
    
  elseif event == "peripheral" then
    local screen = screenClass.sides[par1]
    if screen then
      screen:setSize()
    end
    --Maybe prompt to add a new screen? I don't know
  
  end
  
  local flag = false --Saying all screens are done, must disprove
  local count = 0 --We want it to wait if no screens have channels
  for a,b in pairs(screenClass.channels) do
    count = count + 1
    if not b.isDone then
      flag = true
    end
  end
  if continue and count > 0 then --If its not already false from something else
    continue = flag
  end
  
  if #stationsList > 0 and event ~= "key" then --So screen is properly updated
    for a, b in ipairs(stationsList) do
      b:reset()
      b:updateDisplay()
      b:pushScreenUpdates()
    end
  end
  
  
end

sleep(1.5)
for a in pairs(screenClass.channels) do
  modem.close(a)
end
for a, b in pairs(screenClass.sides) do
  if not b.isDone then --Otherwise we want it display the ending stats
    b:setTextColor(colors.white)
    b:setBackgroundColor(colors.black)
    b.term.clear()
    b.term.setCursorPos(1,1)
  end
end

local text --Fun :D
if computer.isComputer then text = "SUPER COMPUTER OS 9000"
elseif computer.isTurtle then text = "SUPER DIAMOND-MINING OS XXX"
elseif computer.isPocket then text = "PoCkEt OOS AMAYZE 65"
end
if text and not computer.isDone then
  computer:say(text, computer.theme.title,1)
else
  computer.term.setCursorPos(1,computer.dim[2])
  computer.term.clearLine()
end
--Down here shut down all the channels, remove the saved file, other cleanup stuff

