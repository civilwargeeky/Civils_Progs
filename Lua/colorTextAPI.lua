--Colored Text API by Civilwargeeky
--Version 0.2

--[[Colors: white orange magenta lightBlue yellow lime pinkgray lightGray cyan purple blue brown green red black]] 

local codes = {}
for a, b in pairs(colors) do --This just makes a list of the colors to parse.
  if type(b) == "number" then --I could just write them out, but where is the fun in that?
    if a:sub(1,5) == "light" then
      codes[a:sub(1,1)..string.lower(a:sub(6,6))] = b
    elseif a == "blue" then
      codes.db = b
    else
      codes[a:sub(1,2)] = b
    end
  end
end

function encode(input) --Function to make colored strings
  local currColor, toRet = codes.bl, {}
  toRet.isColorText = true
  for a, b in function() return input:find("%%%a%a") end do
    local color = input:sub(a+1,b)..""
    if codes[color] then
      input =  input:sub(0,a-1)..input:sub(b+1,#input)
      table.insert(toRet, {color = codes[color], start = a })
    end
  end
  table.insert(toRet, 1, {color = codes.wh, start = 0})
  toRet.text = input
  local meta = {}
  meta.__call = function(tab) return tab.text end
  meta.__tostring = function(tab) return tab.text end
  meta.__len = function(tab) return #tab.text end
  setmetatable(toRet,meta)
  return toRet
end

local oldWrite = write
write = function(input)
  if input.isColorText and term.isColor() then
    local currPos = 0
    for i=1, #input do
      startPos, endPos = input[i].start, (input[i+1] or {start = #input.text+1}).start-1
      term.setTextColor(input[i].color)
      oldWrite(input.text:sub(startPos,endPos))
    end
    term.setTextColor(codes.wh)
    return true
  else
    return oldWrite(input)
  end
end

function writeCode(input)
  return write(encode(input))
end

local oldPrint = print
print = function(input)
return write(input), write("\n")
end