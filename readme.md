# Digital Hangman Game Using FPGA

This repository holds the project for a digital hangman game using Digilent's Cora Z7 FPGA and various peripherals. Below is a detailed outline of the hardware and software aspects of the system:

## Parts List

1. Digilent's Cora Z7
2. 2-line/16 character I2C LCD display module
3. Sparkfun 7-segment display (with I2C)
4. FTDI USB to UART 5V/3.3V adapter
5. PS/2 keyboard
6. PS/2 socket

## System Design

### Hardware Design

#### PS2 Keyboard Connection

- Connect the PS2 keyboard to PMOD port JA on the Cora Z7 board.
- Implement logic for recognizing English alphabet keys (A-Z).

#### LCD Panel Connection

- Connect the LCD panel to PMOD port JB on the Cora Z7 board.
- Upon power-up, initialize the LCD to display a single cursor (underline) at the left side of the screen.

#### USB to UART Adapter

- Use a USB to UART adapter for communication with the remote PC.
- Set the serial port parameters to a minimum baud rate of 9600, parity none, data bits 8, and stop bits 1.

#### 7-Segment Display

- Connect a 7-segment display to PMOD port JB to indicate the remaining guesses.

### Software Design

#### PC Software

- **Language Options**: C++, C#, Python, JAVA, or any language. (Javascript and HTML/CSS was chosen for this project).
- **GUI**: Create a GUI to display the game's status and an image of a hangman's noose.
- **Word File**: Read a text file containing 50 words with variable lengths (not exceeding 16 letters per word).

#### Game Initialization

- Display "New Game?" on the GUI and LCD.
- Wait for the player to press "Y" on the PS2 keyboard to start a new game.

#### Word Selection

- Randomly select a word from the text file.
- Display the positions of each letter using underscores on the LCD (left-justified).

#### Letter Guessing

- Allow the player to guess a letter using the PS2 keyboard.
- Display correct guesses in the word on the LCD.
- Update the hangman image and show the remaining guesses on the 7-segment display for incorrect guesses.

#### Game Outcome

- **Success**: Display a congratulatory message on the LCD - “Well done! You have solved N puzzles out of M”.
- **Failure**: Show the correct word and a message indicating the number of puzzles solved - “Sorry! The correct word was XXXXX. You have solved N puzzles out of M”.
  - Since these messages have more than 20 letters and spaces, they should appear at the right edge of the LCD display and scroll across the screen at a rate appropriate for reading the message.
- The system should then display: “New Game?”.
- The player can always request a new puzzle by typing “Y” unless all of the words from the text file have been used up.
- The player should be able to end the game by typing the letter “N”.
- The LCD should display the final message when the game ends: “GAME OVER”.

#### Score Tracking

- Keep track of the number of puzzles solved.
- Display the final score on the LCD after the game ends.

#### Game Over

- Display the final score ("X correct out of Y") on the LCD.
- After a short duration, show "GAME OVER" on the LCD.

## Note

Please take a look at the project concept diagram included in the repository for an idea of how each component connects.
