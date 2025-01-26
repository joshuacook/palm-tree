-- MIDI mappings for Blackbox control
local midi = {}

-- MIDI channel the Blackbox is receiving on
midi.channel = 11

-- MIDI note numbers for pad triggers (36-51, C2 to D#3)
midi.pad_notes = {
  -- First row (pads 1-4)
  [1] = 36, -- C2
  [2] = 37,
  [3] = 38,
  [4] = 39,
  
  -- Second row (pads 5-8) 
  [5] = 40,
  [6] = 41,
  [7] = 42,
  [8] = 43,
  
  -- Third row (pads 9-12)
  [9] = 44,
  [10] = 45,
  [11] = 46,
  [12] = 47,
  
  -- Fourth row (pads 13-16)
  [13] = 48,
  [14] = 49,
  [15] = 50,
  [16] = 51  -- D#3
}

-- MIDI note numbers for recording pads (68-83, G#4 to B5)
midi.record_notes = {
  -- First row
  [1] = 68, -- G#4
  [2] = 69,
  [3] = 70,
  [4] = 71,
  
  -- Second row
  [5] = 72,
  [6] = 73,
  [7] = 74,
  [8] = 75,
  
  -- Third row  
  [9] = 76,
  [10] = 77,
  [11] = 78,
  [12] = 79,
  
  -- Fourth row
  [13] = 80,
  [14] = 81,
  [15] = 82,
  [16] = 83  -- B5
}

-- MIDI note numbers for clearing pads (84-99, C6 to D#7)
midi.clear_notes = {
  -- First row
  [1] = 84, -- C6
  [2] = 85,
  [3] = 86,
  [4] = 87,
  
  -- Second row
  [5] = 88,
  [6] = 89,
  [7] = 90,
  [8] = 91,
  
  -- Third row
  [9] = 92,
  [10] = 93,
  [11] = 94,
  [12] = 95,
  
  -- Fourth row
  [13] = 96,
  [14] = 97,
  [15] = 98,
  [16] = 99  -- D#7
}

return midi
