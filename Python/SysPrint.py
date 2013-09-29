"""NOTE: THE AMOUNT OF LINES CALCULATION IS OFF!!! WITH 10 LINES, IT ONLY HAS 7.5!!! FIX IT!!!"""


import pygame
dPrint = print
if not pygame.font.get_init(): pygame.font.init()

data = { "screen": None, "font": "Calibri", "size": 20, "color": (0,0,0), "antiAlias": True, "buffer": 5}
openLines = []
currLine, maxLines = 1, 20
fontObj = pygame.font.SysFont(data["font"],data["size"])

def lineSet(line=1): #Sets the current line position
  global currLine #What I'm changing :)
  if 1<= line <= maxLines:
    currLine = line
    return True
  return False

def lineInc(num=1): #Changes the current line position up
  if abs(num) < maxLines:
    lineSet(currLine+num) or lineSet()
    return True
  return False

def init(surfaceObject, lines, font = data["font"], color = data["color"], antiAlias = data["antiAlias"], buffer = data["buffer"]):
  """The way this is set up, you give it your screen dimensions and the number of lines you want on this screen
  (Optionally a whole bunch of other parameters), and it comes up with a font size for you."""
  global data, maxLines, fontObj
  data["screen"], data["font"], data["color"], data["antiAlias"], data["buffer"] = surfaceObject, font, color, antiAlias, buffer
  maxLines, data["size"] = lines, (int(surfaceObject.get_size()[0] / lines) or 1) #Verify that 0 is height and not 1
  dPrint(data["font"])
  dPrint(data["size"])
  fontObj = pygame.font.SysFont(data["font"], data["size"])

def print(toPrint, flag = None):
  data["screen"].blit(fontObj.render(toPrint, data["antiAlias"], data["color"]),(0, (currLine-1) * data["size"] + data["buffer"]))
  lineInc()
