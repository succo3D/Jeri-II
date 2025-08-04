# Jeri II: Tower's End
![jeri2_1](https://github.com/user-attachments/assets/fc40a908-64bb-404b-8cfd-5059343bcc32)

The source code for my PICO-8 game, Jeri II, as well as the game's level editor!

[You can play the game on Newgrounds!](https://www.newgrounds.com/portal/view/983235)

[Or check it out on the PICO-8 BBS!](https://www.lexaloffle.com/bbs/?tid=150728)

## Included Files
You need PICO-8 to run these p8 files. [You can buy it here.](https://www.lexaloffle.com/pico-8.php)

*jeri2.p8* is the game itself, and *jeri2edit.p8* is the level editor.

*jeri2_enemy_data.p8l* is an extra lua file that contains a packed table with the enemy placements for each level, as well as the most recently edited level number.

The file paths are hardcoded so it's expected you keep these 3 files together.

## How To Use the Editor
![jeri2_2](https://github.com/user-attachments/assets/ff58d9c5-6b08-420e-ba8b-3517ba79633c)
***
The first thing you must do is set the "CHEAT" variable in *jeri2.p8* to TRUE. This will make the game skip the title screen and load the most recently edited level. Additionally, you can seek through levels using the arrow keys. Just remember to turn CHEAT back to FALSE if you want the game to start normally.

Next, open and run *jeri2edit.p8* in a separate window. This is where you'll do all your level editing. Here's a rundown of the controls.

### General Controls
- Left Mouse  - Place Tile/Enemy
- Right Mouse - Delete Tile/Enemy
- S           - Save Changes
- D           - Go To Previous Level
- F           - Go To Next Level
- Tab         - Switch Between Tile/Enemy Mode

> Saving saves all changes since you opened the editor. If you switch to another level after editing it, changes will not be discarded.

> Tilemap changes are saved directly to *jeri2.p8* 

### Tile Edit Mode
![jeri2edit_0](https://github.com/user-attachments/assets/f5ddbf89-871f-484a-b7d8-7ab0ba680ba4)
- Z/X - Change Tile Page

Click on a tile in the hotbar to select it. Click and drag to place that tile. Right click and drag to delete tiles.

**NOTE:** A Jeri (the blue/red arrow) and Door (square with a star on it) must be placed in a level or the game will get mad! (crash)

### Enemy Edit Mode
![jeri2edit_1](https://github.com/user-attachments/assets/f3beaa18-6627-48ed-99de-63bb8df35675)
- Z/X - Change Enemy's Facing Angle

Click on an enemy in the hotbar to select it. Click to place an enemy in the level, and right click to delete enemies. The white lines on certain enemies denote which way they will move when the level starts. Change the direction by pressing Z or X.

### Testing Your Edits
Simply save your changes by pressing S in *jeri2edit.p8*, and then click over to your window with *jeri2.p8* and Run the game (CTRL+R). It will open into the level you're editing and let you playtest.

You will always start as Red, but if you want to try a Blue start, switch to Blue and press Down Arrow to restart the level.

## Closing Thoughts
Thanks for checking this out! I hope this can inspire you to make your own cool game. And if you end up making a Jeri II rom hack, make sure to let me know!! :D
