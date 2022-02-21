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
--           Train name    Train signal (optional)
train[1] = {name="Steam", onoff=14, }
train[2] = {name="Blue",  onoff=4,  }

-- Allowed blocks per train including optional stay time within blocks in seconds
-- You can and should defined allowed blocks for all named trains.
-- More trains are detected automatically, however, these trains can go everywhere.
allowed = {}
--     block  1, 2, 3, 4, 5, 6
allowed[1]= { 1, 1, 0, 0, 0, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
allowed[2]= { 0, 0, 1, 1, 1, 0}

twowayblk = { 0, 3, 2, 0, 0, 0} -- Blocks which are used in both directions. Enter 0 or related block number
blocksig  = { 8,18, 9,19,10,13} -- Block signals
memsig    = { 5, 6, 7,15,20,21} -- Corresponding memory signal per block

-- Configure possible routes between blocks here
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

-- Configuration of the signals (only required if different from default state for signal 'Tools_LW1_Stabsignal' of set V70NLW10003)
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

-- Optional: Start automatically after finding all known train 
-- Only do this if you have defined all trains in tables 'train' and 'allowed'.
-- If you have more trains, you have to wait until all trains are detected and start manually. 
blockControl.start(true)	-- Start main switch and all trains (use 'false' if the train signals should not get touched)

function EEPMain()
	blockControl.run()
	return 1
end 