local yaml = require('yaml')
local patterns_directory = _path.dust .. "code/palm-tree/songs/"
local audio_directory = _path.dust .. "audio/palm/"
local sequencer = {}
local BeatClock = require 'beatclock'
local drums = {}
local N_PLAYERS = 16
local DRUMS_PER_PAGE = 8
local fade_time = 0.01

local function get_duration(file)
    local handle = io.popen("soxi -D " .. file)
    local result = handle:read("*a")
    handle:close()
    return tonumber(result)
end

local function init_drums()
    local files = norns.system_glob(audio_directory .. "*.wav")
    for _, file in ipairs(files) do
        local filename = file:match("([^/]+)%.wav$")
        local duration = get_duration(file)
        drums[filename] = { file = file, duration = duration }
        print("Loaded drum:", filename, "Duration:", duration)
    end
end

function sequencer.init(grid)
    if not grid or not grid.all then
        error("Grid not properly initialized")
    end
    sequencer.grid = grid

    init_drums()
    sequencer.drums_per_page = DRUMS_PER_PAGE
    sequencer.drum_keys = {}
    sequencer.current_page = 1
    sequencer.total_pages = math.ceil(N_PLAYERS / DRUMS_PER_PAGE)
    
    sequencer.active_pattern = 1

    sequencer.clock = BeatClock.new()
    sequencer.beat_position = 0

    sequencer.load_song("song-001.yaml")
    sequencer.patterns = {}
    sequencer.clock:bpm_change(sequencer.song.bpm)
    sequencer.clock.on_step = sequencer.update
    sequencer.playing = false

    local start = 0
    for name, drum in pairs(drums) do
        drum.start = start
        sequencer.load_buffer(drum.file, start)
        print("Buffer loaded for:", name, "Start:", start)
        start = start + drum.duration
    end

    sequencer.configure_voice(1)
    sequencer.configure_voice(2)
    sequencer.configure_voice(3)
    sequencer.configure_voice(4)
    sequencer.configure_voice(5)
    sequencer.configure_voice(6)
end

function sequencer.configure_voice(voice)
    softcut.buffer(voice, 1)
    softcut.loop(voice, 0)
    softcut.enable(voice, 1)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, fade_time)
    softcut.level_slew_time(voice, fade_time)
    print("Voice configured:", voice)
end

function sequencer.draw_beat()
    sequencer.grid:led(sequencer.beat_position, 8, 15)
    sequencer.grid:refresh()
end

function sequencer.get_step(x, y)
    local pattern = sequencer.song.patterns[sequencer.active_pattern]
    assert(pattern, "No pattern found for the active pattern index.")
    assert(pattern[y], "No row found in the pattern for the specified index.")
    return pattern[y][x]
end

function sequencer.grid_redraw()
    sequencer.grid:all(0)
    local start_drum = (sequencer.current_page - 1) * DRUMS_PER_PAGE + 1
    local end_drum = math.min(start_drum + DRUMS_PER_PAGE - 1, N_PLAYERS)
    
    for i = start_drum, end_drum do
        local row = (i - 1) % DRUMS_PER_PAGE + 1
        for col = 1, 16 do
            local step_value = sequencer.get_step(col, i)
            if step_value > 0 then
                local intensity = step_value * 7
                sequencer.grid:led(col, row, intensity)
            end
        end
    end
    sequencer.grid:refresh()
end

function sequencer.load_buffer(path, start)
    print("Loading buffer:", path, "at start:", start)
    softcut.buffer_read_mono(path, 0, start, -1, 1, 1)    
end

function sequencer.load_song(filename)
    local full_path = patterns_directory .. filename
    print("Full path: " .. full_path)  -- Debug statement
    local file, err = io.open(full_path, "r")

    if file then
        print("File opened successfully")  -- Debug statement
        local content = file:read("*a")
        file:close()
        print("File content:\n" .. content)  -- Debug statement
        
        local song = yaml.eval(content)
        sequencer.song = song
        sequencer.song.patterns = parse_patterns(song.patterns)
        
        if #sequencer.song.patterns == 0 then
            -- Initialize with an empty pattern if none exist
            sequencer.song.patterns[1] = {}
            for y = 1, N_PLAYERS do
                sequencer.song.patterns[1][y] = {}
                for x = 1, 16 do
                    sequencer.song.patterns[1][y][x] = 0
                end
            end
        end
        sequencer.active_pattern = 1
        sequencer.steps = sequencer.song.patterns[sequencer.active_pattern]
        sequencer.clock:bpm_change(sequencer.song.bpm)
        print("Parsed song:", song)  -- Debug statement
    else
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
    end
end

function parse_patterns(patterns)
    local parsed_patterns = {}
    for _, pattern_str in ipairs(patterns) do
        local pattern = {}
        local row = 1
        for line in string.gmatch(pattern_str, "[^\n]+") do
            local col = 1
            pattern[row] = {}
            for step in string.gmatch(line, "%S+") do
                if col <= 16 then
                    pattern[row][col] = tonumber(step)
                elseif col == 17 then
                    pattern[row].drum_key = step
                end
                col = col + 1
            end
            row = row + 1
        end
        table.insert(parsed_patterns, pattern)
    end
    return parsed_patterns
end

function sequencer.save_song(filename)
    local full_path = patterns_directory .. filename
    local file = io.open(full_path, 'w')

    if file then 
        local song_str = yaml.dump(sequencer.song)
        file:write(song_str)
        file:close()
        print("Song saved to file: " .. filename)
    else
        print("Failed to save song to file: " .. filename)
    end
end

function sequencer.play(beat_position)
    local voice = 1
    for y = 1, N_PLAYERS do
        local value = sequencer.get_step(beat_position, y)
        if value > 0 then
            sequencer.play_voice(voice, y, value)
            voice = voice + 1
        end
    end
end

function sequencer.play_voice(voice, drum_index, value)
    local drum_key = sequencer.drum_keys[drum_index]
    local drum = drums[drum_key]
    local start = drum.start
    local duration = drum.duration
    softcut.play(voice, 0)
    softcut.level(voice, value * 0.5)
    softcut.loop_start(voice, start)
    softcut.loop_end(voice, start + duration - fade_time)
    softcut.position(voice, start)
    softcut.play(voice, 1)
end

function sequencer.set_selected_drum(drum_index)
    sequencer.selected_drum = drum_index
    sequencer.current_page = math.ceil(drum_index / DRUMS_PER_PAGE)
    sequencer.grid_redraw()
end

function sequencer.set_step(x, y, value)
    local page_offset = (sequencer.current_page - 1) * DRUMS_PER_PAGE
    sequencer.song.patterns[sequencer.active_pattern][y + page_offset][x] = value
    sequencer.grid_redraw()
end

function sequencer.step_cycle(x, y)
    local page_offset = (sequencer.current_page - 1) * DRUMS_PER_PAGE
    local value = sequencer.get_step(x, y + page_offset)
    sequencer.set_step(x, y + page_offset, (value + 1) % 3)
end

function sequencer.switch_pattern(pattern_index)
    if pattern_index <= #sequencer.song.patterns then
        sequencer.active_pattern = pattern_index
    else
        local new_pattern = {}
        for y = 1, N_PLAYERS do
            new_pattern[y] = {}
            for x = 1, 16 do
                new_pattern[y][x] = 0
            end
        end
        sequencer.song.patterns[pattern_index] = new_pattern
        sequencer.active_pattern = pattern_index
    end
    sequencer.steps = sequencer.song.patterns[sequencer.active_pattern]
    sequencer.grid_redraw()
end

function sequencer.update()
    sequencer.beat_position = sequencer.beat_position % 16 + 1
    sequencer.play(sequencer.beat_position)
    sequencer.grid_redraw()
    sequencer.draw_beat()
end

return sequencer
