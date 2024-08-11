# Palm Tree

Palm Tree is a project that utilizes a sequencer module to control and manipulate musical patterns on a grid-based interface. The project is built on the Lua programming language and runs on the norns platform, which is a music-focused computational device. The sequencer allows for dynamic interaction with musical sequences, enabling users to load, modify, and save rhythmic patterns. It integrates with physical grid controllers and provides visual feedback through an LED matrix. The project aims to provide musicians and enthusiasts with a tool to explore rhythmic creativity in a hands-on and intuitive manner.

## File Structure

.
├── README.md
├── audio
│   └── \_.wav
├── lib
│   ├── interface.lua
│   ├── screen.lua
│   └── sequencer.lua
├── machine.lua
└── songs
└── \_.yaml

- `audio` directory contains many wav files that can be played back.
- `lib` directory contains the code for the interface and sequencer.
- `songs` directory contains many yaml files that define the songs for the sequencer.
