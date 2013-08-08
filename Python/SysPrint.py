import pygame

if not pygame.font.get_init(): pygame.font.init()

data = { "font": "Calibri", "size": 20, "color": (0,0,0), "antiAlias": False, "buffer": 5}
currLine, maxLines = 1, 20
fontObj = pygame.font.SysFont(data["font"],data["size"])

def init(font, pageHeight, lines, color = data["color"], antiAlias = data["antiAlias"], buffer = data["buffer"]):
  global data, maxLines, fontObj
  data["font"], data["color"], data["antiAlias"], data["buffer"] = font, color, antiAlias, buffer
  maxLines, data["size"] = lines, int(pageHeight / lines) or 1
  fontObj = pygame.font.SysFont(data["font"],data["size"])

def print(surfObj, toPrint):
  global currLine
  surfObj.blit(fontObj.render(toPrint if isinstance(toPrint,str) else repr(toPrint),data["antiAlias"], data["color"]),(0, (currLine-1) * data["size"] + data["buffer"]))
  currLine = currLine + 1 if currLine < maxLines else 1

def printCenter(surfObj, toPrint, startX = 0):
  pass

def setLine(line = 1):
  pass

