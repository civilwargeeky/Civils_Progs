"""
I think that there should be different "levels" to the coding. Like we would have different modules loaded to do all the "backend" stuff
like keyhandling, event triggering, (although not backend...) graphics. I'm not really sure, but I think it would be messy to include
all of our graphics rendering and image loading code mixed in with our main game code. I will try and research what other coders have done
in the past to see if this is common.

Just a guess at how loading will go:
1. Load menu
2. Load level
3. Load player and world
4. Begin simulation

Also, Semper if you read this, I'm going to tell you right now, unless you have an amazing 3D programming artist planning on joining the team,
there is no way it will be 3D. 2D Graphics is hard enough already.
"""

import AllTheThings

loadMenu()

if waitForKeyPress() == "UpArrow":
  MenuUp()
elif (^That^) == "DownArrow":
  MenuDown()
elif (^^That^^) == "Enter":
  menuItem[Position]()
  
world = load(currentLevel)

world.placePlayer(posTuple)

while True:

  graphics.doStuff()
  sounds.play()
  keys.handleEventsBasedOnContext()
  moveEntitiesOrTickGameStuffLikeMovement()
  
  handleQuitStuffOrEscapeMenu()


