function titleize(text)
local x = term.getSize()
if #text+2 > x then return text end
text = " "..string.upper(text).." "
for i=1, math.floor((x-#text)/2) do
  text = "="..text.."="
end
return text
end

function menu(title, description, textTable, isNumbered, titleAlign, textAlign, prefixCharacter, suffixCharacter, incrementFunction)
local x, y = term.getSize() --Screen size
local alignments = { left = "left", center = "center", right = "right" } --Used for checking if alignment is valid
if not (title and textTable) then error("Requires title and menu list",2) end
if not type(textTable) == "table" and #textTable >= 1 then error("Menu list must be a table with values",2) end
if #title > x then error("Title too long",2) end --If the title is longer than a line, program messes up
if isNumbered == nil then isNumbered = true end --Setting isNumbered default
titleAlign = alignments[titleAlign] or alignments.center --Default title alignment
textAlign = alignments[textAlign] or alignments.left --Default options alignment
prefixCharacter = prefixCharacter or "["
suffixCharacter = suffixCharacter or "]"
if type(textTable[1]) == "table" then --This allows you to have tables of text, function pairs. So my function returns 1, and you call input[1].func()
  for i=1, #textTable do
    textTable[i] = textTable[i].text
  end
end
local function align(text, alignment) --Used to align text to a certain direction
  if alignment == "left" then return 1 end
  if alignment == "center" then return (x/2)-(#text/2) end
  if alignment == "right" then return x - #text end
  error("Invalid Alignment",3) --Three because is only called by output
end
local function output(text,y, alignment) --My own term.write with more control
  local x = align(text, alignment)
  term.setCursorPos(x,y)
  term.clearLine()
  return term.write(text)
end
local currIndex, descriptionLines, scroll = 1, 0, 0 --currIndex is the item from the table it is on, scroll is how many down it should go.
if description then  --descriptionLines is how many lines the description takes up
  descriptionLines = print(description); term.clear(); term.setCursorPos(1,1)--This is my way of figuring out how many lines the description is
end
if descriptionLines > y-4 then error("Description takes up too many lines",2) end --So at least two options are on screen
local titleLines = descriptionLines + 2 --The title line, descriptions, plus extra line
local top, bottom = 1, (y-titleLines) --These two are used to determine what options are on the screen right now (through scroll)
while true do
  if currIndex <= top and top > 1 then --If index is at top, scroll up
    scroll = scroll - 1
    top, bottom = top - 1, bottom - 1
  end
  if currIndex >= bottom and bottom < #textTable then --If at bottom scroll down. Change to > instead of >= to only do on bottom line. Same for above
    scroll = scroll + 1
    top, bottom = top + 1, bottom + 1
  end
  term.clear()
  output(title,1, titleAlign) --Print title
  if descriptionLines == 1 then --Not an else because we don't want to print nothing
    output(description,2, titleAlign)
  elseif descriptionLines > 1 then
    term.setCursorPos(1,2); print(description)
  end
  for i = 1, math.min(y - titleLines,#textTable) do --The min because may be fewer table entries than the screen is big
    local prefix, suffix = "", "" --Stuff like spaces and numbers
    if isNumbered then prefix = tostring(i+scroll)..". " end --Attaches a number to the front
    if i + scroll == currIndex then prefix = prefixCharacter.." "..prefix; suffix = suffix.." "..suffixCharacter  --Puts brackets on the one highlighted
      elseif textAlign == "left" then for i=1, #prefixCharacter+1 do prefix = " "..prefix end --This helps alignment
      elseif textAlign == "right" then for i=1, #suffixCharacter+1 do suffix  = suffix.." " end --Same as above
    end
    if not (#(prefix..textTable[i+scroll]..suffix) <= x) then term.clear(); term.setCursorPos(1,1); error("Menu item "..tostring(i+scroll).." is longer than one line. Cannot Print",2) end
    output(prefix..textTable[i+scroll]..suffix, i + titleLines, textAlign)
  end
  if type(incrementFunction) ~= "function" then --This allows you to have your own custom logic for how to shift up and down and press enter. 
    incrementFunction = function()                --e.g. You could use redstone on left to increment, right to decrement, front to press enter.
      _, key = os.pullEvent("key")
      if key == 200 then return "up"
        elseif key == 208 then return "down"
        elseif key == 28 then return "enter"
      end
    end
  end
  action = incrementFunction()
  if action == "up" and currIndex > 1 then
    currIndex = currIndex - 1
  end
  if action == "down" and currIndex < #textTable then
    currIndex = currIndex + 1
  end
  if action == "enter" then
    return currIndex, textTable[currIndex]
  end
end
end

--The following is some silly testing
list = {"Apples", "Oranges", "Bananas", "Avocadoes",'a','b','c','d','g','u','t','g','y'}
function silly() --For messing with the input function
_, key = os.pullEvent("key")
a = {"up","down"}
if key ~= 28 then
  return a[math.random(1,2)]
end
return "enter"
end

a, b = menu(titleize("Fruit and Letter picker"), "What will you pick today?", list, false, nil, "left", "-->","<--",nil)
term.clear(); term.setCursorPos(1,1)
print("You picked \""..list[a].."\"!!!")
sleep(2)
a,b = menu("Did you pick "..b.."?","Tell the truth now...",{"Yes, I picked "..b,"no"},false,left,center)
term.clear(); term.setCursorPos(1,1)
if b == "no" then print("liar!") else print("Good!") end