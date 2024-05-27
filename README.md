# PaintBFS

An FPGA paint program with the ability to find the shortest path.

## Description
This program allows user to use a mouse and draw a 8 by 8 pixel with support up to 61 colors on a 512 by 480 screen. To change color, either use the reserved color's key code or press `Enter` to cycle through the various colors. User can also use the reserved color to draw a starting and ending point on the screen, for which the user can run it through the press of a button to draw the shortest path between the two pixels. If found, the shortest path will be drawn on the screen with a light-blue tint.

Further description can be found in `PaintBFS_Report.pdf`.

## How to Use
The code has already been compiled. One only need to program it to the FPGA, and run the software code provided in the folder `software` to provide keyboard support. Note that since the NIOS II processor is used, then this program is limited to only Intel's Altera FPGA only.

## Controls
### Mouse controls
1. Left mouse button: Draw the selected color.
2. Right mouse button: Erase colors.
### Keyboard controls
1. `1` button: Draw the starting point.
2. `2` button: Draw the ending point.
3. `Enter`: Cycle to the next color (shown on the hex display).
### Button Controls
1. `KEY[1]`: Start the path-finding algorithm.

## Limitations
After drawing and path-finding, there is no way to reset the `visited` array and the previous node array (used for the path-finding algorithm). The only way to reset is to reprogram the FPGA.

## Why do you use BFS to find the Shortest Path?
BFS is used here since the distance between each pixel is the same. Dijkstra Algorithm actually converge to BFS if the weight of the nodes are all equal in distance. Hence, it is still correct to mention that the path-finding algorithm used in this program will still lead to the shortest path.
