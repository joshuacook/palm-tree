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

return midi
