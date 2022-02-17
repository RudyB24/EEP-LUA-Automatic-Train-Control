-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
--
-- Configuration for Demo Layout 04
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- To place trains, change the code to PLACE_TRAINS=1, reload, 
-- place the trains and fill the initial position of the train in the trains[t] table,
-- and finally set PLACE_TRAINS=0 and reload.           
PLACE_TRAINS = 0
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

train = {}
--          Train name     Train signal       Initial position of the train
train[1] = {name="Steam",  onoff=30, route=0, block=1}
train[2] = {name="Blue",   onoff=14, route=0, block=4}
train[3] = {name="Orange", onoff=4, route=0,  block=7}

allowed = {} -- Allowed blocks per train including optional stay time within blocks in seconds
--     block  1, 2, 3, 4, 5, 6, 7, 8
allowed[1]= {30, 1, 1,30, 1, 1, 1, 1} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
allowed[2]= { 1, 1, 1, 1,20, 1, 1,20}
allowed[3]= {30, 1, 1,30, 1, 1, 1, 1}

twowayblk = { 0, 3, 2, 0, 0, 0, 0, 0} -- 0 or related block number
blocksig  = { 8,18, 9,19,26,10,13,27} -- block signals
memsig    = { 5, 6, 7,15,20,21,28,29} -- memory signals

route = {}
-- route[n] = {from block, to block, turn={ID,state,...}} state: 1=main, 2=branch
route[ 1] = { 1,7,turn={ 2,1, 12,1, 22,2}}
route[ 2] = { 1,8,turn={ 2,1, 12,1, 22,1}}
route[ 3] = { 2,7,turn={17,1,  2,2, 12,1, 22,2}}
route[ 4] = { 2,8,turn={17,1,  2,2, 12,1, 22,1}}
route[ 5] = { 3,5,turn={16,1,  1,2, 11,2, 23,2}}
route[ 6] = { 3,6,turn={16,1,  1,2, 11,2, 23,1}}
route[ 7] = { 4,5,turn={16,2,  1,2, 11,2, 23,2}}
route[ 8] = { 4,6,turn={16,2,  1,2, 11,2, 23,1}}
route[ 9] = { 5,1,turn={23,2, 11,2,  1,1}}
route[10] = { 5,2,turn={23,2, 11,2,  1,2, 16,1}}
route[11] = { 6,3,turn={12,2,  2,2, 17,1}}
route[12] = { 6,4,turn={12,2,  2,2, 17,2}}
route[13] = { 7,1,turn={11,1,  1,1}}
route[14] = { 7,2,turn={11,1,  1,2, 16,1}}
route[15] = { 8,3,turn={22,1, 12,1,  2,2, 17,1}}
route[16] = { 8,4,turn={22,1, 12,1,  2,2, 17,2}}

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