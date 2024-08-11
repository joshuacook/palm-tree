# Palm Tree

Palm Tree is a project that utilizes a sequencer module to control and manipulate musical patterns on a grid-based interface. The project is built on the Lua programming language and runs on the norns platform, which is a music-focused computational device. The sequencer allows for dynamic interaction with musical sequences, enabling users to load, modify, and save rhythmic patterns. It integrates with physical grid controllers and provides visual feedback through an LED matrix. The project aims to provide musicians and enthusiasts with a tool to explore rhythmic creativity in a hands-on and intuitive manner.

## File Structure

```
.
├── README.md
├── audio
│   └── *.wav
├── lib
│   ├── interface.lua
│   ├── screen.lua
│   └── sequencer.lua
├── machine.lua
└── songs
    └── *.yaml
```

- `audio` directory contains many wav files that can be played back.
- `lib` directory contains the code for the interface and sequencer.
- `songs` directory contains many yaml files that define the songs for the sequencer.

## Usage Instructions

### Getting Started

1. Ensure your norns device is set up and connected to a grid controller.
2. Load the Palm Tree project onto your norns.
3. Connect your audio output to hear the sequences.

### Main Interface

The main interface is divided into three pages, which you can navigate using E1 (Encoder 1).

#### Page 1: Main

- **E2**: Adjust BPM
- **E3**: Adjust output level
- **K2**: Toggle play/stop
- **K3**: Switch grid page (1 or 2)

The screen displays:

- Current song title
- BPM
- Output level
- Current grid page
- Active pattern number

#### Page 2: Sampler

- **E2**: Change sample for the selected drum
- **E3**: Select different drum
- **Numpad**: Enter new level for the selected drum (press Enter to confirm)

The screen displays a list of drums with their assigned samples and levels.

#### Page 3: Load and Save

- **E2**: Navigate through available song files
- **K2**: Load selected song
- **K3**: Save current song

#### Page 4: Parameters

This page allows you to adjust global parameters affecting the sound output.

- E2: Select parameter
- E3: Adjust selected parameter value

Available parameters:

- Fade Time: Affects the fade in/out time of samples
- Attack Time: Adjusts the attack time of samples

### Grid Interface

The grid represents a 16-step sequence for up to 16 drums (8 per page).

- Press a grid button to cycle through step values (off -> soft -> loud)
- The current beat is indicated by a bright LED in the bottom row

### Creating and Modifying Patterns

1. Use the grid to create or modify patterns for each drum.
2. Switch between grid pages using K3 on the main page to access all 16 drums.
3. Use Page 2 (Sampler) to assign different samples to each drum or adjust their levels.

### Loading and Saving Songs

1. Navigate to Page 3 using E1.
2. Use E2 to select a song file.
3. Press K2 to load the selected song, or K3 to save the current song.

### Advanced Usage

- Use the numpad to quickly switch between patterns (enter the pattern number and press Enter).
- Experiment with different combinations of samples and patterns to create unique rhythms.
- Create multiple song files to quickly switch between different setups or projects.

Remember to save your work frequently using the save function on Page 3.

Enjoy creating and performing with Palm Tree!
