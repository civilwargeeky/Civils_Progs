#fileDifFinder.py
#Made so I can easily remove cfgs from Kerbal Space Program
#Version 0.0.1
import os

doDebug = True
def debug(*args):
  if doDebug:
    print(*args)

def getFileList(dir, topDir = None):
  if topDir == None:
    topDir = os.path.basename(dir)
  toRet = []
  for file in os.listdir(dir):
    name = os.path.join(dir,file)
    localName = os.path.join(topDir,file)
    if os.path.isdir(name):
      debug("Invoking another list")
      toRet += getFileList(name, localName)
      debug("Done invoking")
    else:
      print("Adding",localName)
      toRet.append(localName)
  return toRet

def findDifFiles(dir1, dir2):
  files1 = getFileList(dir1)
  print()
  files2 = getFileList(dir2)
  difList = []
  if len(files2) > len(files1):
    debug("More files in 2, switching")
    files1, files2 = files2, files1
  
  for i in files1:
    if not i in files2:
      debug("Different file:",i)
      difList.append(i)
  
  return difList
  
def make(dir1, dir2, outputFile):
  debug("Making expected file list")
  dif = findDifFiles(dir1, dir2)
  file = open(outputFile, "w")
  for i in dif:
    file.write(i+"\n")
  file.close()
  return True
  
def delete(dir, inputFile):
  debug("Deleteing Files")
  shouldDelete = []
  file = open(inputFile,"r")
  for i in file.readlines():
    shouldDelete.append(i[:-1])
  fileList = getFileList(dir)
  for i in fileList:
    #debug("Checking",i)
    if i in shouldDelete:
      debug("Deleting",i)
      os.remove(os.path.join(list(os.path.split(dir))[0],i))
  debug("Removing empty directories")
  for dir, directories, files in os.walk(dir, topdown=False): #Because starting from bottom, there will never be possibly non-empty directories
    if len(files) == 0 and len(directories) == 0: #If empty directory
      debug("Removing",dir)
      os.rmdir(dir)