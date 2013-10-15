import pygame, time
import SysPrint as sysPrint
pygame.init()
resX,resY = 640, 480
screen = pygame.display.set_mode((resX,resY))

sysPrint.init(screen,10, antiAlias = True)

while True:
  #sysPrint.lineSet()
  screen.fill((255,255,255))
  sysPrint.print("Hello!")
  pygame.display.update()
  time.sleep(1)
