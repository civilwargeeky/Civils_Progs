#Bank Program API
#Made by civil
#Version 0.0.1
saveFile = "Bank_Save"

#Git commit branch test

"""Ideas:
1. Every user will have the following functions:
  a. Deposit
  b. Withdraw
  c. Apply for loan
  d. Pay for loan (Unique loan number)
  e. Check balance
2. Put a current loan number in master for loan assignment  """
"""The way each account works (in order of number):
0. Full Name (Dict location is first name, maybe concatenate an id number?)
1. Balance
2. Interest rate
3. Transactions
"""
"""Master Loans section is like this:
0. Pointer to account
1. Amount outstanding
2. Loan interest
3. Original amount
"""

#Generic Functions
def genBefFunc(account = "Default", num = 1): #Generic Before Function: Will handle interest rates, also checks for account and that num is > 0  
  """Idea: Interest rates will be calculated every time an account function is called,
  based on real time using an I = Pe^(rt) continous interest model """
  return (account in master.accounts or account == "Default") and num > 0

def genAftFunc(amount = 0, account = None): #Generic After Function: Will handle transactions add and bank add to master
  master.balance += amount
  master.transactions += 1
  if account in master.accounts: master.accounts[account][3] += 1
  return True
  


class InitMaster(object): #This is so I can use lua-like arrays with objects
  def __init__(self, bankStart = 0, transactions = 0, accounts = {}):
    self.balance = bankStart #Bank Balance
    self.transactions = 0 #Total bank transactions
    self.accounts = {} #All the names and data
    self.names = {} #Backups of names for easy finding
    self.loans = [] #Where all loan data is stored
    self.loanNum = 1 #Current number of loans
    self.idNum = 1 #Current Number of users
    self.depositRate = 0.05 #Member interest rate
    self.loanRate = 0.10 #Bank loan rate

master = InitMaster()

#Main Bank Functions
def getName(account,id):
  return account.lower().split(" ",1)[0]+"%04d" % id
  
def getNum(name):
  name = name.lower()
  if name in master.names:
    return getName(name,master.names[name])
  
def register(name = "Default", startingBalance = 0, rate = master.depositRate, transactions = 0):
  if not (isinstance(startingBalance,int)) or startingBalance < 0 or name.lower()[:5] == "master": #last check is so no error on checkName
    return False
  master.accounts[getName(name,master.idNum)] = [name,startingBalance,rate,transactions] #The account name is the lowercase first word of their name concatenated with the current 4-digit id number
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
      return genAftFunc(-amount, account)
  return False, "Bank" if master.balance < amount else "Account" #This is pretty experimental  
  
def getInfo(account = "Master"):
  if not (genBefFunc(account) or account == "Master"): return False
  if account == "Master":
    return account, master.balance, master.depositRate, master.transactions
  a = master.accounts[account] #To save typing and copy/paste
  return a[0], a[1], a[2], a[3]
  
def newLoan(account = "Default", amount = 0,rate = master.loanRate):
  if not genBefFunc(account,amount): return False
  if master.balance >= amount:
    master.loans[master.loanID] = [master.accounts[account],amount,rate,amount]
    master.loanID += 1
    genAftFunc(-amount, account)
    return master.loanID - 1
  return False

def payLoan(account, amount, loanID):
  if not (genBefFunc(account,amount) and master.loans[loanID]) or master.loans[loanID][1] == 0: return False
  if amount >= master.loans[loanID][1]: amount = master.loans[loanID][1]
  master.loans[loanID][1] -= amount
  return genAftFunc(amount,account)
  
def setGenInterest(type,num):
  genBefFunc()
  if num > 1: num /= 100
  type = num

def setDepositInterest(num):
  setGenInterest(master.depositRate,num)
def setLoanInterest(num):
  setGenInterest(master.loanRate,num)
