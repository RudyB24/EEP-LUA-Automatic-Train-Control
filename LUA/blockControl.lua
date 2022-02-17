--[[
-- This comment block shows a sample which you put into the main Lua script of the track layout.

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
--
-- Configuration for Demo Layout 03
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- To place trains, change the code to PLACE_TRAINS=1, reload, 
-- place the trains and fill the initial position of the train in the trains[t] table,
-- and finally set PLACE_TRAINS=0 and reload.           
PLACE_TRAINS = 0
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

train = {} -- Table of max 99 trains
--          Train name    Train signal       Initial position of the train
train[1] = {name="Steam", onoff=14, route=0, block=6}
train[2] = {name="Blue",  onoff=4,  route=0, block=5}

allowed = {} -- Allowed blocks per train including optional stay time within blocks in seconds
--     block  1, 2, 3, 4, 5, 6
allowed[1]= { 1, 1, 0, 0, 0, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
allowed[2]= { 0, 0, 1, 1, 1, 0}

twowayblk = { 0, 3, 2, 0, 0, 0} -- 0 or related block number
blocksig  = { 8,18, 9,19,10,13} -- block signals
memsig    = { 5, 6, 7,15,20,21} -- memory signals

route = {}
-- route[n] = {from block, to block, turn={ID,state,...}} state: 1=main, 2=branch
route[ 1] = { 1,6,turn={ 2,1, 12,1}}
route[ 2] = { 2,6,turn={ 2,2, 12,1, 17,1}}
route[ 3] = { 3,5,turn={16,1,  1,2, 11,2}}
route[ 4] = { 4,5,turn={16,2,  1,2, 11,2}}
route[ 5] = { 5,3,turn={12,2,  2,2, 17,1}}
route[ 6] = { 5,4,turn={12,2,  2,2, 17,2}}
route[ 7] = { 6,1,turn={11,1,  1,1}}
route[ 8] = { 6,2,turn={11,1,  1,2, 16,1}}

MAINSW    = 3 -- id of the main switch

-- Configuration of the signals (only required if different from default state)
-- Example: Signal BS1_KS1_BRK_MAS_oM2_4 requires 1: GREEN, 2: RED
MAINON    = 1 -- 'on' state of main switch
MAINOFF   = 2 -- 'off' state of main switch
BLKSIGRED = 1 -- 'red' state of block signals
BLKSIGGRN = 2 -- 'green' state of block signals
MEMSIGRED = 1 -- 'red' state of memory signals
MEMSIGGRN = 2 -- 'green' state of memory signals

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()
blockControl = require("blockControl")

function EEPMain()
	blockControl.run()
	return 1
end

--]]

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- MODULE blockControl
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local _VERSION = 'v2022-02-17'
local MAX = 100

-- Default values for the state of signals
local MAINON    	= MAINON    or 1  -- ON    state of main switch
local MAINOFF   	= MAINOFF   or 2  -- OFF   state of main switch
local BLKSIGRED 	= BLKSIGRED or 1  -- RED   state of block signals
local BLKSIGGRN 	= BLKSIGGRN or 2  -- GREEN state of block signals
local MEMSIGRED 	= MEMSIGRED or 1  -- RED   state of memory signals
local MEMSIGGRN 	= MEMSIGGRN or 2  -- GREEN state of memory signals

local blockReserved = {} -- Stores the free/reserved state for every block, 0=free, trainnr=reserved
local turnReserved  = {} -- Stores the free/reserved state for every turnout, 0=free, 1=reseved
local available     = {} -- Stores available routes. Per EEPmain() cycle only one route will be randomly selected fom this table
local memsigOld     = {} -- Old memory signal value, used to check with memsig[b] for 0>1 or 1>0 transitions
local request       = {} -- A train that enters a block will request a new route: trainnr=request pending, 0=no request
local stopTimer     = {} -- Waittime, decremented every EEPmain() cycle, which is 5x/s

-- add dummy entries to simplify index access to tables
train[0]      		= {name = "", onoff = 0, route = 0, block = 0}
train[MAX]    		= {name = "", onoff = 0, route = 0, block = 0}
allowed[0]    		= {}
twowayblk[0]  		= 0
blocksig[0]  		= 0
memsig[0]     		= 0
blockReserved[0]	= 0
memsigOld[0]  		= 0
request[0]    		= 0
stopTimer[0]  		= 0
route[0]     		= {0,0, turn = {}}
for to = 0, 99 do turnReserved[to] = 0 end -- BEWARE, 99 is the max number of turnouts. If more, change the number!

math.randomseed(os.time())
local cycle = 0

-- Initialization after placing trains 
if PLACE_TRAINS == 1 then
  print("PLACE_TRAINS == 1")

  EEPSetSignal( MAINSW, MAINOFF )

  for b = 1, #blocksig do
	EEPSaveData( b, 0 ) 								-- Write 0's to the block reservation disk file to make them not nil
	EEPSetSignal( blocksig[b], BLKSIGRED, 1 ) 			-- Set all block signals to RED
  end

  for t = 1, #train do                					-- For all trains ...
    print(string.format("Store train %d '%s' in block %d", t, train[t].name, train[t].block))
	EEPSaveData( train[t].block, t ) 					-- ... write the train nr to its current block in the reservation disk file
	EEPSaveData( twowayblk[train[t].block], t+MAX ) 	-- Reserve the two way twin block with dummy train nr t+MAX
	EEPSetSignal( train[t].onoff, MEMSIGRED, 1 )
  end
  print("Initialization finished, change code to PLACE_TRAINS = 0")
end

-- Initialization 
for b = 1, #blocksig do
  local ok, t      = EEPLoadData( b ) 					-- Read the train nr that reserves block b from the disk file ...

  blockReserved[b] = t              					-- ... and write it in the blockReserved[b] table
  memsigOld[b]     = MEMSIGGRN
  request[b]       = 0
  stopTimer[b]     = 0

  if t > 0 and t < MAX then 							-- if it's a two way twin block (t > MAX) we don't put memsig[b] on RED
	EEPSetSignal( memsig[b], MEMSIGRED, 1 )
	print(string.format("Memory %d\n%d: %s for train %d '%s'", b, MEMSIGRED, "RED", t, train[t].name))
  else 
	  EEPSetSignal( memsig[b], MEMSIGGRN, 1 )
	  print(string.format("Memory %d\n%d: %s for train %d '%s'", b, MEMSIGGRN, "GREEN", t, (t > MAX and train[t-MAX].name or  "")))
  end
end

-- Initialization: Show tipp text on signals via generated functions EEPOnSignal_x
-- <j> linkbündig, <c> zentriert, <r> rechtsbündig, <br> Zeilenwechsel 
-- <b>Fett</b>, <i>Kursiv</i>, <fgrgb=0,0,0> Schriftfarbe, <bgrgb=0,0,0> Hintergrundfarbe
-- siehe https://www.eepforum.de/forum/thread/34860-7-6-3-tipp-texte-f%C3%BCr-objekte-und-kontaktpunkte/
local showTippText = false
-- Toggle visibility using the main switch
EEPRegisterSignal(MAINSW)
_ENV["EEPOnSignal_"..MAINSW] = function(pos)
	if pos == MAINON then 
		showTippText = not showTippText
		print("Toggle tipp text: ",tostring(showTippText))
		for k, t in ipairs(train) do                           -- Train signals
			local signal = t.onoff
			_ENV["EEPOnSignal_"..signal](EEPGetSignal(signal)) -- show current signal status
		end
		for block, signal in ipairs(blocksig) do               -- Block signals
			_ENV["EEPOnSignal_"..signal](EEPGetSignal(signal)) -- show current signal status
		end
		for block, signal in ipairs(memsig) do                 -- Memory signals
			_ENV["EEPOnSignal_"..signal](EEPGetSignal(signal)) -- show current signal status
		end	
	end
end
-- Train signals
for k, t in ipairs(train) do
	local signal = t.onoff
	EEPRegisterSignal(signal)
	_ENV["EEPOnSignal_"..signal] = function(pos)      -- show signal status
		if showTippText then print(string.format("Train %d '%s' Signal %d: %s", k, train[k].name, signal, (pos == MEMSIGRED and "RED" or "GREEN"))) end
		EEPChangeInfoSignal(signal, string.format("%s\n%s", t.name, (pos == MEMSIGRED and "<bgrgb=240,0,0>RED" or "<bgrgb=0,220,0>GREEN")))
		EEPShowInfoSignal(signal, showTippText)
	end
end
-- Block signals
for block, signal in ipairs(blocksig) do
	EEPRegisterSignal(signal)
	_ENV["EEPOnSignal_"..signal] = function(pos)      -- show signal status
		local trainName = EEPGetSignalTrainName(signal, 1) or ""
		if showTippText then print(string.format("Block %d '%s' Signal %d: %s", block, trainName, signal, (pos == BLKSIGRED and "RED" or "GREEN"))) end
		--EEPChangeInfoSignal(signal, string.format("Block %d\n%s\n%d %s", block, trainName, signal, (pos == BLKSIGRED and "<bgrgb=240,0,0>RED" or "<bgrgb=0,220,0>GREEN")))
		--EEPShowInfoSignal(signal, showTippText)
	end
end
-- Memory signals
for block, signal in ipairs(memsig) do
	EEPRegisterSignal(signal)
	_ENV["EEPOnSignal_"..signal] = function(pos)      -- show signal status
		if showTippText then print(string.format("Memory %d Signal %d: %s", block, signal, (pos == MEMSIGRED and "RED" or "GREEN"))) end
		EEPChangeInfoSignal(signal, string.format("Memory %d\n%d %s", block, signal, (pos == MEMSIGRED and "<bgrgb=240,0,0>RED" or "<bgrgb=0,220,0>GREEN")))
		EEPShowInfoSignal(signal, false)--showTippText)
	end
end

print("blockControl Initialization finished\n")

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Call this function in EEPMain
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local function run ()
 
  if PLACE_TRAINS == 1 then return end -- do nothing as long as PLACE_TRAINS is 1

  cycle = cycle + 1 -- EEPMain cycle number
  if cycle % 25 == 1 then -- Do this every 5 seconds, given that EEPmain() runs 5x/s
    if EEPGetSignal( MAINSW ) == MAINOFF then print("Main switch is off") end
  end
  
  -- show current signal status of block signals
  for block, signal in ipairs(blocksig) do
    local trainName = EEPGetSignalTrainName(signal, 1) or ""
	local pos = EEPGetSignal( signal )
    EEPChangeInfoSignal(signal, string.format("Block %d\n%s\n%d %s", block, trainName, signal, (pos == BLKSIGRED and "<bgrgb=240,0,0>RED" or "<bgrgb=0,220,0>GREEN")))
    EEPShowInfoSignal(signal, showTippText)	  
  end

  local fr = 0 -- free routes
  for b = 1, #blocksig do -- check all blocks for arrivals and calculate possible new routes

    local t = blockReserved[b] -- Train t has reserved this block (could be 0, then the block is free)
	
    if stopTimer[b] > 0 then stopTimer[b] = stopTimer[b] - 1 end -- count down the block stop time

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check for released blocks
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	local pos = EEPGetSignal( memsig[b] )
    if pos == MEMSIGGRN and memsigOld[b] == MEMSIGRED then 	-- A train released this block
      print("Train ",t," '",train[t].name,"' released block ",b)
	  
      memsigOld[b] = MEMSIGGRN                             	 -- Set block memory old to free, now this 'if' statement won't run again

      blockReserved[b] = 0                                   -- Set block to 'free'
      blockReserved[twowayblk [b]] = 0                       -- Also the two way twin block is now 'free'

      EEPSaveData( b, 0 )                                    -- Save the state in file for when EEP closes
      EEPSaveData( twowayblk [b], 0 )                        -- Also save the two-way twin block state

      EEPSetSignal( blocksig[b], BLKSIGRED, 1 )              -- Set the block signal to RED
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check arrivals and set new route requests
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    local pos = EEPGetSignal( memsig[b] )
    if pos == MEMSIGRED and memsigOld[b] == MEMSIGGRN then -- There is a new train in this block
      print("Train ",t," '",train[t].name,"' arrived in block ",b," - stop for ",allowed[t][b]," sec")
	  
      EEPSaveData( b, t )                                     -- Save the train number in this block to disk, to be read when EEP reopens
      EEPSaveData( twowayblk [b], t+MAX )                     -- Save the the dummy train nr t+MAX in the two way twin block on disk

      memsigOld[b] = MEMSIGRED                                -- Set block memory old to 'occupied', now this 'if' statement won't run again
      request[b] = t                                          -- Flag is raised that train t in block b requests a new route

      if allowed[t][b] > 1 then 
        stopTimer[b] = 5 * allowed[t][b] 
      end

      local r = train[t].route
      local pb = route[r][1]                                  -- previous bock where the train came from
      EEPSetSignal( memsig[pb], MEMSIGGRN, 1 )                -- Set memory signal of previous block to GREEN to release it next cycle
      --print("Release block ",b," in next cycle")

      for to = 1, #route[r].turn / 2 do
	    local switch = route[r].turn[to*2-1]
        turnReserved[ switch ] = 0                            -- Release the turnouts of the current route
      end
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Make a list of all possible routes for trains who's stop stopTimer ran out
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if request[b] > 0 and stopTimer[b] == 0 then
      local pos = EEPGetSignal( train[t].onoff )
	  --print("Train ",t," '",train[t].name,"' Signal ",train[t].onoff," = ",pos) 
	  if pos == MEMSIGGRN then                                    -- Stop time passed and train switch is ON
        for r = 1, #route do                                    -- Check for free destination blocks in the route table
          if route[r][1] == b and allowed[t][route[r][2]] > 0 then

            local free = blockReserved[route[r][2]]             -- Check if the destination block is free (free==0)

            for to = 1, #route[r].turn / 2 do                   -- Check if the route turnouts are free (free==0)
			
			  local switch = route[r].turn[to*2-1]
              free = free + turnReserved[ switch ]
            end

            if free == 0 then                                   -- the destination block and turnouts are free (VIA BLOCKS ARE NOT USED YET)
              fr = fr + 1                                       -- increment free routes counter
              available[fr] = r                                 -- Store this free route in the 'available' table
              if EEPGetSignal( MAINSW ) == MAINON then 
                print ("Train can go from ",route[r][1]," to ",route[r][2]) 
              end
            end

          end
        end
      end
    end
    
  end -- for b=1, ...

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Randomly select a route to start from the available ones
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

  if EEPGetSignal( MAINSW ) == MAINOFF then
    return -- Quit because no new route is activated

  elseif fr > 0 then                                -- At least one route is available
    local nr = available[math.random(fr)]           -- A new route is randomly selected
    local cb = route[nr][1]                         -- Current block, where the train is now
    local db = route[nr][2]                         -- Destination block, where the train will drive to
    local t = blockReserved[cb]                     -- Nr of the train in the current block
    train[t].route = nr
    request[cb]  = 0                                -- New route is allocated, reset the request for a new route
    blockReserved[db] = t                           -- Set destination block to 'reserved', other trains can't select it anymore
    blockReserved[twowayblk [db]] = t+MAX           -- Also set the two way twin block to 'reserved' with the dummy train nr t+MAX

    for to = 1, #route[nr].turn / 2 do              -- Reserve and switch the turnouts
	  local switch = route[nr].turn[to*2-1]
	  local pos    = route[nr].turn[to*2]
      EEPSetSwitch( switch, pos )
      turnReserved[ switch ] = 1                    -- Reserve the turnout
    end

    EEPSetSignal( blocksig[cb], BLKSIGGRN, 1 )      -- Current block signal to GREEN, the train may go.
    EEPSetSignal( blocksig[db], BLKSIGRED, 1 )      -- Destination block signal to RED, train may have to stop there.
    print("Train ",t," '",train[t].name,"' from block ",cb," to ",db)
  end

  return
end

-- API of the module
local blockControl = {
	run = run,		-- Call this function in EEPMain
}

return blockControl
