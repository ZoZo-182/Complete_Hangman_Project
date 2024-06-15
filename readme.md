# Digital Hangman Game with FPGA and PS/2 Keyboard

This repository holds the project for a digital hangman game using a PS2 keyboard and FPGA. The project is divided into two main components: hardware and software.

## Hardware Side

The hardware side involves:
- Integrating the I2C LCD, PS2 keyboard, and UART communication.
- Sending and receiving data between the FPGA and the host computer.
  - Sending characters pressed on the PS2 keyboard to the host computer.
  - Receiving game status and remaining guesses from the host computer to display on the LCD and 7-segment display.

## Software Side

The software side involves:
- A host computer that sends and receives data through a serial port connected via the SparkFun BOB-13262 UART module.
- Receiving data from the PS2 keyboard and sending game status, remaining guesses, and other information.
- The host computer program was developed using JavaScript, HTML, and CSS.

## FPGA and Development

- FPGA used: Digilent Cora Z7-10
- Coded using VHDL

## System Capabilities

The system can play a GUI-based Hangman game with the following features:
- Inputs are taken by the FPGA via a PS/2 keyboard.
- The FPGA decodes the PS/2 scan code into ASCII code and sends it to the host computer using a UART connection.
- The host computer handles the internal logic for the Hangman game, including:
  - Selection of COM port, baud rate, and number of allowable bad guesses.
  - Incorrect/Correct letter detection.
  - Selection of a random "key" word from a comprehensive list of over 80,000 English words.
  - Display of the word-in-progress and incorrect letters, with a gradual appearance of the "hanged man".
  - Background play of royalty-free music.

## Game State Updates

The host computer continually updates an I2C LCD connected to the FPGA with the current state of the game, including:
- Progress on the word being guessed.
- Running score after each game.
- Selection of a new game.
- Game status.

## Note

Please take a look at the project concept diagram included in the repository for an idea of how each component connects.