#Note: I am trying to adapt cedricks AI into this program.
print("LOADING")

import pygame
from pygame.locals import * #Events in global
from math import floor
import random
from sys import exit
from time import sleep, time
from os import path, chdir, getcwd
startPath = getcwd()
chdir("Resources") #Do note that this runs in resources
print("This screen is now the console and will print debug info")

resX = 640
resY = 480
fontPixels = int(resY/20) #Height of Pixels
fontType = "Comic Sans" #Font
borderPixels = 10 #Width between pieces

files = { "board": "Board.png", "x": "X.png", "o": "O.png" }
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

player = False #Current player is a bit. False is X, True is O
humanPlayer = False
turn = 1 #Because updated at beginning of turn
slots = [0] * 9 #These are all board positions
def update(slot,currPlayer, board = slots):
  try:
    if board[slot] == 0:
      board[slot] = int(currPlayer) + 1
      if board == slots: #Because now there is more than one board possible
        global turn; turn += 1
      #print("Slot %d belongs to Player %d in turn %d" % (slot,currPlayer,turn-1)) #Debug
      return True
  except (IndexError, ValueError, TypeError):
    pass
  return False
def checkWin(board = slots): #If board full will raise assertion error
  for i in [1,2]:
   for a in range(3):
     b = a*3
     if board[b:b+3] == [i,i,i]:
       return i
     if [board[a],board[a+3],board[a+6]] == [i,i,i]:
       return i
   if [board[0],board[4],board[8]] == [i,i,i] or [board[2],board[4],board[6]] == [i,i,i]:
     return i
  if not 0 in board:
    raise(AssertionError)
  return 0
def isFree(board, slot): #For AI. This checks if a slot is free
  return board[slot] == 0
def randomMove(board, movesList): #Cedrick's Random move function
    moves = []
    for x in movesList:
        if isFree(board, x):
            moves.append(x)
 
    if len(moves) != 0:
        return random.choice(moves)
def getComputerMove(): #the AI part! 
    board = slots
    # priority order - 1)see if computer can win 2)see if player can win next turn 3) player first turn condition 4) corners > center > edges
    for x in range(0, 9):
        copy = board + [0] #This is so checkwin does not think its "slots". Should not affect calculations
        if isFree(copy, x):
            update(x, player, copy)
            if checkWin(copy)-1 == int(player): #If current player (AI) is winner
                return x
   
    for y in range(0, 9):
        copy = board + [0] 
        if isFree(copy, y):
            update(y,not player, copy)
            if checkWin(copy)-1 == int(not player): #CheckWin returns player 1 or 2
                return y
   
    cornerMove = not(isFree(board,0) and isFree(board,2) and isFree(board,6) and isFree(board,8))
    edgeMove = not(isFree(board,1) and isFree(board,3) and isFree(board,7) and isFree(board,5))
    cornerMove2 = (not(isFree(board,0) or isFree(board,8))) or (not(isFree(board,2) or isFree(board,6)))
    firstTurn, secondTurn = None, None #Defining out of local
    if turn <= 2: #This is basically what Cedrick did, right?
      firstTurn = 0
      secondTurn = 0
    
    if firstTurn == 0 and cornerMove:
        firstTurn=1
        secondTurn=1
        return 4
    if secondTurn==1 and cornerMove2:
        secondTurn=2
        return randomMove(board, [1,3,7,5])
    if firstTurn==0 and edgeMove:
            firstTurn=3
            return 5
    move = randomMove(board, [0, 2, 6, 8])
    if move != None:
        return move
   
    if isFree(board, 4):
        return 4
        
    return randomMove(board, [1, 3, 7, 5])
    
    for a in range(0,9): #If nothing else worked...
      checkWin() #Will raise assertion error if board full
      if slots[a] == 0:
        return a
def userEvent(type, message): #This is so I can make my own events. event.myType is title, event.message is details
  pygame.event.post(pygame.event.Event(USEREVENT, myType = type, message = message))
def waitForGeneric(event, timeout = 1E100):
  startTime = time()
  while True:
    if pygame.event.peek(event):
      for a in pygame.event.get(event):
        return a
    if time() >= startTime + timeout:
      return False
def waitForClick(timeout = 1E100): return waitForGeneric(MOUSEBUTTONUP, timeout)
def waitForKey(timeout = 1E100): return waitForGeneric([KEYUP],timeout)
  
#Title Sequence
title = titleFont.render("Welcome to TTTClick!", True, (0,255,0))
windowObj.blit(title, ((resX-title.get_size()[0])/2,0))
pygame.display.update()
waitForGeneric([KEYUP,MOUSEBUTTONUP],3)

toQuit = False #Quit Flag

while True:
  windowObj.fill((255,255,255)) #Fill screen w/ white
  windowObj.blit(images["board"],(0,0))

  for a in range(9): #Blitting all pieces to screen
    if slots[a] == 1:
      windowObj.blit(images["x"], slotsPos[int(a/3)][a%3])
    elif slots[a] == 2:
      windowObj.blit(images["o"], slotsPos[int(a/3)][a%3])              
  
  events = pygame.event.get()
  
  for event in events:
    if event.type == USEREVENT:
      print(event.myType,"   ",event.message)
      windowObj.blit(printFont.render(event.message, True, (0,0,0)), (images["board"].get_size()[0],0))
      toQuit = True
    if event.type == QUIT:
      toQuit = True
  
  if player != humanPlayer and not toQuit:
    print("Computer Move")
    while True:
      if update(getComputerMove(),player):
        break
    player = not player
  else:
    for event in events:
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
            if not False in list((c[i]<=event.pos[i]<=c[i]+piecesPixels) for i in range(2)): #I think this is to see if the mouse is in a certain square
              if update(a*3+b,player): #+1 because first slot is 1, not 0
                player = not player


  windowObj.blit(printFont.render("Player %d" % (int(player)+1), True, (0,0,0)), (images["board"].get_size()[0],25))
  windowObj.blit(printFont.render("Turn %d" % turn, True, (0,0,0)), (images["board"].get_size()[0],50))
  
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