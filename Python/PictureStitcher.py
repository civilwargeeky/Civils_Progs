import pygame
import os

originalPath = "C:\\Users\\danielklinger15\\Dropbox\\Finished Seniors\\Finished"

pygame.init()

pics = []

for file in os.listdir(originalPath):
  file = os.path.join(originalPath,file)
  if os.path.isfile(file) and file[-3:] == "png":
    pics.append(pygame.image.load(file))


print("Pictures:",len(pics))
widths = []
for i in range(len(pics)):
  a = pics[i]
  size = a.get_size()
  widths.append(size[0])
  print(size)

maxWidth = int(round(sum(widths)/len(widths),-2)) #Round -2 so we get hundreds. Should be around 650
print("Width:",maxWidth)

heights = []
for i in range(len(pics)):
  pic = pics[i]
  width, height = pic.get_size()[:] 
  scaleFactor = maxWidth / width #This gives a > 1 val for smaller pics, < 1 val for bigger
  pics[i] = pygame.transform.scale(pic, (int(width*scaleFactor), int(height*scaleFactor))) #puts destination as same pic
  heights.append(height*scaleFactor)
  
maxHeight = int(round(sum(heights)/len(heights),-2))

array = []
across = 5
for i in range(0,len(pics),across):
  try:
    array.append(pics[i:i+across])
  except IndexError:
    array.append(pics[i:])
print("Rows:",len(array))
    
maxHeights = []
for i in array:
  sub = []
  for a in i:
    sub.append(a.get_size()[1])
  maxHeights.append(max(sub))
print("Heights: ",maxHeights)
totalHeight = sum(maxHeights)
totalWidth = maxWidth*across

bigPicture = pygame.Surface((totalWidth,totalHeight))
bigPicture.fill((255,255,255))

currentPos = [0,0]
for a in range(len(array)):
  for b in array[a]:
    print("Current Pos:",currentPos)
    bigPicture.blit(b, (currentPos[0],currentPos[1]))
    currentPos[0] += b.get_size()[0]
  currentPos[0] = 0
  currentPos[1] += maxHeights[a]
    
pygame.image.save(bigPicture, "TestPicture.png")
  
pygame.quit()