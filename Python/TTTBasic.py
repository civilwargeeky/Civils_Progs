#Version 1.1
from math import floor
from random import randint
disp = [[0,0,0],[0,0,0],[0,0,0]] #Just a placeholder
slots = [0,0,0,0,0,0,0,0,0]
def updateDisp():
  for i in range(9):
    x = i%3
    y = floor(i/3)
    if slots[i] == 1:
      disp[y][x] = "X"
    elif slots[i] == 2:
      disp[y][x] = "O"
    else:
      disp[y][x] = "/"
def brack(input):
  return "["+str(input)+"]"
def printBoard(printExtra):
#Total length of screen is 25
  if printExtra:
    print("It is currently turn "+str(turn)+", Player "+currentPlayer)
  print("---------------")
  for i in range(3): #Prints list backward
    i = 2-i          #To better understand, comment this line
    a = i*3
    print(str(disp[i])+"       "+brack(a+1)+brack(a+2)+brack(a+3))
  print("---------------")
  if printExtra:
    for i in range(18):
     print("")
def update(slot,currPlayer):
  if len(slot) != 1:
    return False
  slot = int(slot,36)
  if not 1<=slot<=9:
    return False
  if slots[slot-1] != 0:
    return False
  slots[slot-1] = currPlayer
  updateDisp()
  return True
def checkWin():
  for i in [1,2]:
   for a in range(3):
     b = a*3
     if slots[b:b+3] == [i,i,i]:
       return i
     if [slots[a],slots[a+3],slots[a+6]] == [i,i,i]:
       return i
   if [slots[0],slots[4],slots[8]] == [i,i,i] or [slots[2],slots[4],slots[6]] == [i,i,i]:
     return i
AI = (input("Would you like to play with an AI? ").lower()[:1] == "y")
AI_last = 7
player = 1
currentPlayer = "X"
turn = 1 #Because updated at beginning of turn
updateDisp()
while True:
  printBoard(True)
  if AI and player == 2:
    passed = False
    for i in [AI_last-1,AI_last+1,AI_last+3,AI_last-3]:
      if update(str(i),player):
        passed = True
        AI_last = i
        break
    if not passed:
      while not update(str(randint(1,9)),player):
        continue
  else:
    while not update(input("Which slot? "),player):
      print("Number did not work, try again")
      printBoard(False)
  if player == 2:
    turn += 1
  winner = checkWin()
  if winner == 1:
    print("X won!")
    break
  elif winner == 2:
    print("O won!")
    break
  if player == 1:
    player = 2
    currentPlayer = "O"
  else:
    player = 1
    currentPlayer = "X"
printBoard(False)