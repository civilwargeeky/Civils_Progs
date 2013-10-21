import pygame
dPrint = print
if not pygame.font.get_init(): pygame.font.init()

data = { "screen": None, "font": "Calibri", "size": 20, "color": (0,0,0), "antiAlias": True, "offsetX" : 0, "offsetY" : 0}
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

def lineGet(): #Returns current line
  return currLine

def init(surfaceObject, lines, **args):
  """The way this is set up, you give it your screen dimensions and the number of lines you want on this screen
  (Optionally a whole bunch of other parameters), and it comes up with a font size for you."""
  for a in data:
    try:
      args[a]
    except KeyError:
      args[a] = data[a]
  global data, maxLines, fontObj
  data["screen"], data["font"], data["color"], data["antiAlias"], data["offsetX"], data["offsetY"] = surfaceObject, args["font"], args["color"], args["antiAlias"], args["offsetX"], args["offsetY"]
  maxLines, data["size"] = lines, (int((surfaceObject.get_size()[1]-data["offsetY"]) / lines) or 1) #Height is 1
  dPrint(data["font"])
  dPrint(data["size"])
  fontObj = pygame.font.SysFont(data["font"], data["size"])

def specialWrite(toPrint, align = "left", antiAlias = data["antiAlias"], color = data["color"] ):
  if align == "left": 
    data["screen"].blit(fontObj.render(toPrint, data["antiAlias"], data["color"]),(data["offsetX"], (currLine-1) * data["size"] + data["offsetY"]))
  elif align == "center":
    pass #Look at your lua menu api if you forget how this works...
  elif align == "right":
    pass
    
def specialPrint(*args): #Just a wrapper for specialWrite
  specialWrite(*args)
  lineInc()
  
def write(toPrint, align = "left"):
  specialWrite(toPrint, align, data["antiAlias"], data["color"])
  
def print(toPrint, align = "left"):
  specialWrite(toPrint, align, data["antiAlias"], data["color"])
  lineInc()
