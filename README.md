# EEP-LUA-Automatic-Train-Control
November 2021 I moved to a new house. Besides the many pluses the new home offers there’s one little issue: there’s no room for my model railway anymore. EEP came to the rescue … I can still design and ‘build’ model railways and on my 4k screen they are fun to tinker with.

My old model railway was computer controlled with a program called Traincontroller. It allows for automatic train traffic whereby it takes care of switching turnouts and signals and accelerating and decelerating the trains.

It struck me that EEP has no automatic train control built in … or at least not in a way that is user friendly. There is however LUA, which allows us to write code to carry out these tasks. I wondered if it would be possible to write a LUA program that controls automatic train traffic in EEP, like Traincontroller does with a real model railway layout.

I set myself the following goals:
 - Trains should automatically drive from block to block
 - It should be possible to specify which trains are allowed in which blocks
 - It should be possible to define stop times, per train per block
 - It should be possible to start / stop individual trains
 - It should work for any (model) railway layout without the need to (re)write LUA code 
 - The layout is defined solely by entering data on trains, signals, turnouts and routes

The result of this EEP LUA Automatic Traffic Control Project can be downloaded here.

An explanation on how it works and on how to fill the LUA tables with data that define your own layout goes with it:
 - English: EEP_LUA_Automatic+Train_Control.pdf
 - Deutsch: EEP_LUA_Automatische_Zugsteuerung.pdf

The EEP folder contains 5 working EEP demo layouts with the LUA code and the layout definition included. 

The LUA folder contains 5 files with the LUA code to make it easier to edit the code in say Notepad++.

The TC folder contains the 5 layouts in Traincontroller, for those who might like to tinker with TC. Free demo version: https://www.freiwald.com/pages/download.htm

The Images folder contains screenshots of the 5 layouts in EEP, SCARM and Traincontroller.

The SCARM folder contains 2 SCARM files, one with layouts 1-4 (open menu View > Layers to switch layers) and one with layout 5, for those who might like to tinker with SCARM. Free demo version: https://www.scarm.info/index.php

A series of YouTube videos in the making.

Any questions, comments and ideas are welcome. In the meantime … have fun.

