--Rednet Control Station
--Version 0.1.0


sandbox = { lists = {}} --This is the table of list objects
sandbox.new = function(position, listener, activation) --Params
  local tab = {}
  table.insert(sandbox.lists, tab)
  
end

local fileFolder = "civilsRsCS"
--File Reading

--Program Purpose Functions to be used in coroutine

--Computer Input Listener --Waits for input on the computer (key strokes, mouse clicks, screen taps)

--Outside input listener --Goes through list of listeners that items register, waits
----Part of this will be a section that writes to a table of rednet messages in list so that listeners can access rednet.
------Cool idea: Since the function's sandbox will be inherited, have your own "rednet" table for getting and sending messages
----In listener and activation functions, the object's spaces should be passed as self, as a local area.

--Function Doer --Gets passed events that it should do, pointing to the proper functions to do.

--Display Updater --Handles all of the displaying of text and gets passed updates to states