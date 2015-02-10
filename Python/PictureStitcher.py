import pygame
import os

#Config
textHeight = 150
bufferX = 70 #Buffer between pictures in pixels
bufferY = 30
across = 7



command = os.popen("echo %userprofile%")
userDir = command.read()[:-1]
command.close()
print("Current Directory:",userDir)
originalPath = userDir + "\\Dropbox\\Finished Seniors\\Finished"
outputPath = userDir + "\\Desktop"

pygame.init()

font = pygame.font.SysFont(None, textHeight)
def getText(text):
  toRet = font.render(text, True, (0,0,0))
  return toRet, toRet.get_size()[1]

#This finds all available pictures and loads them into an array
pics = []
names = [] #Pics and names will be synced numerically
for rawFile in os.listdir(originalPath):
  file = os.path.join(originalPath,rawFile)
  if os.path.isfile(file) and file[-3:] == "png":
    pics.append(pygame.image.load(file))
    names.append("".join(i for i in rawFile[:-4].split()[0].replace("Fixed","") if not i.isdigit())) #Heh. This removes the ".png", the "Fixed", all numbers, and only takes first word
    print("Loading pic: ",names[-1])


print("Pictures:",len(pics))
#This collects a list of picture widths, for future resizing
widths = []
heights = []
for i in range(len(pics)):
  a = pics[i]
  size = a.get_size()
  widths.append(size[0])
  heights.append(size[1])
  #print(size) #Debug

#This is the mean width of pictures, the maximum width we allow for scaling
maxWidth = int(round(sum(widths)/len(widths),-2)) #Round -2 so we get hundreds. Should be around 650
print("Width:",maxWidth)
maxHeight = int(round(sum(heights)/len(heights),-2)) #gonna try copying
print("Height:",maxHeight)

#This generates a list of heights and resizes all the pictures
heights = []
for i in range(len(pics)):
  pic = pics[i]
  width, height = pic.get_size()[:] 
  scaleFactor = maxWidth / width #This gives a > 1 val for smaller pics, < 1 val for bigger
  print(names[i],height)
  if height*scaleFactor > maxHeight:
    scaleFactor = maxHeight/height
  pics[i] = pygame.transform.scale(pic, (int(width*scaleFactor), int(height*scaleFactor))) #puts destination as same pic
  print(names[i], pics[i].get_size()[1])
  heights.append(height*scaleFactor)
  
maxHeight = int(round(sum(heights)/len(heights),-2))

#This separates the pictures into fixed length arrays
array = []
for i in range(0,len(pics),across):
  try:
    array.append(pics[i:i+across])
  except IndexError:
    array.append(pics[i:])
print("Rows:",len(array))
    
#This finds the tallest height of every row
maxHeights = []
for i in array:
  sub = []
  for a in i:
    sub.append(a.get_size()[1])
  maxHeights.append(max(sub))
print("Heights: ",maxHeights)

maxWidth += bufferX #Done here to avoid mucking scale factors

totalHeight = sum(maxHeights) + len(maxHeights) * (textHeight + bufferY) #Adding in text and buffer
totalWidth = maxWidth*across

#This is the surface everything will be blitted to
bigPicture = pygame.Surface((totalWidth,totalHeight))
bigPicture.fill((255,255,255))

#This is finally the actual process of placing everything properly.
currentPos = [0,0]
for a in range(len(array)):
  for i in range(len(array[a])):
    b = array[a][i]
    #print("Current Pos:",currentPos) #Debug
    bigPicture.blit(b, (currentPos[0],currentPos[1]+textHeight))
    toRender, height = getText(names[a*across + i])
    bigPicture.blit(toRender, (currentPos[0], currentPos[1]))
    currentPos[0] += maxWidth + xBuffer #b.get_size()[0]
  currentPos[0] = 0
  currentPos[1] += maxHeights[a] + textHeight + bufferY

print("Saving Picture...")
output =  outputPath + "\\TestPicture.png"
print("Saving to",output)
pygame.image.save(bigPicture, output)
  
pygame.quit()