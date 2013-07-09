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
def inputInt(failText = "", initText = None): #Will keep asking for a number, printing failText if invalid number
  if initText:
    print(initText)
  toRet = None #Assign before reference
  while not( isinstance(toRet,int)):
    try:
      toRet = int(input())
    except ValueError:
      print(failText)
  return toRet

commandList = {"master":True, "new":True}
  
def welcome(): #Will repeat this until user data is proper
  print("Welcome to the bank!")
  print("Please enter your name as it appears on your bank card (Just pretend),")
  print("or type New to make a new account")
  name = input() #Get full name (not needed :P Just need first)
  try:
    commandList[name.lower()] #Get the key error immediately
    if name.lower() == "master": #Get bank stats
      num = 0 #To prevent errors
      print("Master Balance: %.2f" % (bank.getInfo()[1]) )
      print("Total Transactions: %d" % (bank.getInfo()[3]) )
      tab = ">> "
      for _, a in bank.master.accounts.items(): #Super sneaky hax
        print("%sName: %s\n%s%sBalance: %.2f\n" % (tab, a[0],tab[:-1],tab, a[1]))
      input("Press enter to continue...")
    if name.lower() == "new":
      while True: #Repeat loop in case of invalid new name
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
        if name != False:
          break
        else:
          cls()
          print("Invalid Name")
      print("Thank you, %s, your new bank number is %d" % (name, num))
      print("Keep this information somewhere you will remember")
      input("Press Enter to continue...")
  except KeyError:
    print("What is your bank ID number?") #Need ID number as well
    num = inputInt("Number not recognized, try again")
  accountName = bank.getName(name,num)
  return bank.exists(accountName,num), accountName #Returns that the account exists, as well as the account name (e.g. "default0001")
  
def header(): #At top of screen
  print("-----Current Account: %s  |  Balance: %d  -----" % (bank.getInfo(account)[0], bank.getInfo(account)[1]))

def payLoan(): #To long for lambda
  print(account)
  for a, b in enumerate(bank.master.loans): 
    if bank.master.loans[a][0] == bank.master.accounts[account]:
      return bank.payLoan(account,inputInt("Invalid LoanID","What is your LoanID"),inputInt("Invalid amount","What amount would you like to pay off?"))
  print("You have no loans outstanding")
  return False

menu = [] #Form is: text, function | All functions must return true or false
menu.append(["Check Account Info", lambda: print("Balance: %d, Account Interest Rate: %.2f, # of Transactions %d" % (bank.getInfo(account)[1:4])) or True])
menu.append(["Deposit Money", lambda: bank.deposit(account, inputInt("Invalid Number","How much money would you like to deposit?"))])
menu.append(["Withdraw Money", lambda: (bank.withdraw(account, inputInt("Invalid Number","How much money would you like to withdraw?")))[0]])
menu.append(["Apply for Loan", lambda: print("Your loan number is %d" % bank.newLoan(account,inputInt("Invalid Number","How much is this loan? "))) or True ] )
menu.append(["Pay off Loan", payLoan])
menu.append(["Sign Out", lambda: "Signing Out"])

while True: #Actual program loop
  #Getting user information before we give options
  while True: #This is a makeshift "repeat ... until" loop that will go through at least once
    test, account = welcome()
    if test:
      break
    else:
      cls()
      print("Account not found, try again\n") #Newlines to differentiate from regular program
  while True: #Selection of items loop
    while True: #Repeat Loop
      cls()
      header()
      for number, tab in enumerate(menu):
        print("[%d] %s" % (number, tab[0]))
      try:
        item = int(input("Which item would you like? "))
        if not ( 0 <= item < len(menu)): #Catches numbers out of menu range
          raise(ValueError)
      except ValueError: #Catches not numbers
        pass
      if isinstance(item, int):
        break
    if 0 <= item < len(menu):
      print("Task Succeeded: %r" % (menu[item][1]())) #Calls menu item, and tells if succeeded
    if item == len(menu) - 1: #If they selected "Sign Out"
      cls()
      break
    else:
      input("Press Enter to continue...")
