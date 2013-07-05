@echo off
set currLoc=%cd%
set pythonBank=FullBank.py
if exist %pythonBank% (
  echo Found File, starting now, if you can read this, something has gone wrong
  start python %pythonBank%
) else (
  echo Could not find %pythonBank%, try again
)
