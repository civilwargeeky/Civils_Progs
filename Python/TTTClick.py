print("LOADING")

import pygame
from pygame.locals import * #Events in global
from math import floor
from random import randint
from sys import exit
from time import sleep
from os import path, chdir, getcwd
startPath = getcwd()
chdir("Resources") #Do note that this runs in resources
print("This screen is now the console and will print debug info")

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
    print("Image %s Loaded" % (b))
  except:
    print("Image \"%s\" Not Found" % (b))
multiplier = min(resX,resY) / (max(*images["board"].get_size()))
for a, b in images.items():
  images[a] = pygame.transform.scale(images[a], tuple(int(i * multiplier) for i in images[a].get_size())) #Scales images to match proper window size
piecesPixels, borderPixels = max(*images["x"].get_size()), borderPixels * multiplier #Sets piecesPixels to the larger dimension, scales border pixels. 



b = piecesPixels + borderPixels #Allotted space for a piece
slotsPos = [ [(int(b*i),int(b*a)) for i in range(3)] for a in range(3)] #Top left positions of all pictures for slot[a][b]
slotsPos[0], slotsPos[2] = slotsPos[2], slotsPos[0] #This is for inverted.
print("Image Positions: ",slotsPos)

pygame.init()
clockObj = pygame.time.Clock() #Creates a clock object to control fps
windowObj = pygame.display.set_mode((resX,resY)) #Opens window at given resolution
pygame.display.set_caption("TicTacToe") #Sets window title

titleFont = pygame.font.SysFont(fontType, int(fontPixels*3)) #These are the two fonts I will use
printFont = pygame.font.SysFont(fontType, fontPixels)

#Title Sequence
title = titleFont.render("Welcome to TTTClick!", False, (0,255,0))
windowObj.blit(title, ((resX-title.get_size()[0])/2,0)) #Centered
pygame.display.update()
while True:
  if pygame.event.get(MOUSEBUTTONUP): #Waits for click
    break

player = False #Current player is a bit. False is X, True is O
turn = 1 #Because updated at beginning of turn
slots = [0,0,0,0,0,0,0,0,0] #These are all board positions
def update(slot,currPlayer):
  if slots[slot] == 0:
    try:
      slots[slot] = int(currPlayer) + 1
      global turn; turn += 1
      print("Slot %d belongs to Player %d in turn %d" % (slot,currPlayer,turn-1)) #Debug
      return True
    except (IndexError, ValueError):
      pass
  return False
def checkWin(): #If board full will raise assertion error
  for i in [1,2]:
   for a in range(3):
     b = a*3
     if slots[b:b+3] == [i,i,i]:
       return i
     if [slots[a],slots[a+3],slots[a+6]] == [i,i,i]:
       return i
   if [slots[0],slots[4],slots[8]] == [i,i,i] or [slots[2],slots[4],slots[6]] == [i,i,i]:
     return i 
  if not 0 in slots:
    raise(AssertionError)
def userEvent(type, message): #This is so I can make my own events. event.myType is title, event.message is details
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
        if update(event.key-K_1 if event.key in range(K_1,K_9+1) else event.key-K_KP1,player): #Works because key - first number. First is top numbers, second is keypad
          player = not player
    if event.type in (MOUSEBUTTONUP,): #Mouse button up
      for a in range(3):
        for b in range(3):
          c = slotsPos[a][b] #For ease of use
          if not False in list((c[i]<=event.pos[i]<=c[i]+piecesPixels) for i in range(2)):
            if update(a*3+b,player): #+1 because first slot is 1, not 0
              player = not player
    if event.type == USEREVENT:
      print(event.myType,"   ",event.message)
      windowObj.blit(printFont.render(event.message, False, (0,0,0)), (images["board"].get_size()[0],0))
      toQuit = True
    if event.type == QUIT:
      toQuit = True

  windowObj.blit(printFont.render("Player %d" % (int(player)+1), False, (0,0,0)), (images["board"].get_size()[0],25))
  windowObj.blit(printFont.render("Turn %d" % turn, False, (0,0,0)), (images["board"].get_size()[0],50))
  
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