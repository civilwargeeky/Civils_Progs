--Menu API made by Civilwargeeky
--Version 1.0.2

--Window Class
local window = {}
window.setDim = function(obj, pt1, pt2) 
  obj.pt1 = {math.min(pt1[1],pt2[1]), math.min(pt1[2], pt2[2]) } --This is top left point
  obj.pt2 = {math.max(pt1[1],pt2[1]), math.max(pt1[2], pt2[2]) } --This is bottom right point
  
  obj.xDim = obj.pt2[1]-obj.pt1[1]
  obj.yDim = obj.pt2[2]-obj.pt1[2]
  
  if obj.x > obj.xDim then obj.x = obj.xDim end
  if obj.y > obj.yDim then obj.y = obj.yDim end
  obj:setCursorPos(obj.x, obj.y)

end
window.write = function(text) --I don't even care about multi-line writing
  self.term.write(text:sub(1,self.xDim-self.x+1))
end
window.setCursorPos = function(self, x, y)
  self.term.setCursorPos(self.pt1[1]+x, self.pt1[2]+y)
  self.x, self.y = x, y
  return self
end
window.getCursorPos = function(self)
  return self.x, self.y
end
window.clearLine = function(self)
  self.setCursorPos(1, self.y)
  local var = ""
  for i=1, self.xDim do var = var.." " end
  self.term.write(var)
end
window.clear = function(self)
  for i=1, self.y do
    self.setCursorPos(1,i)
    self:clearLine()
  end
end

window.new = function(term, pt1, pt2) --Expects two {x, y}
  local toRet = {}
  setmetatable(toRet, {__index = function(self, index) return window[index] or self.term[index] end}) --So we can treat the objects like a window
  toRet.isCivilWindow = true --So I can make things if I need
  toRet.term = term --Could be term, or a monitor or something
  toRet.x, toRet.y = 1, 1
  toRet:setDim(pt1, pt2)
  return toRet
  
end

--Text Utilities
function titleize(text)
  local x = term.getSize()
  if #text+2 > x then return text:upper() end
  text = " "..string.upper(text).." "
  for i=1, math.floor((x-#text)/2) do
    text = "="..text.."="
  end
  return text
end
function align(text, alignment, x) --Used to align text to a certain direction
  if alignment == "left" then return 1 end
  if alignment == "center" then return (x/2)-(#text/2) end
  if alignment == "right" then return x - #text+1 end
  error("Invalid Alignment",3) --Three because is only called by output
end

function makeColoredText(text, textColor, backgroundColor)
  return {text or "", textColor = textColor, backgroundColor = backgroundColor, isText = true}
end

function makeText(...)
  local args = {...}
  local toWrite = ""
  for a, b in ipairs(args) do
    toWrite = toWrite..tostring(b)
  end
  return makeColoredText(toWrite)
end


--Table Preparation Utilities
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
      
function prepareTable(tab) --This takes a numerically or key-value pair table and produces a text table
  local toRet = {}
  for a,b in pairs(tab) do
    table.insert(toRet, {key = a, value = makeText(b)})
  end
  return toRet
end

function separateLines(text, x)
  --This sets toRet to text if it is a makeText object, otherwise it is a string or non-usable.
  local toRet = text.isText and text or (type(text) == "string" and {text}) or error("seperateLines expected a makeTable or string, got "..type(text),2)
  
  if text:match("\n") then --We can't handle newlines inside this, so we'll split it up and do recursion!
    local pos = text:find("\n") --Get where the newline is
    local before, after = separateLines(text:sub(1,pos-1), x), separateLines(text:sub(pos+1), x) --Then run the function on the before section (with no newlines), and the after section (which may be recursive)
    toRet = before
    for a, b in ipairs(after) do
      table.insert(toRet, b)
    end
  end
    
  local i = #toRet
  while #(toRet[i]) > x do --Current index is the "working line" that may or may not be longer than necessary
    local curr = toRet[i]
    if curr:sub(x+1,x+1):match("%s") then --This is a special case: If the last part is a space, the line isn't separated there, so we'll do it explicitly.
      toRet[i] = curr:sub(1,x):gsub("%s+$","") --The gsub removes trailing spaces
      local _, cutEnd = curr:find("%s+",x+1) --This will get all spaces starting at end of wanted line
      toRet[i+1] = curr:sub(cutEnd+1) --This returns all text starting after end of space
    else --Otherwise, we need to split at internal space or word
      local cutString = curr:sub(1,x)..""
      local cutStart, sneakyEnd = cutString:find("%s+%S-$") --Apparently captures don't work in string.find. I'll just find the length of a substring *sigh*
      local cutEnd
      if cutStart then  --This just gets the number of spaces at the end of the line. Could be multiple
        cutEnd = cutStart + #(cutString:sub(cutStart, sneakyEnd):match("%s+")) - 1 --I don't know if sneakyEnd is necessary, it should always be end of string
      end
      
      if cutStart or math.huge < x then --If there is a whitespace we can split at
        toRet[i] = curr:sub(1, cutStart-1)..""
        toRet[i+1] = curr:sub(cutEnd+1)..""
      else --There is no whitespace to split at
        toRet[i] = curr:sub(1,x)
        toRet[i+1] = curr:sub(x+1)
      end
    end
    i = i+1
  end
  
  return toRet, #toRet
end

function menu(title, description, textTable, options, incrementFunction, term, x, y)
  --in text table, program displays the element.text, and returns the .text, .key, and .value
  --options table contains [isNumbered, titleAlign, textAlign, prefixCharacter, suffixCharacter, spaceCharacter]
  --term table contains {term, x, y} or a valid window object
  --Initialization
  if not term.isCivilWindow then term = window.new(term, x, y) end
  local x, y = term.getSize() --Screen size
  local currIndex, scroll = 1, 0 --currIndex is the item from the table it is on, scroll is how many down it should go.
  local titleLines, descriptionLines = 0,0 --How many lines the title and description take up
  local alignments = { left = "left", center = "center", right = "right" } --Used for checking if alignment is valid
  
  --Checking for all required parts
  if not (title and textTable) then error("Requires title and menu list",2) end
  if not type(textTable) == "table" and #textTable >= 1 then error("Menu list must be a table with values",2) end
  local defaultOptions = {isNumbered = true, titleAlign = alignments.center, textAlign = alignments.left, prefixCharacter = "[", suffixCharacter = "]", spaceCharacter = "."}
  options = options or {}
  setmetatable(options, {__index = defaultOptions}) --So we have a default here
  
  textTable = prepareTable(textTable)
  
  --Defining local functions
  local function output(text,y, alignment, assumeSingle) --My own term.write with more control
    local originalAlignment, printTab, lines = alignment --Setting locals
    if type(text) == "table" then --Assuming this is from separateLines
      printTab, lines = text, #text
    elseif assumeSingle then --Saves from doing separateLines on all the menu options
      printTab, lines = {text}, 1
    else
      printTab, lines = separateLines(text)
    end
    for i=1, lines do
      local x = align(printTab[i], alignment, x) --Note inside is non-local x
      term:setCursorPos(x,y+i-1) ---1 because it will always be at least +1
      term:clearLine()
      term:write(printTab[i])
      --term.write(" Writing to "..tostring(x)..","..tostring(y+i-1).." lines "..tostring(lines)) --Debug
      --os.pullEvent("char")
    end
  end

  --Getting all initializations done
  title, titleLines = separateLines(title)
  if description then  --descriptionLines is how many lines the description takes up
    description, descriptionLines = separateLines(description)
  end
  local upperLines = descriptionLines + titleLines --The title line, descriptions, plus extra line
  if upperLines > y-3 then error("Top takes up too many lines",2) end --So at least two options are on screen
  local top, bottom = 1, (y-upperLines) --These two are used to determine what options are on the screen right now (through scroll)
  
  --Main Loop
  while true do
    while currIndex <= top and top > 1 do --If index is at top, scroll up
      scroll = scroll - 1
      top, bottom = top - 1, bottom - 1
    end
    while currIndex >= bottom and bottom < #textTable do --If at bottom scroll down. Change to > instead of >= to only do on bottom line. Same for above
      scroll = scroll + 1
      top, bottom = top + 1, bottom + 1
    end
    term:clear()
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
      if #toPrint > x then term:clear(); term:setCursorPos(1,1); error("Menu item "..tostring(i+scroll).." is longer than one line. Cannot Print",2) end
      output(toPrint, i + upperLines, textAlign, true)
    end
    
    --Handle events
    if type(incrementFunction) ~= "function" then --This allows you to have your own custom logic for how to shift up and down and press enter. 
      incrementFunction = defaultMenuKeyHandler--e.g. You could use redstone on left to increment, right to decrement, front to press enter.
    end
    local action = incrementFunction(currIndex, #textTable) --Function handles calling os.pullEvent()
    if tonumber(action) then
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

function defaultMenuKeyHandler(index, maxIndex) --This handles events
  local event, key = os.pullEvent("key")
  if event == "key" then
    if key == 200 then --Up arrow
      if index == 1 then return maxIndex end --Go to bottom if at top
      return "up"
    elseif key == 208 then --Down Arrow
      if index == maxIndex then return 1 end --Go to top if at bottom
      return "down"
    elseif key == 28 then return "enter"
    elseif key >= 2 and key <= 11 then return key-1 --This is for quickly selecting a menu option
    end
  end
end