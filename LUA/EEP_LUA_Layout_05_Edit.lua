-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Ruud Boer, January 2022
-- EEP Lua code to automatically drive trains from block to block.
-- The user only has to define the layout by configuring some tables and variables
-- There's no need to write any LUA code, the code uses the data in the tables and variables.
--
-- Configuration for Demo Layout 05
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Find a solution to use 'via' blocks'.
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- To place trains, change the code to PLACE_TRAINS=1, reload, 
-- place the trains and fill the initial position of the train in the trains[t] table,
-- and finally set PLACE_TRAINS=0 and reload.           
PLACE_TRAINS = 0
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Below configuration is for the RB31 layout
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

train = {}
--          Train name             Train signal       Initial position of the train
train[1] = {name="Steam CCW",      onoff=9,  route=0, block=19}
train[2] = {name="Orange CCW",     onoff=72, route=0, block=16}
train[3] = {name="Blue CW",        onoff=77, route=0, block=3}
train[4] = {name="Cream CW",       onoff=78, route=0, block=24}
train[5] = {name="Shuttle Red",    onoff=79, route=0, block=13}
train[6] = {name="Shuttle Yellow", onoff=92, route=0, block=9}
train[7] = {name="Shuttle Steam",  onoff=93, route=0, block=8}

allowed = {} -- Allowed blocks per train including optional stay time within blocks in seconds
--      block  1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
allowed[1]= {35,25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0} -- 0 not allowed, 1 allowed, >1 stop time (add the drive time from sensor to signal)
allowed[2]= {35,25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0}
allowed[3]= { 0, 0,40,30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0}
allowed[4]= { 0, 0,25,30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0}
allowed[5]= { 0, 1, 1, 1,28,28,28,28,28,28,28,28,28, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1}
allowed[6]= { 0, 1, 1, 1,28,28,28,28,28,28,28,28,28, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1}
allowed[7]= { 0, 1, 1, 1,28,28,28,28,28,28,28,28,28, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1}

twowayblk = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,18,17, 0, 0,22,21, 0, 0, 0,27,26} -- 0 or related block number
blocksig  = {19,25,26,27,28,29,30,35,36,44,43,46,45,37,39,41,82,81,73,34,33,32,42,40,31,74,38} -- block signals
memsig    = {47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,75,76} -- memory signals

-- Configure possible routes between blocks here
-- route[n] = {from block, to block, via={block,...}, turn={ID,state,...}} state: 1=main, 2=branch
route = {}
route[ 1] = { 1,14,turn={3,1}}
route[ 2] = { 2,14,turn={3,2}}
route[ 3] = { 3,21,turn={1,2}}
route[ 4] = { 4,20,turn={}}
route[ 5] = { 5,26,turn={11,1}}
route[ 6] = { 6,26,turn={13,1, 11,2}}
route[ 7] = { 7,26,turn={13,2, 11,2}}
route[ 8] = { 8,15,turn={ 8,2,  2,2,  4,2,  5,1}}
route[ 9] = { 9,15,turn={ 8,1,  2,2,  4,2,  5,1}}
route[10] = {10,24,turn={15,1, 12,2, 14,1}}
route[11] = {11,24,turn={15,2, 12,2, 14,1}}
route[12] = {12,22,turn={18,1, 22,1, 21,2, 23,2}}
route[13] = {12,27,turn={18,1, 22,1, 21,1,  7,2}}
route[14] = {13,22,turn={18,2, 22,1, 21,2, 23,2}}
route[15] = {13,27,turn={18,2, 22,1, 21,1,  7,2}}
route[16] = {14,15,turn={ 5,2}}
route[17] = {15,10,turn={24,1, 14,2, 12,2, 15,1}}
route[18] = {15,11,turn={24,1, 14,2, 12,2, 15,2}}
route[19] = {15,16,turn={24,2}}
route[20] = {16,17,turn={16,1}}
route[21] = {17,19,turn={20,2}}
route[22] = {17,22,turn={20,1, 17,2, 23,1}}
route[23] = {18,23,turn={16,2}}
route[24] = {19, 1,turn={}}
route[25] = {20,12,turn={ 7,1, 21,1, 22,1, 18,1}}
route[26] = {20,13,turn={ 7,1, 21,1, 22,1, 18,2}}
route[27] = {20,18,turn={ 7,1, 21,1, 22,2, 17,1, 20,1}}
route[28] = {21,12,turn={23,2, 21,2, 22,1, 18,1}}
route[29] = {21,13,turn={23,2, 21,2, 22,1, 18,2}}
route[30] = {21,18,turn={23,1, 17,2, 20,1}}
route[31] = {22, 2,turn={ 1,1}}
route[32] = {23,24,turn={12,1, 14,1}}
route[33] = {24, 8,turn={ 4,1,  2,2,  8,2}}
route[34] = {24, 9,turn={ 4,1,  2,2,  8,1}}
route[35] = {24,25,turn={ 4,1,  2,1}}
route[36] = {25, 3,turn={ 6,1}}
route[37] = {25, 4,turn={ 6,2}}
route[38] = {26,12,turn={ 7,2, 21,1, 22,1, 18,1}}
route[39] = {26,13,turn={ 7,2, 21,1, 22,1, 18,2}}
route[40] = {26,18,turn={ 7,2, 21,1, 22,2, 17,1, 20,1}}
route[41] = {27, 5,turn={11,1}}
route[42] = {27, 6,turn={11,2, 13,2}}
route[43] = {27, 7,turn={11,2, 13,1}}
 
MAINSW    = 80 -- ID of the main switch

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