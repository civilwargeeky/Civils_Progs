import pygame
dPrint = print
if not pygame.font.get_init(): pygame.font.init()

defaults = { "screen": None, "font": "Calibri", "size": 20, "color": (0,0,0), "antiAlias": True, "offsetX" : 0, "offsetY" : 0, "lines" : 5, "align" : "left"}
openLines = []
currLine, maxLines = 1, 20

def init(surfaceObject, lines, **args): #This is used to set defaults
  """The way this is set up, you give it your screen dimensions and the number of lines you want on this screen
  (Optionally a whole bunch of other parameters), and it comes up with a font size for you."""
  global defaults
  for a in defaults:
    try:
      args[a]
    except KeyError:
      args[a] = defaults[a]
    defaults[a] = args[a]
  defaults["screen"] = surfaceObject
  defaults["size"] = (int((surfaceObject.get_size()[1]-defaults["offsetY"]) / lines) or 1) #Height is 1

class text(object):
  def __init__(self, surface, **args):
    self.data = {}
    self.currLine = 1
    for a in defaults:
      try:
        args[a] #The value of this default exists in the given arguments
      except KeyError:
        args[a] = defaults[a] #Give this value a default one
      self.data[a] = args[a] #Add it to the personal data table
    self.data["screen"] = surface
    self.data["size"] = (int((self.data["screen"].get_size()[1]-(self.data["offsetY"] * 2)) / self.data["lines"]) or 1) #Height is index 1
    self.fontObj = pygame.font.SysFont(self.data["font"], self.data["size"]) #Set up render object

  def lineSet(self, line=1): #Sets the current line position
    if 1<= line <= self.data["lines"]:
      self.currLine = line
      return True
    return False

  def lineInc(self, num=1): #Changes the current line position up
    if abs(num) < self.data["lines"]:
      self.lineSet(self.currLine+num) or self.lineSet()
      return True
    return False

  def lineGet(self): #Returns current line
    return self.currLine

  def makeSurface(self, toPrint, **args): #This is the important function that makes text surfaces
    return self.fontObj.render(toPrint, args["antiAlias"],  args["color"])
  
  def specialWrite(self, toPrint, **args): #Main backend function
    for a in ["align", "antiAlias","color"]: #This is my solution to "can't see self in params"
      try:
        args[a]
      except KeyError:
        args[a] = self.data[a]
    x, y = None, None
    if args["align"] == "left":
      x, y = self.data["offsetX"], (self.currLine-1) * self.data["size"] + self.data["offsetY"]
      self.data["screen"].blit(self.makeSurface(toPrint, **args),(self.data["offsetX"], (self.currLine-1) * self.data["size"] + self.data["offsetY"]))
    elif args["align"] == "center":
      pass #Look at your lua menu api if you forget how this works...
    elif args["align"] == "right":
      pass
    return x,y
      
  def specialPrint(self,**args): #Just a wrapper for specialWrite
    return self.specialWrite(**args), self.lineInc()
    
  def write(self, toPrint, align = "left"):
    return self.specialWrite(toPrint, align = align, antiAlias = self.data["antiAlias"], color = self.data["color"])
    
  def print(self, toPrint, align = "left"):
    return self.specialWrite(toPrint, align = align, antiAlias = self.data["antiAlias"], color = self.data["color"]), self.lineInc()