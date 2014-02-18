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

class gameBoard(object):
  def __init__(self):
    self.player = False #Current player is a bit. False is X, True is O. This variable assigns who goes first
    self.humanPlayer = False #Which player is human
    self.twoPlayer = False #If true, player is always human
    self.difficulty = 2 #Difficulties 0 - 2 in increasing difficulty
    self.turn = 1 #Because updated at beginning of turn
    self.slots = [0] * 9 #These are all board positions
    
  def update(board, slot, player):
    try:
      if board.slots[slot] == 0:
        board.slots[slot] = int(player) + 1
        #print("Slot %d belongs to Player %d in turn %d" % (slot,currPlayer,turn-1)) #Debug
        return True
    except (IndexError, ValueError, TypeError):
      pass
    return False
  def checkWin(board, doRaise = True): #If board full will raise assertion error
    for i in [1,2]:
     for a in range(3):
       b = a*3
       if board.slots[b:b+3] == [i,i,i]:
         return i
       if [board.slots[a],board.slots[a+3],board.slots[a+6]] == [i,i,i]:
         return i
     if [board.slots[0],board.slots[4],board.slots[8]] == [i,i,i] or [board.slots[2],board.slots[4],board.slots[6]] == [i,i,i]:
       return i
    if not 0 in board and doRaise:
      raise(AssertionError)
    return 0
  def isFree(board, slot): #For AI. This checks if a slot is free
    return board.slots[slot] == 0
  def randomMove(board, movesList): #Cedrick's Random move function
      moves = []
      for x in movesList:
          if isFree(board, x):
              moves.append(x)
      if len(moves) != 0:
          return random.choice(moves)
  def getComputerMove(board): #the AI part! 
      #Priority Order:
      #1. See if computer can win
      #2. See if player can win next turn 
      #3. Player first turn condition (???)
      #4. Check sneaky wins/counters
      #5. corners > center > edges
      difficultyCheck = random.randint(0,10) #Lower difficulties have a chance of AI not realizing what its doing
      if difficulty >= 2 or (difficulty == 2 and not difficultyCheck == 0) or (difficulty == 0 and difficultyCheck in [i for i in range(6)]):
        for x in range(0, 9):
            copy = board + [0] #This is so checkwin does not think its "slots". Should not affect calculations
            if isFree(copy, x):
                update(x, player, copy)
                if checkWin(copy)-1 == player: #If current player (AI) is winner
                    return x
       
        for y in range(0, 9):
            copy = board + [0] 
            if isFree(copy, y):
                update(y,not player, copy)
                if checkWin(copy)-1 == (not player): #CheckWin returns player 1 or 2
                    return y
                  
      if difficulty >= 2: #I consider this a "hard" level behavior    
        tableOfCorners = [board.slots[0],board.slots[2],board.slots[6],board.slots[8]]            
        if tableOfCorners.count(player+1) == 2: #If has two corners, pick the third
          copy = board + [0]
          for i in [0,2,6,8]:
            if isFree(copy,i):
              return i
        if tableOfCorners.count((not player) + 1) == 2: #Prevents opposite corner start trick
          return randomMove(board,[1,3,7,5])
      
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

titleFont = pygame.font.SysFont(fontType, int(fontPixels*5)) #These are the two fonts I will use
printFont = pygame.font.SysFont(fontType, fontPixels)

"""
#Config
player = False #Current player is a bit. False is X, True is O. This variable assigns who goes first
humanPlayer = False #Which player is human
twoPlayer = False #If true, player is always human
difficulty = 2 #Difficulties 0 - 2 in increasing difficulty
turn = 1 #Because updated at beginning of turn
slots = [0] * 9 #These are all board positions
"""
action = False #Quit Flag. Can be set to 'quit' or 'menu'

"""def init(): #???
  global player, humanPlayer, twoPlayer, difficulty, turn, slots, action
  player = False #Current player is a bit. False is X, True is O. This variable assigns who goes first
  humanPlayer = False #Which player is human
  twoPlayer = False #If true, player is always human
  difficulty = 2 #Difficulties 0 - 2 in increasing difficulty
  turn = 1 #Because updated at beginning of turn
  slots = [0] * 9 #These are all board positions

  action = False #Quit Flag. Can be set to 'quit' or 'menu'
"""

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
def switchPlayer():
  global player, humanPlayer, turn
  player = not player
  if twoPlayer:
    humanPlayer = player
  turn += 1
  
#Title Sequence
"""title = titleFont.render("Welcome to TTTClick!", True, (0,255,0))
windowObj.blit(title, ((resX-title.get_size()[0])/2,0))
pygame.display.update()
waitForGeneric([KEYUP,MOUSEBUTTONUP],3)
pygame.event.get() #Get rid of excess events"""

title = titleFont.render("Tic Tac Toe", True, (0,0,0))
pixelBorder = 5 #Width of pixel border
def makeButton (text, textColor, backgroundColor, borderWidth):
  borderTuple = (borderWidth, borderWidth)
  button = titleFont.render(text, True, textColor, (255,255,255))
  x, y = button.get_size()
  background = pygame.Surface((x+borderWidth*2, y+borderWidth*2))
  background.fill(backgroundColor)
  background.blit(button, (borderWidth, borderWidth))
  return background
colorBlack = (255,0,0)
start = makeButton("Start", colorBlack, colorBlack, pixelBorder)
quit = makeButton("Quit", colorBlack, colorBlack, pixelBorder)
def center (target, toPlace):
  xMax, yMax = target.get_size()
  x, y = toPlace.get_size()
  return (xMax-x)/2, (yMax-y)/2



def menu(): #This should work since I don't redeclare anything?
  windowObj.fill((255,255,255))
  windowObj.blit(title, (center(windowObj,title)[0], pixelBorder))
  startPos = tuple(center(windowObj,start))
  startRect = start.get_rect(topleft = startPos)
  windowObj.blit(start, startPos )
  a = tuple(center(windowObj,quit))
  quitPos = (a[0],a[1]+start.get_size()[1]+pixelBorder)
  quitRect = quit.get_rect(topleft = quitPos)
  windowObj.blit(quit, quitPos)
  pygame.display.update()

  while True:
    event = waitForClick(5)
    if not event:
      break
    if event.button == 1:
      print(event.pos)
      if startRect.collidepoint(event.pos):
        break
      if quitRect.collidepoint(event.pos):
        raise(SystemExit)
    
board = "defined" #Just initializing  
def init():
  global board
  board = gameBoard()
 
      
action = "menu"
while True:
  if action == "menu":
    sleep(2)
    menu()
    init()
  if action == "quit":
    sleep(2)
    break

  if board.twoPlayer:
    board.humanPlayer = board.player #Tell computer that player always human
  windowObj.fill((255,255,255)) #Fill screen w/ white
  windowObj.blit(images["board"],(0,0))

  try: #Checking for winner
    winner = checkWin() #Main board, raise exception if full
    if winner:
      userEvent("Winner", "Player %d has won!" % (winner))
  except AssertionError:
      userEvent("Winner", "NO WINNER")

  events = pygame.event.get()
  
  for event in events: #Cleanup Events to Quit game.
    if event.type == USEREVENT and event.myType == "Winner":
      print(event.myType,"   ",event.message)
      windowObj.blit(printFont.render(event.message, True, (0,0,0)), (images["board"].get_size()[0],0))
      action = "menu"
    if event.type == QUIT:
      action = "quit"

  if not action: #If nothing special is happening
    if board.player == board.humanPlayer:
      for event in events:
        if event.type in (KEYDOWN,): #All the key press events
          print("KEY DOWN")
          print(event.key)
          if event.key in list(range(K_1,K_9+1)) + list(range(K_KP1,K_KP9+1)):
            if update(event.key-K_1 if event.key in range(K_1,K_9+1) else event.key-K_KP1,player): #Works because key - first number. First is top numbers, second is keypad
              board.switchPlayer()
        if event.type in (MOUSEBUTTONUP,): #Mouse button up
          for a in range(3):
            for b in range(3):
              c = slotsPos[a][b] #For ease of use
              if not False in list((c[i]<=event.pos[i]<=c[i]+piecesPixels) for i in range(2)): #I think this is to see if the mouse is in a certain square
                if update(a*3+b,player): #+1 because first slot is 1, not 0
                  board.switchPlayer()
    else:
      print("Computer Starting Move")
      while True:
        if board.update(getComputerMove(),board.player):
          break
      board.switchPlayer()

  for a in range(9): #Blitting all pieces to screen
    if slots[a] == 1:
      windowObj.blit(images["x"], slotsPos[int(a/3)][a%3])
    elif slots[a] == 2:
      windowObj.blit(images["o"], slotsPos[int(a/3)][a%3])

  #Blitting turn and player counters
  windowObj.blit(printFont.render("Player %d" % (int(player)+1), True, (0,0,0)), (images["board"].get_size()[0],25))
  windowObj.blit(printFont.render("Turn %d" % turn, True, (0,0,0)), (images["board"].get_size()[0],50))
  
  pygame.display.update()
  clockObj.tick(20)
  

pygame.quit()
exit()