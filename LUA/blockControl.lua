--[[
-- This comment block shows a sample which you put into the main Lua script of the track layout.

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables.
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
--
-- This sample shows the configuration for Demo Layout 03
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Table of named trains having an optional specific train signal to start/stop this train individually.
-- (You can omit the "#" as first character.)
train = {} 		  
-- train[id] = { name = "Train name", onoff = Train signal (optional) }
train[1] = {name="Steam", onoff=14, }
train[2] = {name="Blue",  onoff=4, }

-- Allowed blocks per train (having same id like in table 'train') including optional stay time within blocks in seconds
-- You can and should defined allowed blocks for all named trains.
-- More trains are detected automatically, however, these trains can go everywhere.
allowed = {}
--     block  1, 2, 3, 4, 5, 6
allowed[1]= { 1, 1, 0, 0, 0, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
allowed[2]= { 0, 0, 1, 1, 1, 0}

twowayblk = { 0, 3, 2, 0, 0, 0} -- Blocks which are used in both directions. Enter 0 or related block number
blocksig  = { 8,18, 9,19,10,13} -- Block signals
memsig    = { 5, 6, 7,15,20,21} -- Corresponding memory signal per block

-- Configure possible routes between adjacent blocks by defining the required settings of the turnouts on this path
route = {
--  { from block, to block, turn={ID,state,...}},    with state: 1=main, 2=branch
	{ 1, 6, turn={  2,1, 12,1       }},
	{ 2, 6, turn={  2,2, 12,1, 17,1 }},
	{ 3, 5, turn={ 16,1,  1,2, 11,2 }},
	{ 4, 5, turn={ 16,2,  1,2, 11,2 }},
	{ 5, 3, turn={ 12,2,  2,2, 17,1 }},
	{ 5, 4, turn={ 12,2,  2,2, 17,2 }},
	{ 6, 1, turn={ 11,1,  1,1       }},
	{ 6, 2, turn={ 11,1,  1,2, 16,1 }},
}
-- Using the notation above we define the whole table in one Lua statement (spanning from line 33 to 43). 
-- Instead of this you can use multiple Lua statements  using indices as well:
--route = {}
--route[1] = { 1, 6, turn={  2,1, 12,1       }}
--route[2] = { 2, 6, turn={  2,2, 12,1, 17,1 }}
--...

MAINSW = 3 -- id of the main switch

-- Configuration of the signals (only required if different from default state and not used in this skrip)
-- Example: Signal BS1_KS1_BRK_MAS_oM2_4 requires 1: GREEN, 2: RED
MAINON    = 1 -- 'on' state of main switch
MAINOFF   = 2 -- 'off' state of main switch
BLKSIGRED = 1 -- 'red' state of block signals
BLKSIGGRN = 2 -- 'green' state of block signals
MEMSIGRED = 1 -- 'red' state of memory signals and train signals
MEMSIGGRN = 2 -- 'green' state of memory signals and train signals

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Remaining part of main script in EEP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

clearlog()
blockControl = require("blockControl")

-- Optional: Start automatically after finding all known train 
-- Only do this if you have defined all trains in tables 'train' and 'allowed'.
-- If you have more trains, you have to wait until all trains are detected and start manually. 
blockControl.start(true)	-- Start main switch and all trains (use 'false' if the train signals should not get touched)

function EEPMain()
    blockControl.run()
    return 1
end

--]]

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- MODULE blockControl
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local _VERSION = 'v2022-02-22'

-- Default values for the state of signals
local MAINON        = MAINON    or 1  -- ON    state of main switch
local MAINOFF       = MAINOFF   or 2  -- OFF   state of main switch
local BLKSIGRED     = BLKSIGRED or 1  -- RED   state of block signals
local BLKSIGGRN     = BLKSIGGRN or 2  -- GREEN state of block signals
local MEMSIGRED     = MEMSIGRED or 1  -- RED   state of memory signals
local MEMSIGGRN     = MEMSIGGRN or 2  -- GREEN state of memory signals

local blockReserved = {} -- Stores the free/reserved state for every block, 0=free, trainnr=reserved
local turnReserved  = {} -- Stores the free/reserved state for every turnout, false=free, true=reseved
local memsigOld     = {} -- Old memory signal value, used to check with memsig[b] for 0>1 or 1>0 transitions
local request       = {} -- A train that enters a block will request a new route: trainnr=request pending, 0=no request
local stopTimer     = {} -- Waittime, decremented every EEPmain() cycle, which is 5x/s
local dummyTrain    = -999 -- Dummy train which could reserve a twin block (I've no idea why a small value like -4 would fail.)

local tippTextRED   = "<bgrgb=240,0,0>"
local tippTextGREEN = "<bgrgb=0,220,0>"

--Consistency checks
assert( #train == #allowed,          "ERROR: Count of trains do not match: #train="..#train..                " <> #allowed="..#allowed )
for k = 1, #allowed do
  assert( #allowed[k] == #blocksig,  "ERROR: Count of blocks do not match: #allowed["..k.."]="..#allowed[k].." <> #blocksig="..#blocksig )
end  
assert( #twowayblk == #blocksig,     "ERROR: Count of blocks do not match: #twowayblk="..#twowayblk..        " <> #blocksig="..#blocksig )
assert( #memsig == #blocksig,        "ERROR: Count of blocks do not match: #memsig="..#memsig..              " <> #blocksig="..#blocksig )
for r,_ in pairs(route) do
  assert( #(route[r].turn) % 2 == 0, "ERROR: No pairs of data in route["..r.."].turn" )
end  

-- add dummy entries to simplify index access to tables
train[0]          = {name = "", onoff = 0, route = 0, block = 0}
allowed[0]        = {}
twowayblk[0]      = 0
blocksig[0]       = 0
memsig[0]         = 0
blockReserved[0]  = 0
memsigOld[0]      = 0
request[0]        = 0
stopTimer[0]      = 0
route[0]          = {0,0, turn = {}}

math.randomseed(os.time())
local cycle = 0

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Initialization: Show tipp text on signals via generated functions EEPOnSignal_x
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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
        for t = 1, #train do                           			-- Train signals
            local signal = train[t].onoff
            _ENV["EEPOnSignal_"..signal](EEPGetSignal(signal)) 	-- show current signal status
        end
        for b, signal in ipairs(blocksig) do               		-- Block signals
            _ENV["EEPOnSignal_"..signal](EEPGetSignal(signal)) 	-- show current signal status
        end
        for b, signal in ipairs(memsig) do                 		-- Memory signals
            _ENV["EEPOnSignal_"..signal](EEPGetSignal(signal))	-- show current signal status
        end    
    end
end
-- Train signals
for t = 1, #train do
    local signal = train[t].onoff
	if signal then 
		EEPRegisterSignal(signal)
		_ENV["EEPOnSignal_"..signal] = function(pos)      -- show signal status
			if showTippText then print(string.format("Train %d '%s' Signal %d: %s", t, train[t].name, signal, (pos == MEMSIGRED and "RED" or "GREEN"))) end
			EEPChangeInfoSignal(signal, string.format("%s\n%s", train[t].name, (pos == MEMSIGRED and tippTextRED.."STOP" or tippTextGREEN.."GO")))
			EEPShowInfoSignal(signal, showTippText)
		end
	end
end
-- Block signals
for b, signal in ipairs(blocksig) do
    EEPRegisterSignal(signal)
    _ENV["EEPOnSignal_"..signal] = function(pos)      -- show signal status
        local trainName = EEPGetSignalTrainName(signal, 1) or ""
        if showTippText then print(string.format("Block %d '%s' Signal %d: %s", b, trainName, signal, (pos == BLKSIGRED and "RED" or "GREEN"))) end
        --EEPChangeInfoSignal(signal, string.format("Block %d\n%s\n%d %s", b, trainName, signal, (pos == BLKSIGRED and tippTextRED.."STOP" or tippTextGREEN.."GO"))) -- updated in function run
        --EEPShowInfoSignal(signal, showTippText)
    end
end
-- Memory signals
for b, signal in ipairs(memsig) do
    EEPRegisterSignal(signal)
    _ENV["EEPOnSignal_"..signal] = function(pos)      -- show signal status
        if showTippText then print(string.format("Memory %d Signal %d: %s", b, signal, (pos == MEMSIGRED and "RED" or "GREEN"))) end
        EEPChangeInfoSignal(signal, string.format("Memory %d\n%d %s", b, signal, (pos == MEMSIGRED and tippTextRED.."reserved" or tippTextGREEN.."free")))
        EEPShowInfoSignal(signal, false)--showTippText)
    end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Initialization - find trains
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local FINDMODE = true
print("FIND MODE is active")
EEPSetSignal( MAINSW, MAINOFF )         		-- Main Stop, do not allow creating any new requests
for b = 1, #blocksig do
  EEPSetSignal( blocksig[b], BLKSIGRED, 1 )		-- Stop all trains at block signals

  blockReserved[b] = 0                  		-- Let's assume that there is no train in block ...
  stopTimer[b]     = 0
  EEPSetSignal( memsig[b], MEMSIGGRN, 1 )
  memsigOld[b]     = MEMSIGGRN

  request[b]       = 0							-- ... and no request 
end

for t = 1, #train do
	train[t].block = 0							-- We don't know for sure where the trains is
end

local function findTrains ()
	-- Find trains in blocks
	for b, signal in ipairs(blocksig) do
		local trainName = EEPGetSignalTrainName(signal, 1)  -- Get the train name from EEP
		if trainName ~= "" then								-- The block knows a train
			trainName = string.sub(trainName, 2, -1)		-- Remove leading # character from name
			
			local t											-- Identify the train
			for k = 1, #train do                			-- Search train by name
				if trainName == train[k].name then
				  t = k                                     -- Train found by name
				end
			end
			
			if not t then									-- Create entry for unknown train (without train signal)
				table.insert(train, { name = trainName, onoff = 0, })
				t = #train
				
				allowed[t] = {}
				for b = 1, #blocksig do
					table.insert(allowed[t], 1)				-- Such trains can go everywhere
				end
				
				print(string.format("Create new train %d '%s' in block %d", t, trainName, b))
				
			elseif not train[t].block or train[t].block == 0 then	
				print(string.format("Train %d '%s' found in block %d", t, trainName, b))
				
			else
				-- Train is already known
			end
			
			train[t].block   = b							-- The train occupies the block
			train[t].route   = 0							-- and has no route yet
			
			blockReserved[b] = t							-- Place the train in the block
			blockReserved[twowayblk[b]] = dummyTrain
			EEPSetSignal( memsig[b], MEMSIGRED )			-- Set arrival at new block ...
			memsigOld[b] = MEMSIGGRN						-- ... to request a new route
		end
	end
	
	-- End find mode if user activated the main signal and all trains are assigned to a block
	local finished = true
	for t = 1, #train do
		if not train[t].block or train[t].block == 0 then
		  finished = false        						-- Train found by name
		end
	end
	if finished then
		if EEPGetSignal( MAINSW ) == MAINON then 	
			FINDMODE = false
			print("FIND MODE finished")
		else
		
		end
	end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Show current signal status of all block signals
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local function showSignalStatus()

  -- Main signal
  if FINDMODE then
    EEPChangeInfoSignal(MAINSW, "<b>Initialization: Find trains and place them into blocks</b>")
    EEPShowInfoSignal(MAINSW, true)
  else
    local pos = EEPGetSignal( MAINSW )
    EEPChangeInfoSignal(MAINSW, "Block control is active"
	  .."\n".. (pos == MAINOFF and tippTextRED.."RED" or tippTextGREEN.."GREEN")
	)
    EEPShowInfoSignal(MAINSW, showTippText)
  end

  -- Block signals
  for b, signal in ipairs(blocksig) do
    local t   = blockReserved[b]
    local pos = EEPGetSignal( signal )
    local mem = EEPGetSignal( memsig[b] )
 
    local trainName = EEPGetSignalTrainName(signal, 1)      -- Get the name from EEP if the signal already holds the train ...
    if trainName == "" then 
	  if t > 0 then
	    trainName = train[t].name                           -- ... otherwise get it from the table 
	  elseif t == dummyTrain then
	    trainName = "dummy train" 
	  end
	end

    EEPChangeInfoSignal(signal, "Block"
      .." "..  string.format("%d", b) 
      .."\n".. trainName
--      .." "..  string.format("%d", t)
--      .."\n".. (mem == MEMSIGRED and tippTextRED.."RED" or tippTextGREEN.."GREEN")
--      .." "..  string.format("%d", memsig[b])
      .."\n".. (pos == BLKSIGRED and tippTextRED.."RED" or tippTextGREEN.."GREEN")
--      .." "..  string.format("%d", signal) 
    )
    EEPShowInfoSignal(signal, showTippText)
  end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Function to be called in EEPMain
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local function run ()

  if FINDMODE then 
    findTrains()                        -- Find trains and assign them to blocks
    showSignalStatus()                  -- Show current signal status of all block signals
	return
  end

  cycle = cycle + 1                     -- EEPMain cycle number
  if cycle % 25 == 1 then               -- Do this every 5 seconds, given that EEPmain() runs 5x/s
    if EEPGetSignal( MAINSW ) == MAINOFF then print("Main switch is off") end
  end
  
  showSignalStatus()                    -- Show current signal status of all block signals

  local available = {} 					-- Stores available routes. Per EEPmain() cycle only one route will be randomly selected fom this table
  
  for b = 1, #blocksig do               -- Check all blocks for arrivals and calculate possible new routes

    local t = blockReserved[b]          -- A train or a dummy train has reserved this block (could be 0, then the block is free)
    
    if stopTimer[b] > 0 then stopTimer[b] = stopTimer[b] - 1 end     -- count down the block stop time

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check for released blocks
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    local pos = EEPGetSignal( memsig[b] )
    if pos == MEMSIGGRN and memsigOld[b] == MEMSIGRED then           -- A train released this block
      memsigOld[b] = MEMSIGGRN                                       -- Set block memory old to free, now this 'if' statement won't run again

      local trainId = (t > 0 and t or 0)
      print("Train ",t," '",train[trainId].name,"' released block ",b,(twowayblk[b] > 0 and " and twin block "..twowayblk[b] or ""),(t == dummyTrain and " ### DUMMY TRAIN ###" or ""))

      train[trainId].block = 0                                       -- Set train to be located outside of any block

      EEPSaveData( b, 0 )                                            -- Save the state in file for when EEP closes
      if twowayblk[b] > 0 then EEPSaveData( twowayblk[b], 0 ) end    -- Also save the two-way twin block state, to get loaded in next cycle

      blockReserved[b] = 0                                           -- Set block to 'free'
      blockReserved[twowayblk[b]] = 0                                -- Also the two way twin block is now 'free'

      EEPSetSignal( blocksig[b], BLKSIGRED, 1 )                      -- Set the block signal to RED
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Check arrivals and set new route requests
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if t > 0 then                                                    -- A real train...
      local pos = EEPGetSignal( memsig[b] )
      if pos == MEMSIGRED and memsigOld[b] == MEMSIGGRN then         -- ... enters a free block which is now occupied by this train 
        memsigOld[b] = MEMSIGRED                                     -- Set block memory old to 'occupied', now this 'if' statement won't run again

        print("Train ",t," '",train[t].name,"' arrived in block ",b," and stays at least for ",allowed[t][b]," sec")
        train[t].block = b                                           -- Remember the location of the train...

        if twowayblk[b] > 0 then            
          EEPSaveData( twowayblk[b], dummyTrain )                    -- ... and save a dummy train in the corresponding two way twin block, to get loaded in next cycle
          print("Save dummy train in twin block ",twowayblk[b])
        end

        EEPSaveData( b, t )                                          -- Save the train number in this block, to get loaded in next cycle

        request[b]   = t                                             -- Flag is raised that train t in block b requests a new route

        if allowed[t][b] > 1 then 
          stopTimer[b] = 5 * allowed[t][b]                           -- calculate the stop timer in seconds
        end

        local r = train[t].route                                     -- Get current route
        local pb = route[r][1]                                       -- previous bock where the train came from
        EEPSetSignal( memsig[pb], MEMSIGGRN, 1 )                     -- Set memory signal of previous block to GREEN to release it next cycle
        print("Release block ",pb," in next cycle")

        for to = 1, #route[r].turn / 2 do                            -- The turn table contains pairs of data
          local switch = route[r].turn[to*2-1]
          turnReserved[ switch ] = false                             -- Release the turnouts of the current route
        end
      end
    end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@  Make a list of all possible routes for trains who's stop stopTimer ran out
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    if t > 0 then                                                    -- A real train...
      if request[b] > 0 and stopTimer[b] == 0 then                   -- ... has a request and no wait time
	    local signal = train[t].onoff or 0							 -- Does this train has a train signal?
        local pos = EEPGetSignal( signal )
        if pos == 0 or  pos == MEMSIGGRN then         				 -- Stop time passed and train switch is ON
 
          for r,_ in pairs(route) do                                 -- Check for free destination blocks in the route table
            local fromBlock = route[r][1]
            local toBlock   = route[r][2]
            if fromBlock == b and allowed[t][toBlock] > 0 then

              local free = blockReserved[toBlock]                    -- Check if the destination block is free (free==0)

              for to = 1, #route[r].turn / 2 do                      -- Check if the route turnouts are free (free==0)
                local switch = route[r].turn[to*2-1]
                if turnReserved[ switch ] then free = free + 1 end
              end

              if free == 0 then                                      -- the destination block and turnouts are free (VIA BLOCKS ARE NOT USED YET)
                available[#available + 1] = r                        -- Append this free route to the 'available' table
                if EEPGetSignal( MAINSW ) == MAINON then 
                  print ("Train ",t," '",train[t].name,"' can go from ",fromBlock," to ",toBlock) 
                end
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

  elseif #available > 0 then                            -- At least one route is available
    local nr = available[math.random(#available)]       -- A new route is randomly selected
    local cb = route[nr][1]                             -- Current block, where the train is now
    local db = route[nr][2]                             -- Destination block, where the train will drive to
    local t  = blockReserved[cb]                        -- Nr of the train in the current block
    local trainId = (t>0 and t or 0)
    train[trainId].route = nr
    request[cb]  = 0                                    -- New route is allocated, reset the request for a new route
    blockReserved[db] = trainId                         -- Set destination block to 'reserved', other trains can't select it anymore

    if twowayblk[db] > 0 then
      blockReserved[twowayblk[db]] = dummyTrain         -- Also set the two way twin block to 'reserved' with the dummy train nr
      --print("blockReserved[",twowayblk[db],"] = dummyTrain for block ",db," and train ",t)
    end

    for to = 1, #route[nr].turn / 2 do                  -- Reserve and switch the turnouts
      local switch = route[nr].turn[to*2-1]
      local pos    = route[nr].turn[to*2]
      EEPSetSwitch( switch, pos )
      turnReserved[ switch ] = true                     -- Reserve the turnout
    end

    EEPSetSignal( blocksig[cb], BLKSIGGRN, 1 )          -- Current block signal to GREEN, the train may go.
    EEPSetSignal( blocksig[db], BLKSIGRED, 1 )          -- Destination block signal to RED, train may have to stop there.
    print("Train ",t," '",train[trainId].name,"' travels from block ",cb," to ",db)
  end

  return
end

local function start (allTrains)
	EEPSetSignal( MAINSW, MAINON )						-- Activate main signal
	
	if allTrains then
		for t = 1, #train do							-- Activate all train signals
			local signal = train[t].onoff
			if signal then 
				EEPSetSignal( train[t].onoff, MEMSIGGRN )
			end
		end
	end
end

local function stop (allTrains)
	EEPSetSignal( MAINSW, MAINOFF )						-- Deactivate main signal
	
	if allTrains then
		for t = 1, #train do							-- Deactivate all train signals
			local signal = train[t].onoff
			if signal then 
				EEPSetSignal( train[t].onoff, MEMSIGRED )
			end
		end
	end
end

-- API of the module
local blockControl = {
    run 	= run,		-- Call this function in EEPMain
	
	start 	= start,	-- Optional: Start main signal and start trains	
	stop 	= stop,		-- Optional: Stop main signal and stop trains
}

return blockControl
