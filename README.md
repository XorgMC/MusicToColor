# MusicToColor

Changes made by me, XorgMC:
- Changed variables to uint16_t to support more than 256 LEDs
- Converted Delphi program to FreePascal (using Lazarus)
- Translated remaining russian comments in program
- Some new programs

ToDo:
- Convert PC program to Python (WIP/POC?) OR make multi-platform (use uos for audio capture)
- Make program remote-controllable
- Cleanup everything


Basic principles of the color music program:

- Band-pass filtering of sound and control of the choice of color music programs is performed by the "CMU.EXE" program for the PC.

- The formation of color music programs is performed by Arduino modules.

- The LED strip is controlled by the Arduino module in accordance with the selected program.

- Any software player can be used to play music, such as WinAmp, AIMP, ITUNES, Windows Media, etc. or a hardware player with a line output.


Collection of color music.

  To assemble a minimal DMU kit, with a direct connection to a PC USB, you only need an LED strip with a WS2812B, an arduino nano, ESP32 (or similar), three conductors and a mini USB cable to connect the Arduino board to one of the PC USB ports. In this version, the number of active LEDs is limited to 20, one for each color bar of the CMU program. The restriction is introduced to prevent overloading the USB port. You can change the number in the arduino sketch. Be aware of the limited RAM - an arduino nano/uno can drive about 480-500 LEDs, while I didn't reach a limit on ESP32.
  
  A simple switching circuit with a large number of LEDs is shown in the figure "sch.jpg". The number of LEDs in this switching scheme is limited by the power of your power source, ~~but cannot exceed 256~~ cannot exceed 65535, I think (all uint8_t variables should have been converted to uint16_t).
  
  To assemble the wireless version, you will additionally need one more Arduino board, two nRF24L01 radio modules with adapter boards, a 5V power supply for the power corresponding to your tape. Both nRF24L01 modules connect to Arduino boards in the same way. Connection is carried out according to a typical scheme to digital outputs D9, D10, D11, D12, D13 or others with a corresponding change in the configuration headers in the sketches. Typical wiring diagrams for nRF24L01 are available on the Internet. The LED strip control input Din (Din on the tape) is connected to the digital output D2 of the arduino board and can be changed by making appropriate changes to the sketch.


User's manual.

  1. The program "CMU.EXE" does not require special installation. Create a folder with any name that you associate with the color music program and copy the "CMU.EXE" file into it. The program is ready to run.
  2. Install the Arduino IDE. Download and install the Adafruit_Neopixel, RF24 and IRremote libraries. Installing libraries in the Arduino IDE is described on the Internet and is not difficult.
  3. Make changes to the sketches for your feed and connection option.
  
      3.1 Set the number of LEDs in your strip
      
              #define stripLed 120 // number of LEDs in the strip
              
      3.2 Set the pin number to which the LED strip is connected
      
              #define stripPin 2 // LED strip control output
              
      3.3 Set the pin numbers to which the nRF24L01 module is connected
      
              RF24 radio(9, 10); // create a radio object to work with the RF24 library, specifying the pin numbers nRF24L01+ (CE, CSN)
              
  4. We assemble the project and upload it to the board or boards, depending on the option.
  5. Connect the tape, run the program.
  6. Setting up the program.
  
      6.1 Set the serial COM port to which the Arduino is connected.
      
      6.2 Select an audio device from the output of which the audio stream will be fed to the input of the color music program. To receive an audio stream from a software player, use the "Audio Source Selection Guide" from the audioConnect.doc file.
      
      6.3 Select one of the color-music or dynamic visualization programs.


Links to video of the work of color music programs

https://youtu.be/sFQip-zjMoY

https://youtu.be/H6T8ywU3Iu8

https://youtu.be/h9zbtLpKtf0
  

---

FFT from the Internet, the author is not specified. You can find this version of FFT in C++.
I checked the correctness of the test signal.