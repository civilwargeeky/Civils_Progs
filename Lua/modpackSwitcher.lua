--This will read all the modpacks that you have installed (in my folder :D ) and will let you switch between them
--What this does: Generate a list of all the modpacks installed, presents the list to the user, moves the modpack files around (makes backup of rei's minimap files between switches)


dofile("modpackFileAPI.lua") --Needs filesystem API

local minecraft = getRet("echo %appdata%"):add(".minecraft")
local modpacks = minecraft:add("modpacks")
if not minecraft:match("%.minecraft") then error("Not in minecraft folder, in "..minecraft) end
if not exists(modpacks) then error("Mod Packs Folder not found") end


local function getFoldersTable(dir)
  local toRet = {}
  for a in scan(dir, "/ad") do --Only want directories
    table.insert(toRet, a)
  end
  return toRet
end

os.execute("color A6") --Mild dark green on bright green
local x, y = 79, 24 --characters
local modsFolders = getFoldersTable(modpacks)


local function titleize(text, char)
  char = char or "="
  text = text:upper()
  for i=1, math.floor((x-#text)/(2*#char)) do
    text = char..text..char
  end
  return text
end
local function prompt(input)
  print(input.." y/n")
  return io.read():lower():sub(1,1) ~= "n"
end

local packNumber
repeat
  os.execute("cls")
  print(titleize(""))
  print(titleize("Welcome to Daniel's Mod Switcher!"))
  print(titleize(""))
  print("")
  print("Please choose a Mod Pack")
  print(titleize("","-"))
  for a,b in pairs(modsFolders) do
    modsFolders[a] = ({getNameAndVersion(modpacks:add(modsFolders[a]):add("modpackversion.txt"))})
    b = modsFolders[a]
    local name = (b[3] or b[1]).." v"..b[2]
    local toPrint = string.format("%2d",a).."."
    for i=1,x-#name-#toPrint do
      toPrint = toPrint.." "
    end
    toPrint = toPrint..name
    print(toPrint)
  end
  print(titleize("","-"))

  print("Which Index Number would you like?")
  if packNumber then print(tostring(packNumber).." was not a valid choice") end
  packNumber = tonumber(io.read())
until modsFolders[packNumber]


local pack = modsFolders[packNumber]
os.execute("cls")
print(titleize(""))
print(titleize("You have selected "..(pack[3] or pack[1])))
local numberMods = 0
for a in scan(modpacks:add(pack[1]):add("mods"), "/s /a:-d") do
  numberMods = numberMods + 1
end
print(titleize("This pack has "..tostring(numberMods).." mods in it"))
print(titleize("Now copying the mods and configs"))
print(titleize(""))
print("")
print("")

local temp = minecraft:add("temp") --This is for saving minimap points
local minimap = minecraft:add("mods"):add("rei_minimap")
if exists(minimap) then
  mkDir(temp)
  copyDir(minimap, temp)
end

rmDir(minecraft:add("mods"))
rmDir(minecraft:add("config"))

copyDir(modpacks:add(pack[1]):add("mods"), minecraft)
copyDir(modpacks:add(pack[1]):add("config"), minecraft)
  

if exists(temp) then
  copyDir(temp:add("rei_minimap"), minecraft:add("mods"))
  rmDir(temp)
end

print("")
print("Done :D")
print("Your mods have been loaded")

local desktop = getRet("echo %userprofile%"):add("desktop")
for a in scan(desktop) do
  if a:match("[Mm]inecraft.exe") then
    print("Minecraft found! Running")
    os.execute(desktop:add(a))
  end
end

