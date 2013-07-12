#Bank Program API
#Made by civil
#Version 0.1.0
saveFile = "BankRestore.bank"
multiUser = True

"""Ideas:
1. Every user will have the following functions:
  a. Deposit
  b. Withdraw
  c. Apply for loan
  d. Pay for loan (Unique loan number)
  e. Check balance
2. Put a current loan number in master for loan assignment  """
"""The way each account works (in order of number):
0. Full Name
1. Balance
2. Interest rate
3. Transactions
4. ID number
"""
"""Master Loans section is like this:
0. Pointer to account
1. Amount outstanding
2. Loan interest
3. Original amount
"""
import pickle #For file saving
from os import system, path #For file handling
from time import time
from math import exp

#Generic Functions
def calcInterest(principal, rate, time): 
  return principal*exp(rate*time) #Interest = principal * e ^ (rate * time)

def genBefFunc(account = "Default", num = 1): #Generic Before Function: Will handle interest rates, also checks for account and that num is > 0  
  global master
  if multiUser: #This will load the master from file every time anything is done.
    if path.exists(saveFile):
      with open(saveFile,"rb") as file:
        master = pickle.load(file)
  master.newTime = time() #All of the below is for calculating interest
  changedTime = (master.newTime-master.oldTime)/60/24 #We'll measure it in days, instead of years
  master.oldTime = time()
  for a in master.loans: #Calculate loan
    a[1], a[3] = calcInterest(a[1],a[2],changedTime), calcInterest(a[3],a[2],changedTime)
  for a, b in master.accounts.items(): #Calculates accounts
    orig = b[1]
    b[1] = calcInterest(b[1],b[2],changedTime)
    master.balance += (b[1] - orig) #Add in interest to balance
  """Idea: Interest rates will be calculated every time an account function is called,
  based on real time using an I = Pe^(rt) continous interest model """
  
  return ((account in master.accounts) or account == "Default") and num > 0
  
exists = genBefFunc #So the user can check accounts
update = lambda: genBefFunc() or True

def genAftFunc(amount = 0, account = None): #Generic After Function: Will handle transactions add and bank add to master
  master.balance += amount
  master.transactions += 1
  if account in master.accounts: master.accounts[account][3] += 1
  pickle.dump(master,open(saveFile,"wb"))
  return True
  
class InitMaster(object): #This is so I can use lua-like arrays with objects
  def __init__(self, bankStart = 0, transactions = 0, accounts = {}):
    self.balance = float(bankStart) #Bank Balance
    self.transactions = 0 #Total bank transactions
    self.accounts = {} #All the names and data
    self.names = {} #Backups of names for easy finding
    self.loans = [] #Where all loan data is stored
    self.loanID = 1 #Current number of loans
    self.idNum = 1 #Current Number of users
    self.depositRate = 0.05 #Member interest rate
    self.loanRate = 0.10 #Bank loan rate
    self.oldTime = time() #For interest calculation
    self.newTime = time()

master = InitMaster()
if path.exists(saveFile):
  with open(saveFile,"rb") as file:
    master = pickle.load(file)

#Main Bank Functions
def getName(account,id):
  return account.lower().split(" ",1)[0]+"%04d" % id

def getNum(name):
  name = name.lower()
  if name in master.names:
    return getName(name,master.names[name])
    
def formatName(name):
  if len(name) < 3 or not isinstance(name,str): return False
  toRet = ""
  for a in name.split(" "): toRet += a[0].upper() + a[1:].lower() + " "
  return toRet[:-1]
  
  
def register(name, startingBalance = 0, rate = master.depositRate, transactions = 0):
  if not (isinstance(startingBalance,float)) or startingBalance < 0 or name.lower()[:5] == "master" or len(name) < 3:
    return False, 0
  master.accounts[getName(name,master.idNum)] = [formatName(name),float(startingBalance),rate,transactions, master.idNum] #The account name is the lowercase first word of their name concatenated with the current 4-digit id number
  master.names[getName(name,0)[:-4]] = master.idNum
  master.idNum += 1
  genAftFunc(startingBalance)
  return name, master.idNum - 1

def deposit(account = "Default", amount = 0):
  if not genBefFunc(account, amount): return False
  master.accounts[account][1] += amount
  return genAftFunc(amount, account)

def withdraw(account = "Default", amount = 0):
  if not genBefFunc(account,amount): return False
  if master.balance >= amount:
    if master.accounts[account][1] >= amount:
      master.accounts[account][1] -= amount
      return genAftFunc(-amount, account), "Good"
  return False, ("Bank" if master.balance < amount else "Account") #This is pretty experimental  
  
def getInfo(account = "Master"):
  if not (genBefFunc(account) or account == "Master"): return False
  if account == "Master":
    return (account, master.balance, master.depositRate, master.transactions)
  a = master.accounts[account] #To save typing and copy/paste
  return tuple(master.accounts[account])
  
def getLoanInfo(account, loanID):
  if not (genBefFunc(account)): return False
  return master.loans[loanID-1]
  
def newLoan(account, amount = 0,rate = master.loanRate):
  if not genBefFunc(account,amount): return False
  if master.balance >= amount:
    master.loans.insert(master.loanID, [master.accounts[account],float(amount),rate,float(amount)])
    master.loanID += 1
    genAftFunc(-amount, account)
    return master.loanID - 1
  return False
  
def payLoan(account, loanID, amount):
  loanID -= 1
  try:
    if not (genBefFunc(account,amount) and master.loans[loanID]) or master.loans[loanID][1] == 0: return False
  except IndexError:
    return False
  if amount >= master.loans[loanID][1]:
    amount = master.loans[loanID][1] #Because genAftFunc handles master balance
    del master.loans[loanID]  #If it is gone, it should be gone
  else: 
    master.loans[loanID][1] -= amount
  return genAftFunc(amount,account)
  
def setGenInterest(type,num):
  genBefFunc()
  if num > 1: num /= 100
  type = num
  return type == num

def setDepositInterest(num): return setGenInterest(master.depositRate,num)
def setLoanInterest(num): return setGenInterest(master.loanRate,num)
