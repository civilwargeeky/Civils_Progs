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
  maxLines, data["size"] = lines, (int(surfaceObject.get_size()[1] / lines) or 1) #Height is 1
  dPrint(data["font"])
  dPrint(data["size"])
  fontObj = pygame.font.SysFont(data["font"], data["size"])

  #Maybe have like "special print" that allows you to change parameters
def print(toPrint, align = "left"):
  if align == "left": 
    data["screen"].blit(fontObj.render(toPrint, data["antiAlias"], data["color"]),(0, (currLine-1) * data["size"] + data["buffer"]))
  elif align == "center":
    pass #Look at your lua menu api if you forget how this works...
  elif align == "right":
    pass
  lineInc()
