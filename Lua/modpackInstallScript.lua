--Expected install
--[[
resources folder
  mods folder
    mods
      rei_minimap
        option.txt
        keyconfig.txt
  config folder
    configs
  versions folder
    1.6.4 folder that goes in minecraft/versions/1.6.4
  launcher_profiles.json (blank one)
  forgeinstall.jar
  options.txt
  minecraft.exe(uneeded)
  modpackversion.txt
    Mod Pack Name (no spaces)
    Mod Pack Version
lua folder
  lua.exe and lua52.dll
  icon file
  shortcut.exe
  switcher, install, and API
]]
local option = false --Whether or not to ask to install minecraft
dofile("lua\\modPackFileAPI.lua") --Load API


local function prompt(input)
  local fun = "_____________________________"
  print(fun)
  print()
  print(input)
  print("y/n? ")
  local val = io.read():lower():sub(1,1) ~= "n" --This gets the input, and checks if first letter is y
  print(fun)
  return val
end
local function status(input)
  print("-----",input:upper())
end

os.execute("color B4") --Red on blue
status("starting")
local base = getRet("cd")
local current = base:add("resources") --Current parent directory. It is above the lua folder because this is called from base folder
local minecraft = getRet("echo %appdata%"):add(".minecraft") --Minecraft directory
local temp = current:add("temporary")

if not prompt("This installer will delete your mods and configs for minecraft and replace them.\nContinue?") then
  error("Please Close Me :D",0)
end

if not exists(minecraft) then
  print("Wow, you haven't even played minecraft yet. \nLet me help you with that")
  mkDir(minecraft)
  local json = "launcher_profiles.json" --A blank json so forge can install
  if not exists(minecraft:add(json)) then copyFile(current:add(json), minecraft) end
  option = true
end


--Config Area
local versionFileName = "modpackversion.txt"
local versionsFile = current:add(versionFileName)
local modpacks = minecraft:add("modpacks")
local switcherName = "runSwitcher.bat"
local switcherShortcutName = "Mod Switcher.lnk"
local desktop = getRet("echo "..("%userprofile%"):sanitize()):add("Desktop")


if not exists(modpacks) then
  status("Making Mod Pack Folder")
  mkDir(modpacks)
end
local pack, version = getNameAndVersion(versionsFile)
local existingVersion = "0"
if not exists(modpacks:add(pack)) then
  status("Adding folder for "..pack)
  mkDir(modpacks:add(pack))
else
  _, existingVersion = getNameAndVersion(modpacks:add(pack):add(versionFileName))
  status("Existing Version: "..existingVersion)
end
status("Current Version: "..version)

local doReplace = false
local versionTable, existingVersionTable = splitVersion(version), splitVersion(existingVersion)
doReplace = compareVersions( splitVersion(version), splitVersion(existingVersion))--Goes through and checks if version is bigger than the existing one

if doReplace then --If the current version is newer than installed
  status("Update check passed, updating mods")
  local rei = "rei_minimap"
  local minimap = minecraft:add("config"):add(rei)
  if exists(minimap) then
    status("backing up minimap points")
    mkDir(temp)
    copyDir(minimap, temp)
  end
  if prompt("Replace keyBindings and settings? This is helpful if the modpack is new on this computer") then --The options.txt file
    status("removing existing options")
    rmFile(minecraft:add("options.txt"))
    status("copying new options")
    copyFile(current:add("options.txt"), minecraft)
    if exists(minimap) then
      status("removing minimap options")
      rmFile(temp:add(rei):add("option.txt"))
      rmFile(temp:add(rei):add("keyconfig.txt"))
    end
  end
  status("Removing your mods and configs")
  rmDir(minecraft:add("mods"))
  rmDir(minecraft:add("config"))

  status("Copying configs and mods")
  copyDir(current:add("config"), minecraft)
  copyDir(current:add("mods"), minecraft)

  if exists(temp) then
    status("Replacing minimap points")
    copyDir(temp:add(rei), minecraft:add("mods"))
    rmDir(temp)
  end
  
  status("Copying configs and mods to Mod Packs Folder")
  rmDir(modpacks:add(pack)) --Get rid of old pack possibility
  mkDir(modpacks:add(pack))
  copyDir(current:add("config"), modpacks:add(pack))
  copyDir(current:add("mods"), modpacks:add(pack))
  copyFile(current:add(versionFileName), modpacks:add(pack))
  
else
  print("You have a more recent pack than this one, or you have already installed.\nNo need to change anything :)")
end
  
--Outside of regular install because this installer is also convenient for updating forge.
status("Checking installed forge versions") --This checks if they have played current version before
for a in scan(current) do --This checks if the proper forge version is installed
  if a:match(".+installer%.jar$") then --This finds the forge installer jar in the current folder. 'a' is the filename
    local mcVersion, forgeVersion = a:match("forge%-(.+)%-(.+)%-installer%.jar$") --Two captures from the installer jar's name
    if not exists(minecraft:add("versions"):add(mcVersion))then --The vanilla versions files, this must exist before forge can install
      status(mcVersion.." Versions Files not found, adding")
      if not exists(current:add("versions"):add(mcVersion)) then --Pack maker didn't make pack properly
        status("Pack Maker screwed up, no versions files")
        status("Please ask them to not screw up in the future")
        status("Cannot continue :(  ")
        error("Expected "..mcVersion.." versions folder does not exist in install",0)
      end
      copyDir(current:add("versions"):add(mcVersion), minecraft:add("versions"))
    else
      option = false --They already have minecraft
    end
    local forgeVersionPath = minecraft:add("versions"):add(mcVersion.."-Forge"..forgeVersion)
    if exists(forgeVersionPath) and countFiles(forgeVersionPath) > 0 then --Checking if forge version files exist inside folder (if fail, forge makes folder but not files)
      status("forge already loaded, good to go")
    else
      status("running forge: Please press OK When a window appears onscreen (it may take a bit)")
      os.execute(current:add(a):sanitize())
      break
    end
  end
end

status("all done! :D")

if option and prompt("Place Minecraft.exe on your desktop? ") then
  copyFile(current:add("minecraft.exe"), getRet("echo %userprofile%"):add("desktop"))
end

if not (exists(minecraft:add("lua"):add(switcherName)) and exists(desktop:add(switcherShortcutName)) )  and prompt("Would you like to install my mod pack switcher?") then
  copyDir(base:add("lua"), minecraft)
  local file = io.open(minecraft:add("lua"):add(switcherName), "w") --Maker our own bat file for running
  file:write("@echo off\nlua.exe modpackSwitcher.lua\npause") --The running the program part of the program
  file:close()
  status("Making Desktop Shortcut")
  os.execute(base:add("lua"):add("shortcut.exe").." /F:"..desktop:add(switcherShortcutName):sanitize().. --Adding a shortcut. f is link name
  " /A:C /T:"..minecraft:add("lua"):add(switcherName):sanitize().. --A:C I think is type of link, T is destination
    " /W:"..minecraft:add("lua"):sanitize().. --W is working directory
    " /I:"..minecraft:add("lua"):add("cookie.ico"):sanitize()) --I is icon file
  status("Removing extra files")
  local lua = minecraft:add("lua")
  rmFile(lua:add("Shortcut.exe"))
  rmFile(lua:add("modpackInstallScript.lua"))
end
