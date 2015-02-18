#KSP Surface Distance Calculator
#This will find the distance between two points, tell you the angle you need to set, and tell you about how long it takes to get there (at a given speed)
#Get your numbers from a mod like SCANSAT


"""
To make everything easy, I am aligning the map coordinates to a cartesian plane like so:
              | N X +
              |
      W Y+    |         E Y-
      --------------------
              |
              |
              | S X-
              
   This way, to turn the angles into headings, you only need to subtract them from 360
"""

import math

class radii:
  kerbin = 600000
  
rangeY = 180
rangeX = 90
  
def toArc(radius, deg, max):
  return (2*math.pi * radius) * (deg/(2*max))
  
def parseInput(input):
  answer = input.split()
  if len(answer) < 6: return False
  x = float(((int(answer[0])%rangeX) + (int(answer[1])%60)/60) * (answer[2][0].lower() == "n" and 1 or -1))
  y = float(((int(answer[3])%rangeY) + (int(answer[4])%60)/60) * (answer[5][0].lower() == "w" and 1 or -1))
  return x,y
  
def formatTime(seconds):
  a = int(seconds/60/60/24)
  b = int(seconds/60/60 - 24*a)
  c = int(seconds/60 - 60*b)
  d = int(seconds - 60*c)
  return a, b, c, d

def main():
  print("Welcome to the distance and time calculator!")
  print("Coordinate type? (Type 1: 90 60 N 180 60 E, Type 2: 23.78 -76.5)")
  longInput = (eval(input("> ")) == 1)
  posX, posY = False, False
  while type(posX) != float:
    print("\nWhat is your position?")
    if longInput:
      print("Answer like '108 33 N 17 5 W'")
      posX, posY = parseInput(input("> "))
    else:
      print("Answer like '-55.24 78.35' (N/S E/W)")
      posX, posY = input("> ").split()[:]
      posX, posY = float(posX), -float(posY)
    if type(posX) != float: print("Invalid input")
  
  targetX, targetY = False,False
  while type(targetX) != float:
    print("\nWhat is your target's position? Answer like the other one")
    if longInput:
      targetX, targetY = parseInput(input("> "))
    else:
      targetX, targetY = input("> ").split()[:]
      targetX, targetY = float(targetX), -float(targetY)
    if type(targetX) != float: print("Invalid input")
    
  distX = toArc(radii.kerbin, targetX-posX, rangeX)
  distY = toArc(radii.kerbin, targetY-posY, rangeY)
  
  print("\nWhat is your current speed in m/s?")
  speed = float(input("> "))
  
  totalDist = math.sqrt(distX**2 + distY**2)
  
  print("\n\n")
  print("Distance to Target:              ", round(totalDist/1000, 2),"km")
  days, hours, minutes, seconds = formatTime(totalDist/speed)
  print("Estimated time at current speed: ",  days > 0 and (str(days)+" days") or "", hours > 0 and (str(hours)+" hours")  or "", minutes, "minutes", seconds, "seconds")
  print("Required heading:                ", round(360-(math.degrees(math.atan2(distY,distX)) % 360), 2), "degrees")
  
main()