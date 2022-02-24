-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables.
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
--
-- This sample shows the configuration for Demo Layout 02
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Table of named trains having an optional specific train signal to start/stop this train individually.
-- (You can omit the "#" as first character.)
train = {} 
--           Train name    Train signal (optional)
train[1] = { name="Steam", onoff=14, }
train[2] = { name="Blue",  onoff=4, }

-- Allowed blocks per train including optional stay time within blocks in seconds
-- You can and should defined allowed blocks for all named trains.
-- More trains are detected automatically, however, these trains can go everywhere.
allowed = {}
--     block  1, 2, 3, 4
allowed[1]= {15, 0, 0, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
allowed[2]= { 0, 1, 1, 0}

twowayblk = { 0, 0, 0, 0} -- Blocks which are used in both directions. Enter 0 or related block number
blocksig  = { 8, 9,10,13} -- Block signals
memsig    = { 5, 6, 7,15} -- Corresponding memory signal per block

-- Configure possible routes between blocks here
route = {}
-- route[n] = {from block, to block, turn={ID,state,...}} state: 1=main, 2=branch
route[ 1] = { 1,4,turn={ 2,1, 12,1}}
route[ 2] = { 2,3,turn={ 1,2, 11,2}}
route[ 3] = { 3,2,turn={12,2,  2,2}}
route[ 4] = { 4,1,turn={11,1,  1,1}}
 
MAINSW    = 3 -- ID of the main switch

-- Configuration of the signals (only required if different from default state for signal 'Tools_LW1_Stabsignal' of set V70NLW10003)
-- Example: Signal BS1_KS1_BRK_MAS_oM2_4 requires 1: GREEN, 2: RED
MAINON    = 1 -- ON state of main switch
MAINOFF   = 2 -- OFF   state of main switch
BLKSIGRED = 1 -- RED   state of block signals
BLKSIGGRN = 2 -- GREEN state of block signals
MEMSIGRED = 1 -- RED   state of memory signals
MEMSIGGRN = 2 -- GREEN state of memory signals

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