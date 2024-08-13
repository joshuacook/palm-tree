-- lib/sequencer.lua

local N_PLAYERS = 16
local PLAYERS_PER_PAGE = 8
local FADE_TIME = 0.005
local PATTERNS_DIRECTORY = _path.dust .. "code/palm-tree/songs/"

local sequencer = {}
local midi_out = midi.connect(1)

sequencer.next_pattern_index = nil

function load_song(sequencer, filename)
    local full_path = PATTERNS_DIRECTORY .. filename
    local file, err = io.open(full_path, "r")

    if file then
        local content = file:read("*a")
        file:close()
        
        sequencer.steps = {}
        sequencer.drum_keys = {}
        sequencer.drum_levels = {}

        local song = parse_song(content)
        sequencer.song = song
        sequencer.song.filename = filename
        sequencer.song.patterns = parse_patterns(song.patterns)

        params:set("clock_tempo", sequencer.song.bpm)
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
                elseif col == 18 then
                    pattern[row].drum_level = tonumber(step)
                end
                col = col + 1
            end
            row = row + 1
        end
        table.insert(parsed_patterns, pattern)
    end
    return parsed_patterns
end

function parse_song(content)
    local song = {}
    local metadata_section, patterns_section = content:match("(.-)\n+patterns:\n(.*)")
    if not metadata_section:match("\n$") then
        metadata_section = metadata_section .. "\n"
    end

    for key, value in metadata_section:gmatch("([%w_]+):%s*([^\n]+)\n") do
        local num_value = tonumber(value)
        if num_value then
            song[key] = num_value
        else
            song[key] = value:match('^"(.*)"$') or value
        end
    end
    
    song.patterns = {}
    local current_pattern = nil
    local line_count = 0

    for line in patterns_section:gmatch("[^\r\n]+") do
        if line:find("%- |") then
            if current_pattern then
                table.insert(song.patterns, current_pattern)
            end
            current_pattern = ""
            line_count = 0
        elseif current_pattern then
            current_pattern = current_pattern .. line .. "\n"
            line_count = line_count + 1
            if line_count == 16 then
                table.insert(song.patterns, current_pattern)
                current_pattern = nil
            end
        end
    end

    if current_pattern then
        table.insert(song.patterns, current_pattern)
    end

    return song
end

function save_song(sequencer)
    local filename = sequencer.song.filename
    local full_path = PATTERNS_DIRECTORY .. filename
    local file, err = io.open(full_path, "w")
    if file then
        local serialized_patterns = serialize_patterns(sequencer.song.patterns)
        sequencer.song.patterns = serialized_patterns
        file:write(serialize_song(sequencer.song))
        file:close()
    else
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
    end
end

function serialize_song(song)
    local serialized = ""
    for key, value in pairs(song) do
        if key ~= "patterns" and key ~= "filename" then
            if type(value) == "string" then
                serialized = serialized .. key .. ': "' .. value .. '"\n'
            else
                serialized = serialized .. key .. ': ' .. tostring(value) .. '\n'
            end
        end
    end
    serialized = serialized .. "patterns:\n"
    for _, pattern in ipairs(song.patterns) do
        serialized = serialized .. "  - |\n" .. pattern .. "\n\n"
    end
    return serialized
end

function serialize_patterns(patterns)
    local serialized_patterns = {}
    for _, pattern in ipairs(patterns) do
        local pattern_str = ""
        for _, row in ipairs(pattern) do
            for col = 1, 16 do
                if col == 1 then
                    pattern_str = pattern_str .. "    "
                end
                pattern_str = pattern_str .. row[col] .. " "
            end
            pattern_str = pattern_str .. (row.drum_key or "default_key") .. " "
            pattern_str = pattern_str .. (row.drum_level or "0") .. "\n"
        end
        table.insert(serialized_patterns, pattern_str)
    end
    return serialized_patterns
end

function sequencer.init(grid, clock, sample_library, sample_keys)
    if not grid or not grid.all then
        error("Grid not properly initialized")
    end
    sequencer.grid = grid
    sequencer.clock = clock
    sequencer.sample_library = sample_library
    sequencer.sample_keys = sample_keys

    sequencer.current_grid_page = 1
    sequencer.active_pattern_index = 1

    sequencer.load_song("song-001.yaml")

    sequencer.apply_pattern_switch(1)

    sequencer.beat_position = 0
    params:set("clock_tempo", sequencer.song.bpm)
    
    sequencer.n_players = N_PLAYERS
    sequencer.selected_drum = 1
    
    sequencer.clock.transport.start = function()
        sequencer.clock.id = sequencer.clock.run(function()
            while true do
                sequencer.clock.sync(1/4)
                sequencer.update()
            end
        end)
    end
    
    sequencer.clock.transport.stop = function(id)
        sequencer.clock.cancel(sequencer.clock.id)
        sequencer.clock.id = nil
    end
end

function sequencer.draw_beat()
    sequencer.grid:led(sequencer.beat_position, 8, 15)
    sequencer.grid:refresh()
end

function sequencer.get_step(x, y)
    local page_offset = (sequencer.current_grid_page - 1) * PLAYERS_PER_PAGE
    return sequencer.steps[y + page_offset][x]
end

function sequencer.grid_redraw()
    sequencer.grid:all(0)
    local start_drum = (sequencer.current_grid_page - 1) * PLAYERS_PER_PAGE + 1
    local end_drum = math.min(start_drum + PLAYERS_PER_PAGE - 1, N_PLAYERS)
    
    for i = start_drum, end_drum do
        local row = (i - 1) % PLAYERS_PER_PAGE + 1
        for col = 1, 16 do
            local step_value = sequencer.steps[i][col]
            if step_value > 0 then
                local intensity = step_value * 7
                sequencer.grid:led(col, row, intensity)
            end
        end
    end
    sequencer.grid:refresh()
end

function sequencer.load_song(filename)
    load_song(sequencer, filename)
    sequencer.switch_pattern(sequencer.active_pattern_index)
end

function sequencer.play_voices(beat_position)
    local voice = 1
    for y = 1, N_PLAYERS do
        local step_value = sequencer.steps[y][beat_position]
        if step_value > 0 then
            local drum_level = sequencer.drum_levels[y] or 1 -- Default level is 1 if not specified
            sequencer.play_voice(voice, y, step_value, drum_level)
            voice = voice + 1
        end
    end
end

function sequencer.play_voice(voice, drum_index, value, level)
    local drum_key = sequencer.drum_keys[drum_index]
    local drum = sequencer.sample_library[drum_key]
    local start = drum.start
    local duration = drum.duration
    softcut.play(voice, 0)
    softcut.level(voice, value * 0.5 * level) -- Adjust volume by drum level
    softcut.loop_start(voice, start)
    softcut.loop_end(voice, start + duration - FADE_TIME)
    softcut.position(voice, start)
    softcut.play(voice, 1)
end

function sequencer.save_song()
    sequencer.switch_pattern(sequencer.active_pattern_index)
    save_song(sequencer)
end

function sequencer.set_selected_drum(drum_index)
    sequencer.selected_drum = drum_index
    sequencer.current_grid_page = math.ceil(drum_index / PLAYERS_PER_PAGE)
    sequencer.grid_redraw()
end

function sequencer.set_step(x, y, value)
    local page_offset = (sequencer.current_grid_page - 1) * PLAYERS_PER_PAGE
    
    -- Ensure sequencer.steps is initialized
    if not sequencer.steps then
        print("Error: sequencer.steps is nil")
        return
    end
    
    -- Ensure the row is initialized
    if not sequencer.steps[y + page_offset] then
        print("Error: sequencer.steps[" .. tostring(y + page_offset) .. "] is nil")
        return
    end
    
    sequencer.steps[y + page_offset][x] = value
    sequencer.grid_redraw()
end

function sequencer.step_cycle(x, y)
    local value = sequencer.get_step(x, y)
    sequencer.set_step(x, y, (value + 1) % 3)
end

function sequencer.switch_pattern(pattern_index)
    sequencer.next_pattern_index = pattern_index

    for channel = 1, 4 do
        midi_out:program_change(pattern_index - 1, channel)
    end

end

function sequencer.apply_pattern_switch(pattern_index)
    pattern_index = pattern_index or sequencer.next_pattern_index
    if sequencer.next_pattern_index then
        local pattern_index = sequencer.next_pattern_index
        
        if sequencer.steps and #sequencer.steps > 0 then
            for y, row in ipairs(sequencer.steps) do
                sequencer.song.patterns[sequencer.active_pattern_index][y] = row
                sequencer.song.patterns[sequencer.active_pattern_index][y].drum_key = sequencer.drum_keys[y]
                sequencer.song.patterns[sequencer.active_pattern_index][y].drum_level = sequencer.drum_levels[y]
            end
        end
        
        if pattern_index <= #sequencer.song.patterns then
            sequencer.active_pattern_index = pattern_index
        else
            local new_pattern = sequencer.create_empty_pattern()
            sequencer.song.patterns[pattern_index] = new_pattern
            sequencer.active_pattern_index = pattern_index
        end
        
        sequencer.steps = sequencer.song.patterns[sequencer.active_pattern_index]

        sequencer.drum_keys = {}
        sequencer.drum_levels = {}
        for y, row in ipairs(sequencer.steps) do
            sequencer.drum_keys[y] = row.drum_key
            sequencer.drum_levels[y] = row.drum_level
        end
        sequencer.grid_redraw()

        sequencer.next_pattern_index = nil
    end
end

function sequencer.update()
    sequencer.beat_position = sequencer.beat_position % 16 + 1
    sequencer.play_voices(sequencer.beat_position)
    
    if sequencer.beat_position == 16 then
        sequencer.apply_pattern_switch()
    end
    
    sequencer.grid_redraw()
    sequencer.draw_beat()
end

function sequencer.create_empty_pattern()
    local new_pattern = {}
    for y = 1, N_PLAYERS do
        new_pattern[y] = {}
        for x = 1, 16 do
            new_pattern[y][x] = 0
        end
        new_pattern[y].drum_key = sequencer.sample_keys[y] or "default_key"
        new_pattern[y].drum_level = 1 -- Default level is 1
    end
    return new_pattern
end

function sequencer.play()
    sequencer.clock.transport.start()
end

function sequencer.stop()
    sequencer.clock.transport.stop()
end

return sequencer
