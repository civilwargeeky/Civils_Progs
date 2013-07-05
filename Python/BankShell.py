import bank as bank
from time import sleep

#Bank is done :)
#I will go through some examples
#The bank functions never print anything, so you will have to do that on your own
#Do note that each person acts as both an object, and a part of the master table, you can use them both ways
def printSleep(words, time = 1): #For simulated UI
  print(words)
  sleep(time)
def func(words,func,*params):
  print(words)
  return func(*params)


print(bank.register("Civil",100)) #I have 100 dollars, this returns my name and number
print(bank.register("Bill", 200)) #Bill has 200 dollars
print(bank.getInfo()) #Gets bank stats
print(bank.getInfo("civil0001")) #They "proper" way to get the info
print(bank.getInfo(bank.getName("Civil",1))) #Easier way
print(bank.getInfo(bank.getNum("Civil"))) #Alternate way, less reliable
def UI_Test():
  printSleep("What is your name? ")
  name = "Bill"
  printSleep(name)
  printSleep(bank.getInfo(bank.getNum(name)),3) #To show how this is implemented
  printSleep("What is you name and number? ")
  name_number = "Bill 0002"
  printSleep(name_number)
  name, number = name_number.split(" ")
  printSleep(bank.getInfo(name.lower()+number),2) #If you have the name and number, you can do bank.getName by yourself
if bank.getInfo[1] == 300:
  UI_Test()
print(bank.getInfo()) #Should be $300
func("Depositing $300 Into Civil's Account",bank.deposit,bank.getNum("Civil"),300)
print(bank.getInfo())