# Black Box Control Surface for Norns

## Overview
Custom grid-based control surface for 1010 Music Black Box, implemented as a Norns script.

## Core Functionality

### Grid Layout
- Top row (1-16): Recording controls
- Bottom row (1-16): Playback controls
- Middle rows: Loop length visualization (1,2,3,4,8,16 bars)

### Visual Feedback System
#### Recording Row
- Unlit: Empty pad
- Dim solid: Has content
- Flashing: Armed for recording
- Bright solid: Recording

#### Playback Row
- Unlit: Stopped
- Dim: Queued to start
- Bright: Playing
- Flashing: Queued to stop

### Loop Length Control
- Only active for empty pads
- Always visible for reference
- Non-linear mapping (1,2,3,4,8,16)
- Visual intensity indicates selected length

## MIDI Implementation
[To be detailed: CC mappings for loop control, recording, and length selection]

## Development Priorities
1. Basic grid interface implementation
2. MIDI communication with Black Box
3. Visual feedback system
4. Loop length control
5. Performance optimizations

## Technical Requirements
- Norns script environment
- Grid support
- MIDI routing capability
- Black Box firmware compatibility

## Testing Scenarios
1. Record/playback workflow
2. Length selection
3. Multiple loop interaction
4. MIDI timing accuracy
5. Visual feedback responsiveness