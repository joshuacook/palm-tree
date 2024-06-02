# Palm Tree

Palm Tree is a project that utilizes a sequencer module to control and manipulate musical patterns on a grid-based interface. The project is built on the Lua programming language and runs on the norns platform, which is a music-focused computational device. The sequencer allows for dynamic interaction with musical sequences, enabling users to load, modify, and save rhythmic patterns. It integrates with physical grid controllers and provides visual feedback through an LED matrix. The project aims to provide musicians and enthusiasts with a tool to explore rhythmic creativity in a hands-on and intuitive manner.

## Regression Testing

1. Load Song 999
2. Page 1
    - Examine Metadata
        - Song: Diagnostic
        - BPM: 108
        - Output Level: -2.00
        - Grid: 1
        - Active: 1
    - set BPM to 100
    - set Output Level to 3.00
    - Toggle Page
    - Edit Pattern
    - Stop Song
    - Switch Pattern
    - Edit Pattern
3. Page 2
    - change sample on each pattern
4. Page 3
    - save song
    - load song



1. Load 999
2. Diagnostic 0: load
  - run diagnostic 0 in matron
4. Diagnostic 1: Page 1
  - set bpm to 100
  - set output level to 0.00
  - play song
     - listen
  - toggle page
  - edit pattern
     - listen
  - run diagnostic 1 in matron
5. Diagnostic 2: Page 1
  - stop song
  - switch pattern 
  - run diagnostic 2
  - edit pattern
  - run diagnostic 3
  - switch pattern
6. Diagnostic 3: Page 2
  - change each sample
  - play song (make k2 toggle play on page 2, k3 toggle grid page)
  - listen
  - stop song
  - run diagnostic 3
7. Page 3
  - save song 
  - run diagnostic 4
  - load song
  - run diagnostic 5
  - reset song