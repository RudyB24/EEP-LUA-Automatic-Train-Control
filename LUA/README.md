# Lua files

This folder `LUA`contains an optimized module `blockControl` and the corresponding Lua files for the demo layouts.

The module has following optimizations compared with the original version which you still can find in folder `EEP`:

- Modularization: The Lua scripts of a layouts now only contain the data and call the module using a `require` statement.
- Automatic 'find train' mode to assign trains to blocks after starting or after reloading the Lua script. (This replaces the PLACE_TRAIN mode.)
- Because of this 'find train' mode you can save the layout at any time (assuming that all trains are currently located in different block of are traveling to different blocks).
- You do not need to enter data about trains which can go everywhere and do not have their own train signal (but it's still recommended to do it). Such trains are identified during 'find mode'.
- You can define optional destinations blocks for routes to avoid specific lockdown situations. You find an example about this in demo layout 5.
- Tipp texts on signals show the status (free / reserved / occupied) of blocks. You switch the visibility of these tipp texts using the main switch.
- No use of data slots anymore.
