--Fun city game. Maybe kind of like AOE or Civ... a bit
--Basic premise: You have food, stone, gold, and population
--[[ You have several resources:
  Food: Used and produced each turn. Food surplus increases population
  Stone: Used to build buildings
  Gold: Used to pay army and bribe nations and upkeep buildings
  Population: Each member is assigned to a job. Must have:
    Food: People make food
    Construction: Build/Repair Buildings
    Stone Miner: Get stone
    Gold Miner: Get gold
    Police: Curb large populations
    Standing Army: Defend Nation from random attacks
    Special Buildings: A smith would improve yields, armorer improve battles. etc.
After a certain population, crime will cause certain number of deaths each turn >= population growth. Will have to build police station (lots of gold to upkeep)
Different buildings can be built, each with different tiers. Different tiers will require large amounts of stone and gold, and lots of gold in upkeep
Buildings will provide different bonuses, and some will be prerequisites for things.
  Town Hall: Upgrading this allows your town to have a larger population.
  Farms: Allow more people to work farms
  Stone Mine: Allow more people to work stone mines
  Gold Mine: Same
  Police Station: Allow assignment of police to protect citizens
  Barracks: Allow larger armies
  Smith: Better tools allow better yields at farms and mines (maybe 1 = farms, 2 = stone, 3 = gold)
  Armorer: Soldiers are more effective in combat

I'm thinkning that you will also be able to attack neighboring towns to take gold. Distance will affect soldiers killed in route to battle
Random events will destroy building in the city or reduce yields or kill people.
  Volcano, Flood, Drought, Locusts, Mine Collapse, Cave Bears, Neighbors attacking, prince steals gold
  If crime high:
    Poison, Arson, Murder, Greed (burns gold)

To win, get a certain amount of gold or conquer all neighbors. Neighbors will get significantly better based on turns, and attacking them will set back their production to a differnet turn.
You can lose if your population is zero or you are bankrupt.

All data will be stored in a save file when you hit "save game"
Each other city will get "simple" resource increase of gold and army based on random "econonmy" and "army" modifiers and turn. ]]

menu = {}
os.load(menu,"menuAPI.lua")

buildings = {} --Format buildingName = {level = x, maxLevel, screenName, popAssigned, levels = { [1] = {costStone, costGold, maxPop, upkeep}}, description? }
function addBuilding(name, screenName, maxLevel, levels description, currLevel)
  buildings[name] = {level = currLevel or 0, popAssigned = 0, screenName = screenName, maxLevel = maxLevel, levels = levels, description = description or ""}
  return buildings[name] ~= nil
end
--addBuilding("pizzaStore", "Pizza Store", 1, {{stone = 5, gold = 99, maxPop = 5, upkeep = 5}}, "A pizza Parlor")
function setModifiers(name, base, expanded, levelMod)
  buildings[name].levelModifier = levelMod --This adjusts how much percent upgrading has on its effects
  buildings[name].modifiers = {base = {}, expanded = {}}
  buildings[name].modifiers.base = {gold = base.gold or 0, stone = base.stone or 0, food = base.food or 0}
  buildings[name].modifiers.expanded = {gold = expanded.gold or 0, stone = expanded.stone or 0, food = expanded.food or 0}
  return buildings[name].modifiers ~= nil
end
--setModifiers("pizzaStore", {gold = 2, food = 5, stone = 0}, {gold = 0.05, food = 0.1, stone = 0}, 0.15)