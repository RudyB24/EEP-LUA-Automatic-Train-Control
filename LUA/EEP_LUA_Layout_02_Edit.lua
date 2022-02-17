-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
--
-- Configuration for Demo Layout 02
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- To place trains, change the code to PLACE_TRAINS=1, reload, 
-- place the trains and fill the initial position of the train in the trains[t] table,
-- and finally set PLACE_TRAINS=0 and reload.           
PLACE_TRAINS = 0
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

train = {}
--          Train name    Train signal       Initial position of the train
train[1] = {name="Steam", onoff=14, route=0, block=4}
train[2] = {name="Blue",  onoff=4,  route=0, block=3}

allowed = {} -- Allowed blocks per train including optional stay time within blocks in seconds
--     block  1, 2, 3, 4
allowed[1]= {15, 0, 0, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
allowed[2]= { 0, 1, 1, 0}

twowayblk = { 0, 0, 0, 0} -- 0 or related block number
blocksig  = { 8, 9,10,13} -- block signals
memsig    = { 5, 6, 7,15} -- memory signals

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

function EEPMain()
	blockControl.run()
	return 1
end 