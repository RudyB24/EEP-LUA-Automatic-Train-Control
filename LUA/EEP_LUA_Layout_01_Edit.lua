-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Rudy Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
--
-- Configuration for Demo Layout 01
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- To place trains, change the code to PLACE_TRAINS=1, reload, 
-- place the trains and fill the initial position of the train in the trains[t] table,
-- and finally set PLACE_TRAINS=0 and reload.           
PLACE_TRAINS = 0
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

train = {}
--           Train name    Train signal      Initial position of the train
train[1] = { name="Steam", onoff=4, route=0, block=3}

allowed = {} -- Allowed blocks per train including optional stay time within blocks in seconds
--     block  1, 2, 3
allowed[1]= {15, 1, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)

twowayblk = { 0, 0, 0} -- 0 or related block number
blocksig  = { 8, 9,10} -- block signals
memsig    = { 5, 6, 7} -- memory signals


route = {}
-- route[n] = {from block, to block, turn={ID,state,...}} state: 1=main, 2=branch
route[ 1] = { 1,3,turn={2,1}}
route[ 2] = { 2,3,turn={2,2}}
route[ 3] = { 3,1,turn={1,1}}
route[ 4] = { 3,2,turn={1,2}}
 
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

function EEPMain()
	blockControl.run()
	return 1
end 