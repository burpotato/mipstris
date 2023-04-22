# mipstris
### A mostly complete version of tetris, built in MIPS.
This program runs a (mostly faithful) rendition of the game TETRIS in the MIPS **Bitmap Display**, controlled by the **Keyboard and Display MMIO Simulator.**

## Gameplay
This game is a verision of Tetris, although with a few functionalities removed.
In this game, blocks fall from the top of the screen in a 10x26 grid. When a block cannot move down any further, that block is **placed**. Players try to move the blocks to create **lines** - a row in the grid in which all 10 spaces are filled. Each line completed contributes to your score, which is shown underneath the grid. If a block touches the top of the screen, the game ends.

Players can move the block **left, right and down** but **cannot move the block up**. They can also rotate the block in either direction, and "**hold**" a block - save a block, which can be swapped out for another block later. Holding can only be done once before a block must be placed.

The game speeds up over time, based on the amount of lines cleared, maxing out after 22 lines are cleared. 
## Differences from actual Tetris
There were some features of Tetris that I was unable to implement. These are
- **Rotation forgiveness**
  - In the official game, rotating a block against a wall or the floor would move the block slightly to allow for the rotation. I instead disallowed such rotations.
  - Related to this, the mechanic of "**t-spins**" are also not in this version of the game
- **Score**
  - Partially because t-spins are such a large part of scoring in the originl game, the scoring system has also been simplified, just counting lines, instead of putting more score value on a 4-line clear or consecutive clears.
- **Levels**
  - In Tetris, the speed corresponds to your level, which is increased by different factors. This has also been simplified.
  

## Starting the game
1. Open the file [mipstris.asm](/mipstris.asm) in MARS or MARS+.
2. Navigate to the **Tools** section in the toolbar, and open both the **Bitmap Display** and the **Keyboard and Display MMIO Simulator.**
3. Change the settings of **Bitmap Display** to match the following:

- Unit Width in Pixels: **16**
- Unit Height in Pixels: **16**
- Display Width in Pixels: **256**
- Display Height in Pixels: **512**
- Base Address For Display: **0x10008000 ($gp)**

  *Resize as needed after settings are changed.*

4. Connect both the Bitmap Display and the Keyboard and Display MMIO Simulator to MIPS with the button in the bottom left of each window.
  
  **Your Bitmap Display and Keyboard and Display MMIO Simulator should now look like these images.**
![game setup](/images/gamesetup.png)
  *The window sizes do not matter, so long as the full bitmap display is visible, and the KEYBOARD input box is visible.*
  
5. Assemble and run the file using the buttons in the toolbar.
6. The game should start immediately - get ready!
## Controls
- Move current block using `j`,`k`,`l`
- Rotate the block using `i` and `z`
- Hold a block using `c`
- Slam a block using `space` 
- Quit early using `q`

## Pseudocode
