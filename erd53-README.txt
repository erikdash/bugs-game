To keep track of the events in my game (bugs, phaser blasts, bursts) I used a curcular
queue with two pointers stored in registers ($s6 at front, $s7 at end). The queue iterates
through a for loop from 0 to n (with n being the number of events in the queue. This was
incremented everytime an event was spawned). The loop would load the event from $s6, move
the bug/phaser blast/burst and put it back into the queue at an incremented $s7, then 
$s6 was incremented. If the item was removed during the process, $s6 is just incremented
without the event being added back to the queue at $s7. 

Each time the for loop
iterates, a counter is incremented by 1. If the counter is equal to the number of events,
the for loop is exited, and the game loops back to the "main loop" which checks for
key presses, then checks the time (to see if >= 200 milliseconds have passed, and it is ok
to iterate through the queue again, and also if >= 120000 milliseconds (2 minutes) have
passed and the game needs to be ended.

To spawn bugs, I generated a random number between 0 and 10, and if that number was 3 or 4,
3 bugs were spawned at random x coordinates in the top row, and added to the queue. The queue
is then iterated through again. And the loop continues.

Issues:
-The game seems to run faster when there is less in the queue, and slower as the queue fills up.
-If there are only a few bugs on the screen (2-3), they will quickly move to the bottom and 
new bugs will get stuck at the top of the screen for a few cycles (this is very rare).
Sometimes the game will end, without errors, but won't print the score when this happens.
Scoring works correctly when the game is exited normally.
-Occasionally, when a burst needs to be removed, some if it's LEDs won't get turned off
-Occasionally a burst will hit an edge of the window and cause an out of bounds error (very 
rare)