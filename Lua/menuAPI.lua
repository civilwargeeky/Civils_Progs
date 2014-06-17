function titleize(text)
local x = term.getSize()
if #text+2 > x then return text:upper() end
text = " "..string.upper(text).." "
for i=1, math.floor((x-#text)/2) do
  text = "="..text.."="
end
return text
end
function sentenceCaseTable(tab) --Expects a prepared table or sequentially numbered
  local toRet = {} --So we don't go modifying people's tables
  for a, b in pairs(tab) do
    if type(b) == "table" then
      local toMod = (b.value or b.text) --Priority to value so you can have pretty yet functional tables
      table.insert(toRet[a], toMod:sub(1,1):upper()..toMod(2))
    elseif type(b) == "string" then
      toRet[a] = b:sub(1,1):upper()..b:sub(2)
    end
  end
  return toRet
 end
      
function prepareTable(tab)
  local toRet = {}
  for a,b in pairs(tab) do
    table.insert(toRet, {key = a, value = b})
  end
  return toRet
end

function menu(title, description, textTable, isNumbered, titleAlign, textAlign, prefixCharacter, suffixCharacter, spaceCharacter, incrementFunction)
local x, y = term.getSize() --Screen size
local currIndex, scroll = 1, 0 --currIndex is the item from the table it is on, scroll is how many down it should go.
local titleLines, descriptionLines = 0,0 --How many lines the title and description take up
local alignments = { left = "left", center = "center", right = "right" } --Used for checking if alignment is valid
if not (title and textTable) then error("Requires title and menu list",2) end
if not type(textTable) == "table" and #textTable >= 1 then error("Menu list must be a table with values",2) end
if isNumbered == nil then isNumbered = true end --Setting isNumbered default
titleAlign = alignments[titleAlign] or alignments.center --Default title alignment
textAlign = alignments[textAlign] or alignments.left --Default options alignment
prefixCharacter = prefixCharacter or "["
suffixCharacter = suffixCharacter or "]"
spaceCharacter = spaceCharacter or "."
for i=1, #textTable do
  if type(textTable[i]) ~= "table" then 
    textTable[i] = {text = textTable[i]} --If it is given without key and value pairs
  end
  textTable[i].text = textTable[i].text or textTable[i].value --This allows you to have tables of text, function pairs. So my function returns 1, and you call input[1].func()
  textTable[i].key = textTable[i].key or i
end
local function align(text, alignment) --Used to align text to a certain direction
  if alignment == "left" then return 1 end
  if alignment == "center" then return (x/2)-(#text/2) end
  if alignment == "right" then return x - #text+1 end
  error("Invalid Alignment",3) --Three because is only called by output
end
local function seperateLines(text) --Seperates multi-line text into a table
  if type(text) ~= "string" then error("Seperate Lines expects string, got "..type(text),2) end
  local toRet = {}
  local originalText = text --I do this because it may break the gsub if I modify while iterating
  while true do
    local count = 0
    text = originalText
    if #toRet >= 1 and not text:match("[^ ]") then --If there are no non-space characters, you are done
      toRet[#toRet] = toRet[#toRet]..text:match(" *$") --Get buffer spaces at end
      return toRet, #toRet 
    end 
    table.insert(toRet, "")
    if #toRet == 1 then --We want to add in buffer spaces at the beginning
      toRet[1] = toRet[1]..text:match("^ *")
      count = #toRet[1]
      originalText = originalText:sub(#toRet[1]+1)
    end
    for word in text:gmatch("[^ ]+ *") do --Non space characters with an optional space(s) at the end
      local toBreak
      local found = word:find("\n")--This makes newLines actually work (hopefully)
      if found then
        word = word:sub(1,found-1)
        originalText = originalText:sub(1,found-1)..originalText:sub(found+1) --Cut out the newline
        toBreak = true --If this line should be cut off
      end
      count = count + #word --Counts characters so we don't go over limit
      if count <= x or #word > x then  --The second is for emergencies, if the word is longer than a line, put it here anyways
        toRet[#toRet] = toRet[#toRet]..word
        originalText = originalText:sub(#word+1) --Sub out the beginning
        if toBreak then break end
      else
        break --Go to next line
      end
    end
  end
end

local function output(text,y, alignment, assumeSingle) --My own term.write with more control
  local originalAlignment, printTab, lines = alignment --Setting locals
  if type(text) == "table" then --Assuming this is from seperateLines
    printTab, lines = text, #text
  elseif assumeSingle then --Saves from doing seperateLines on all the menu options
    printTab, lines = {text}, 1
  else
    printTab, lines = seperateLines(text)
  end
  for i=1, lines do
    local x = align(printTab[i], alignment)
    term.setCursorPos(x,y+i-1) ---1 because it will always be at least +1
    term.clearLine()
    term.write(printTab[i])
    --term.write(" Writing to "..tostring(x)..","..tostring(y+i-1).." lines "..tostring(lines)) --Debug
    --os.pullEvent("char")
  end
end

title, titleLines = seperateLines(title)
if description then  --descriptionLines is how many lines the description takes up
  description, descriptionLines = seperateLines(description)
end
local upperLines = descriptionLines + titleLines --The title line, descriptions, plus extra line
if upperLines > y-3 then error("Top takes up too many lines",2) end --So at least two options are on screen
local top, bottom = 1, (y-upperLines) --These two are used to determine what options are on the screen right now (through scroll)
while true do
  while currIndex <= top and top > 1 do --If index is at top, scroll up
    scroll = scroll - 1
    top, bottom = top - 1, bottom - 1
  end
  while currIndex >= bottom and bottom < #textTable do --If at bottom scroll down. Change to > instead of >= to only do on bottom line. Same for above
    scroll = scroll + 1
    top, bottom = top + 1, bottom + 1
  end
  term.clear()
  output(title,1, titleAlign) --Print title
  if descriptionLines >= 1 then --Not an else because we don't want to print nothing
    output(description,titleLines+1, titleAlign)
  end
  for i = 1, math.min(y - upperLines,#textTable) do --The min because may be fewer table entries than the screen is big
    local prefix, suffix = "", "" --Stuff like spaces and numbers
    if isNumbered then prefix = tostring(textTable[i+scroll].key)..spaceCharacter.." " end --Attaches a number to the front
    if i + scroll == currIndex then prefix = prefixCharacter.." "..prefix; suffix = suffix.." "..suffixCharacter  --Puts brackets on the one highlighted
      elseif textAlign == "left" then for i=1, #prefixCharacter+1 do prefix = " "..prefix end --This helps alignment
      elseif textAlign == "right" then for i=1, #suffixCharacter+1 do suffix  = suffix.." " end --Same as above
    end
    local toPrint = prefix..textTable[i+scroll].text..suffix
    if #toPrint > x then term.clear(); term.setCursorPos(1,1); error("Menu item "..tostring(i+scroll).." is longer than one line. Cannot Print",2) end
    output(toPrint, i + upperLines, textAlign, true)
  end
  if type(incrementFunction) ~= "function" then --This allows you to have your own custom logic for how to shift up and down and press enter. 
    incrementFunction = defaultMenuKeyHandler--e.g. You could use redstone on left to increment, right to decrement, front to press enter.
  end
  action = incrementFunction()
  if type(action) == number or tonumber(action) then
    local num = tonumber(action)
    if num <= #textTable and num > 0 then
      currIndex = num
    end
  elseif action == "up" and currIndex > 1 then
    currIndex = currIndex - 1
  elseif action == "down" and currIndex < #textTable then
    currIndex = currIndex + 1
  elseif action == "enter" then
    return textTable[currIndex].text, textTable[currIndex].key, currIndex, textTable[currIndex].value
  end
end
end

function defaultMenuKeyHandler()
  while true do --So it doesn't redraw every time button pressed
    _, key = os.pullEvent("key")
    if key == 200 then return "up"
    elseif key == 208 then return "down"
    elseif key == 28 then return "enter"
    elseif key >= 2 and key <= 11 then return key-1 --This is for quickly selected a menu option
    end
  end
end