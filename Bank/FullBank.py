#This is the actual bank program that will do all the major banking stuff
#E.G., not just a proof of concept
#Made by civilwargeeky
#Version 0.0.1

print("Beginning bank... please wait")
import bank
from time import sleep
from os import system

def cls():
  system("cls")
def inputInt(failText = ""):
  toRet = None
  while not( isinstance(toRet,int)):
    try:
      toRet = int(input())
    except ValueError:
      print(failText)
  return toRet

def welcome(): #Will repeat this until user data is proper
  print("Welcome to the bank!")
  print("Please enter your name as it appears on your bank card (Just pretend),")
  print("or type New to make a new account")
  name = input() #Get full name (not needed :P Just need first)
  if name == "New":
    print("Ok, to start, what is your full name?")
    name = input()
    print("How much money are you depositing initially?")
    amnt = input()
    while not (isinstance(amnt,float)): #This makes sure it is actually a number, then rounds it to two places
      try:
        amnt = round(float(amnt),2)
      except ValueError:
        print("Number not recognized, try again")
        amnt = input()
    name, num = bank.register(name, amnt) #Registers the new user, returns their bank ID number
    print("Thank you, %s, your new bank number is %d" % (name, num))
    sleep(1)
    print("Keep these somewhere you will remember")
    sleep(1)
  else:
    print("What is your bank ID number?") #Need ID number as well
    num = inputInt("Number not recognized, try again")
  accountName = bank.getName(name,num)
  return bank.exists(accountName,num), accountName #Returns that the account exists, as well as the account name (e.g. "default0001")

#Getting user information before we give options
while True: #This is a makeshift "repeat ... until" loop that will go through at least once
  test, account = welcome()
  if test:
    break
  else:
    print("Account not found, try again\n") #Newlines to differentiate from regular program

#Yay! It worked!
print(bank.getInfo(account))
print(bank.getInfo())