const hangmanImage = document.querySelector(".hangman-box img");
const wordDisplay = document.querySelector(".word-display");
const guessesText = document.querySelector(".guesses-text");
const keyboardDiv = document.querySelector(".keyboard");
const gameModel = document.querySelector(".game-model");
const playAgainBtn = document.querySelector(".play-again");

let interruptScrolling = false;

let letterFound = false; // Variable to track if the clicked letter is found in the word
let currentWord, correctLetters, wrongGuessCount, remainingGuessCount, hiddenWord, isVictory, gameOverTimeout, displayedWord;
const maxGuesses = 6;
let wordsUsed = [];
let gameReset = false; // Variable to track if the game is reset

const dataToSend = [];
const currentWordLength = currentWord ? currentWord.length : 0; // Calculate the length of the currentWord
const numSpaces = Math.max(16 - currentWordLength, 0); // Calculate the number of spaces needed to fill up to 16 characters
const spaces = Array(numSpaces).fill(' ').join('');

// Concatenate the hidden word with spaces to make up 16 characters
const fullword = (hiddenWord + spaces).slice(0, 16); // Ensure the total length is 16 characters
const firstline = spaces.slice(0, 16);

const resetGame = async () => {
    correctLetters = [];
    wrongGuessCount = 0;
    remainingGuessCount = 6;
    hangmanImage.src = `hangman${wrongGuessCount}.png`
    guessesText.innerText = `${wrongGuessCount} / ${maxGuesses}`;
    keyboardDiv.querySelectorAll("button").forEach(btn => btn.disabled = false);
    wordDisplay.innerHTML = currentWord.split("").map(() => `<li class="letter"></li>`).join("");
    gameModel.classList.remove("show");

    // Initialize hiddenWord with underscores
    hiddenWord = currentWord.replace(/[a-zA-Z]/g, '_');
    displayedWord = hiddenWord; // Initialize displayedWord with hiddenWord 

    const fullword = (hiddenWord + spaces).slice(0, 16);
    await WritetoSerial(firstline + fullword + remainingGuessCount);

}

// Function to read words from text file (async because reading from file takes some time. js can execute other code while waiting for this to finish)
async function ReadFromFileandSelectRandomWord() {
    try {
        const response = await fetch('EnglishWords.txt');
        const text = await response.text();
        const words = text.split('\n');

        const randomWord = words[Math.floor(Math.random() * words.length)];
        currentWord = randomWord;
        resetGame();
    } catch (error) {
        console.error("Error reading words from file.", error);
    }
}

const gameOver = async (victory) => {
    isVictory = victory;

    // Increment number of puzzles solved if the player wins and chooses to continue
    if (isVictory) {
        wordsUsed.push(currentWord);
    }

    // Reset the count if the player starts a new game after losing
    if (!isVictory) {
        wordsUsed = [];
    }

    // after 300ms of game completion show model with relevant details
    setTimeout(async () => {
        const modelText = isVictory ? `Well done! You have solved ${wordsUsed.length} puzzles out of 1000` : `Sorry! The correct word was: ${currentWord}. You have solved ${wordsUsed.length} puzzles out of 1000`;
        gameModel.querySelector("img").src = `images/${isVictory ? 'victory' : 'lost'}.png`;
        gameModel.querySelector("h4").innerText = `${isVictory ? 'Congrats!' : 'Game Over!'}`;
        gameModel.querySelector("p").innerHTML = `${modelText} <b></b><b></b>`;
        gameModel.classList.add("show");

        // Reset interrupt flag before calling Scrolling
        interruptScrolling = false;

        // Sending game outcome logic to the serial port
        await Scrolling(modelText);

    }, 300);
}

const initGame = async (button, clickedLetter) => {
    interruptScrolling = false; // Reset interrupt flag before starting the game
    // Check if remainingGuessCount is undefined to determine if the game just started
    if (remainingGuessCount === undefined) {
        // If it's the start of the game, send the initial values to the serial port
        await WritetoSerial(firstline + fullword + maxGuesses);
    }

    // Variable to track if the clicked letter is found in the word
    let letterFound = false;

    // If the clicked letter is found in the currentWord, update the display
    if (currentWord.includes(clickedLetter)) {
        [...currentWord].forEach((letter, index) => {
            if (letter === clickedLetter) {
                correctLetters.push(letter);
                wordDisplay.querySelectorAll('li')[index].innerText = letter;
                wordDisplay.querySelectorAll('li')[index].classList.add("guessed");
                letterFound = true; // Set the flag to true if the letter is found
            }
        });

        // If the letter is found, reconstruct the displayed word
        if (letterFound) {
            displayedWord = ''; // Initialize displayed word
            [...currentWord].forEach(letter => {
                if (correctLetters.includes(letter)) {
                    displayedWord += letter; // Add correct letters to the displayed word
                } else {
                    displayedWord += '_'; // Add underscores for hidden letters
                }
            });

            // Pad the displayed word with spaces to make it exactly 16 characters long
            const numSpaces = Math.max(16 - displayedWord.length, 0);
            const spacesToAdd = Array(numSpaces).fill(' ').join('');
            const fullword = displayedWord + spacesToAdd;

            // Send updated game state to the serial port
            await WritetoSerial(firstline + fullword + remainingGuessCount);
        }
    } else {
        // If the clicked letter is not found, update wrong guess count
        wrongGuessCount++;
        remainingGuessCount--;
        hangmanImage.src = `hangman${wrongGuessCount}.png`;

        // Pad the displayed word with spaces to make it exactly 16 characters long
        const numSpaces = Math.max(16 - displayedWord.length, 0);
        const spacesToAdd = Array(numSpaces).fill(' ').join('');
        const fullword = displayedWord + spacesToAdd;

        await WritetoSerial(firstline + fullword + remainingGuessCount);
    }

    // Disable the clicked button
    button.disabled = true;

    // Update the guesses text
    guessesText.innerText = `${wrongGuessCount} / ${maxGuesses}`;

    // Check for game over conditions
    if (wrongGuessCount === maxGuesses) return gameOver(false);
    if (correctLetters.length === currentWord.length) return gameOver(true);
}

window.addEventListener('keydown', async function (event) {
    if (gameModel.classList.contains('show') && (event.key.toLowerCase() === 'y')) {
        const key = event.key.toLowerCase();
        if (key === 'y') {
            if (!interruptScrolling) {
                interruptScrolling = true; // Set interruption flag
                await WritetoSerial("New Game? y/n   " + firstline + remainingGuessCount);
            } else {
                playAgainBtn.click();
                gameReset = true;
            }
        } else if (key === 'n') {
            interruptScrolling = true; // Set interruption flag
            gameModel.querySelector("h4").innerText = "GAME OVER!";
            gameModel.querySelector("p").innerText = "";
            const over = "GAME OVER!";
            // Pad the message with spaces to total up to 16 characters
            const padover = over.padEnd(16, ' ');
            // Initialize hiddenWord with underscores
            hiddenWord = currentWord.replace(/[a-zA-Z]/g, '_');
            displayedWord = hiddenWord; // Initialize displayedWord with hiddenWord 

            await WritetoSerial(padover + firstline + remainingGuessCount);
        }
    } else {
        const key = event.key.toLowerCase();
        if (key.match(/[a-z]/)) {
            const correspondingButton = keyboardDiv.querySelector(`button[data-key="${key}"]`);
            if (correspondingButton) {
                correspondingButton.click();
            }
        }
    }
});


async function Scrolling(gameOutcome) {
    /* Actual Scrolling Logic
        Take the first 16 characters of the gameOutcome
        Make sure there is a loop that adds one character at a time (the rest of the gameOutcome string) and then sends that word with the new character added
        this should still add up to 16 characters total because the first character is no longer being sent.
        For Example, send out the first 16 characters fo gaemeOutcome, then after 1 second increment the starting postion of the string gameOutcome by 1
        and then send out the next 16 characters. 
        
    */
    // then 

    // write the 16 characters that are updated every one second (scrolling) + fullword that is updated based off of the player
    // + the reminaing guess count for the player 

    let startIndex = 0; // Starting index for scrolling

    // Define a loop for scrolling
    const scrollLoop = setInterval(async () => {
        if (interruptScrolling) {
            clearInterval(scrollLoop); // Stop the scrolling loop
            interruptScrolling = false; // Reset the interruption flag
            return; // Exit the loop
        }

        const endIndex = Math.min(startIndex + 16, gameOutcome.length); // Calculate end index
        const partialOutcome = gameOutcome.substring(startIndex, endIndex); // Extract partial outcome

        const numSpaces = Math.max(16 - displayedWord.length, 0);
        const spacesToAdd = Array(numSpaces).fill(' ').join('');
        const fullword = displayedWord + spacesToAdd;
        await WritetoSerial(partialOutcome + fullword + remainingGuessCount); // Write partial outcome to serial

        startIndex++; // Increment starting index for next iteration

        // Check for interruption by 'y' or 'n' key press
        if (endIndex === gameOutcome.length) {
            clearInterval(scrollLoop); // Stop the scrolling loop
        }

    }, 1000); // 1-second interval for scrolling

}

//creating keyboard buttons
for (let i = 97; i <= 122; i++) {
    const button = document.createElement("button");
    button.innerText = String.fromCharCode(i);
    button.dataset.key = String.fromCharCode(i);
    keyboardDiv.appendChild(button);
    button.addEventListener("click", e => initGame(e.target, String.fromCharCode(i)));
}

// Function to handle received data from the serial port
async function handleReceivedData(data) {
    const keys = data.trim().split(""); // Split data into individual characters
    for (const key of keys) {
        if (gameModel.classList.contains('show')) {
            // Process 'y' or 'n' key presses only if the game model is showing
            if (key === 'y') {
                if (!interruptScrolling) {
                    interruptScrolling = true; // Set interruption flag
                    await WritetoSerial("New Game? y/n   " + firstline + remainingGuessCount);
                } else {
                    playAgainBtn.click();
                    gameReset = true;
                }
            } else if (key === 'n') {
                interruptScrolling = true; // Set interruption flag
                gameModel.querySelector("h4").innerText = "GAME OVER!";
                gameModel.querySelector("p").innerText = "";
                const over = "GAME OVER!";
                // Pad the message with spaces to total up to 16 characters
                const padover = over.padEnd(16, ' ');
                // Initialize hiddenWord with underscores
                hiddenWord = currentWord.replace(/[a-zA-Z]/g, '_');
                displayedWord = hiddenWord; // Initialize displayedWord with hiddenWord 
                const fullword = (hiddenWord + spaces).slice(0, 16);
                const scoreMessage = `${wordsUsed.length}/1000 correct`;
                await WritetoSerial(padover + scoreMessage + " ".repeat(16 - scoreMessage.length) + remainingGuessCount);
                await new Promise(resolve => setTimeout(resolve, 5000));
                await WritetoSerial(padover + firstline + remainingGuessCount);
                if (key === 'y') {
                    await resetGame();
                }
            }
        } else {
            // Process other key presses only if the game model is not showing
            if (key.match(/[a-z]/)) {
                const correspondingButton = keyboardDiv.querySelector(`button[data-key="${key}"]`);
                if (correspondingButton) {
                    correspondingButton.click();
                }
            }
        }
    }
    console.log("Received data from PS2 keyboard:", data);
}

// Function to connect to serial port
async function connectSerial() {
    try {
        const port = await navigator.serial.requestPort();
        if (!port) {
            throw new Error("Serial port is not available.");
        }

        await port.open({ baudRate: 9600, parity: 'none', dataBits: 8, stopBits: 1 });

        const reader = port.readable.getReader();

        // Modify gameModel class to include "show" by default
        gameModel.classList.add('show');

        // Set initial game model text
        gameModel.querySelector("h4").innerText = `New Game?`;

        // Send "New Game?" prompt to serial port
        await WritetoSerial("New Game?       " + "                " + "0");

        // Continuously read data from the serial port
        while (true) {
            const { value, done } = await reader.read();
            if (done) break;
            const receivedData = new TextDecoder().decode(value);
            handleReceivedData(receivedData);
        }
    } catch (error) {
        console.error("Error accessing serial port:", error);
    }
}

async function WritetoSerial(messages) {
    try {
        const ports = await navigator.serial.getPorts();
        console.log(ports);
        if (!ports || ports.length === 0) {
            throw new Error("No serial ports available.");
        }

        // Select the first available port
        const port = ports[0];

        if (!port.writable) {
            throw new Error("Serial port does not support writing.");
        }

        // Check if the WritableStream is locked
        if (port.writable.locked) {
            throw new Error("WritableStream is locked.");
        }

        // Write data to the serial port
        const writer = port.writable.getWriter();
        const data = new TextEncoder().encode(messages);
        console.log("data length:", data.length);
        await writer.write(data);
        console.log("Data Sent to Port: ", messages);
        await writer.close();

    } catch (error) {
        console.error("Error accessing serial port:", error);
    }
}

async function WritetoSerialButton() {
    message = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEF0";
    WritetoSerial(message);
    console.log("In function");
}


connectSerial();
ReadFromFileandSelectRandomWord();
playAgainBtn.addEventListener("click", ReadFromFileandSelectRandomWord);