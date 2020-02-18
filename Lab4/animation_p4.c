// SW[0]   Mode - 0/stall, 1/poll
// SW[1]   Direction - 0/down, 1/up
// SW[9:7] Colour
// VGA 335 x 209

#include <math.h>

#define LDA_REG (volatile int *)0x00700000
#define SWITCH (volatile int *)0x00750000


int merge(int x, int y);

void main() {
	
	//Set variables and pointers
	int y = 111;
	(volatile int *) MODE = LDA_REG;
	(volatile int *) STATUS = MODE + 0x04;
	(volatile int *) GO = MODE + 0x08;
	(volatile int *) START = MODE + 0x0C;
	(volatile int *) END = MODE + 0x10;
	(volatile int *) COLOUR = MODE + 0x14;
	
	//inf loop drawing lines
	while (1) {
		//update y value
		if (*SWITCH & 0x02) {
			if (y > 0) {
				y--;
			}
			else {
				y = 209;
			}
		}
		else {
			if (y < 209) {
				y++;
			}
			else {
				y = 0;
			}
		}
		
		//draw line
		//set mode
		*MODE = *SWITCH & 0x01;
		
		//set colour
		*COLOUR = *SWITCH >> 7;
		
		//set coords
		*START = merge(0,y);
		*END = merge(335,y);
		
		//if mode = 1 poll
		if (*MODE & 0x01) {
			while (*STATUS & 0x01); //wait untill status clear
		}
		
		//start drawing
		*GO = 0x01;
		
		
		//erase line
		//set mode
		*MODE = *SWITCH & 0x01;
		
		//set colour
		*COLOUR = 0x0000;
		
		//set coords
		*START = merge(0,y);
		*END = merge(335,y);
		
		//if mode = 1 poll
		if (*MODE & 0x01) {
			while (*STATUS & 0x01); //wait untill status clear
		}
		
		//start drawing
		*GO = 0x01;
		
	}
	return;
}



//combine x and y into one integer for register
int merge(int x, int y) {
	return ((y << 9) & 0x01fe00) + (x & 0x01ff);
}
