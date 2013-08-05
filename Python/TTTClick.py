import pygame
from pygame.locals import *
from math import floor
from random import randint
from sys import exit
from time import sleep
from os import path, chdir, getcwd
startPath = getcwd()
chdir("Resources") #Do note that this runs in resources
print("LOADING")

resX = 640
resY = 480
fontPixels = int(resY/20) #Height of Pixels
fontType = "Comic Sans" #Font
borderPixels = 10 #Width between pieces

files = { "icon": "Icon.png", "board": "Board.png", "x": "X.png", "o": "O.png" }
images = {}
for a, b in files.items():
  try: 
    images[a] = pygame.image.load(b)
  except:
    print("Image \"%s\" Not Found" % (b))
multiplier = min(resX,resY) / (max(*images["board"].get_size()))
for a, b in images.items():
  images[a] = pygame.transform.scale(images[a], tuple(int(i * multiplier) for i in images[a].get_size()))
piecesPixels, borderPixels = max(*images["x"].get_size()), borderPixels * multiplier



b = piecesPixels + borderPixels #Allotted space for a piece
slotsPos = [ [(int(b*i),int(b*a)) for i in range(3)] for a in range(3)]
slotsPos[0], slotsPos[2] = slotsPos[2], slotsPos[0] #This is for inverted.
print(slotsPos)

pygame.init()
clockObj = pygame.time.Clock() #Creates a clock object to control fps
windowObj = pygame.display.set_mode((resX,resY)) #Opens window at given resolution
pygame.display.set_caption("TicTacToe")

titleFont = pygame.font.SysFont(fontType, int(fontPixels*3))
printFont = pygame.font.SysFont(fontType, fontPixels)

#Title Sequence
title = titleFont.render("Welcome to TTTClick!", False, (0,255,0))
windowObj.blit(title, ((resX-title.get_size()[0])/2,0))
pygame.display.update()
sleep(2)

player = False #Current player is a bit. False is X, True is O
turn = 1 #Because updated at beginning of turn
slots = [0,0,0,0,0,0,0,0,0] #These are all board positions
def update(slot,currPlayer):
  if slots[slot-1] == 0:
    try:
      slots[slot-1] = int(player) + 1
      return True
    except:
      pass
  return False
def checkWin(): #If board full will raise assertion error
  if not 0 in slots:
    raise(AssertionError)
  for i in [1,2]:
   for a in range(3):
     b = a*3
     if slots[b:b+3] == [i,i,i]:
       return i
     if [slots[a],slots[a+3],slots[a+6]] == [i,i,i]:
       return i
   if [slots[0],slots[4],slots[8]] == [i,i,i] or [slots[2],slots[4],slots[6]] == [i,i,i]:
     return i
def userEvent(type, message):
  pygame.event.post(pygame.event.Event(USEREVENT, myType = type, message = message))

toQuit = False #Quit Flag

while True:
  windowObj.fill((255,255,255)) #Fill screen w/ white
  windowObj.blit(images["board"],(0,0))

  for a in range(9): #Blitting all pieces to screen
    if slots[a] == 1:
      windowObj.blit(images["x"], slotsPos[int(a/3)][a%3])
    elif slots[a] == 2:
      windowObj.blit(images["o"], slotsPos[int(a/3)][a%3])              

  for event in pygame.event.get():
    if event.type in (KEYUP, KEYDOWN): #All the key press events
      print("KEY UP/DOWN")
      print(event.key)
      if event.key in list(range(K_1,K_9+1)) + list(range(K_KP1,K_KP9+1)):
        if update(event.key-K_1+1 if event.key in range(K_1,K_9+1) else event.key-K_KP1+1,player): #Works because key - first number + 1. First is top numbers, second is keypad
          player = not player
    if event.type in (MOUSEBUTTONUP,): #Mouse button up
      for a in range(3):
        for b in range(3):
          c = slotsPos[a][b] #For ease of use
          if not False in list((c[i]<=event.pos[i]<=c[i]+piecesPixels) for i in range(2)):
            if update(a*3+b+1,player): #+1 because first slot is 1, not 0
              player = not player
    if event.type == USEREVENT:
      print(event.myType)
      windowObj.blit(printFont.render(event.message, False, (0,0,0)), (images["board"].get_size()[0],0))
      toQuit = True
    if event.type == QUIT:
      break

  try: #Checking for winner
    winner = checkWin()
    if winner:
      userEvent("Winner", "Player %d has won!" % (winner))
  except:
      userEvent("Winner", "NO WINNER")

  pygame.display.update()
  clockObj.tick(20)
  if toQuit:
    sleep(2)
    break

pygame.quit()
exit()