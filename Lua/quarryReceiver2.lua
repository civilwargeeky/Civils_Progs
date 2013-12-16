--Quarry Receiver Version 3.4.0
--Made by Civilwargeeky
--[[
Ideas:
For session persistence, you probably only need to save what monitor and what turtle to connect with.
]]

local xSizes = {} --Monitor x dimensions, both should have a special "monitor" parameter
local ySizes = {} --Monitor y dimensions
local dim, screenSize = {}, {}
dim.x, dim.y = term.getSize() --I think this gets the size of the monitor
for i=1, min(#xSizes, #ySizes) do --Gets number of monitors by matching dimensions
  if dim.x == xSizes[i] then
    screenSize.x = i
  end
  if dim.y == ySizes[i] then
    screenSize.y = i
  end
end
local items = {}
--Sizes are different screen sizes, priority says if it will be run when not enough screen size, variable is the variable it gets from table, if exclusion, don't run.
local function addItem(sizesTab, priority, variable, exclusion) --Add an item that can be displayed on screen. Priority is number, variable and exclusion are strings
local toRet = {}
toRet.text = sizesTab[screenSize.x] or sizesTab[#sizesTab]
toRet.priority = priority
toRet.variable = variable
toRet.exclusion = exclusion
table.insert(items, toRet)
end
--[[
Items to add:
Title with computer name and number
Dimensions of quarry
Open space
Current Fuel
Percent Done
Current position x
Current position z
Current number of layers done
Number of blocks mined
Number of blocks moved
If going to next layer, if going back to start, if it home position.
Any errors, like chest is full or something.
]]
local rednetMessageToSend --This will be a command string sent to turtle




function main()

end

function rednet()
--Will send rednet message to send if it exists, otherwise sends default message.
end

function commandSender()

end
