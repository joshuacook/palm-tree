local patterns_directory = _path.dust .. "code/palm-tree/patterns/"
local audio_directory = _path.dust .. "audio/palm/"
local sequencer = {}
local BeatClock = require 'beatclock'
local drums = {}

-- Function to get the duration of an audio file using soxi
local function get_duration(file)
    local handle = io.popen("soxi -D " .. file)
    local result = handle:read("*a")
    handle:close()
    return tonumber(result)
end

-- Function to initialize the drums table synchronously
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

    sequencer.clock = BeatClock.new()
    sequencer.beat_position = 0
    sequencer.bpm = 91
    sequencer.clock:bpm_change(sequencer.bpm)
    sequencer.clock.on_step = sequencer.update
    sequencer.playing = false
    sequencer.drum_keys = {
        "606-BD",
        "606-SD",
        "606-OH",
        "606-CH",
        "606-CY",
        "ELM-01",
        "ELM-02",
        "ELM-03"
    }
    sequencer.drum_voice = {1, 2, 3, 3, 3, 4, 4, 4}

    sequencer.steps = {}
    for y = 1, 8 do
        sequencer.steps[y] = {}
        for x = 1, 16 do
            sequencer.steps[y][x] = 0
        end
    end

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

    sequencer.players = {
        function (value) sequencer.play_voice(1, value) end,
        function (value) sequencer.play_voice(2, value) end,
        function (value) sequencer.play_voice(3, value) end,
        function (value) sequencer.play_voice(4, value) end,
        function (value) sequencer.play_voice(5, value) end,
        function (value) sequencer.play_voice(6, value) end,
        function (value) sequencer.play_voice(7, value) end,
        function (value) sequencer.play_voice(8, value) end
    }
end

function sequencer.configure_voice(voice)
    softcut.buffer(voice, 1)
    softcut.loop(voice, 0)
    softcut.enable(voice, 1)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, 0.01)
    softcut.level_slew_time(voice, 0.01)
    print("Voice configured:", voice)
end

function sequencer.draw_beat()
    sequencer.grid:led(sequencer.beat_position, 8, 15)
    sequencer.grid:refresh()
end

function sequencer.get_step(x, y)
    return sequencer.steps[y][x]
end

function sequencer.grid_redraw()
    sequencer.grid:all(0)
    for i = 1, 16 do
        for j = 1, 8 do 
            local step_value = sequencer.steps[j][i]
            if step_value > 0 then
                sequencer.grid:led(i, j, step_value * 5)
            end
        end
    end
    sequencer.grid:refresh()
end

function sequencer.load_buffer(path, start)
    print("Loading buffer:", path, "at start:", start)
    softcut.buffer_read_mono(path, 0, start, -1, 1, 1)    
end

function sequencer.load_steps_from_file(filename)
    local file = io.open(patterns_directory .. filename, 'r')
    if file then 
        local content = file:read('*a')
        file:close()

        local row = 1
        for line in string.gmatch(content, "([^\n]+)") do
            local col = 1
            for step in string.gmatch(line, "%d") do
                sequencer.set_step(col, row, tonumber(step))
                col = col + 1
            end
            row = row + 1
        end
    else
        print("File not found: " .. filename)
    end
end

function sequencer.play(beat_position)
    for y = 1, 8 do
        local value = sequencer.steps[y][beat_position]
        if value > 0 then
            sequencer.players[y](value)
        end
    end
end

function sequencer.play_voice(drum_index, value)
    local voice = sequencer.drum_voice[drum_index]
    local drum_key = sequencer.drum_keys[drum_index]
    local drum = drums[drum_key]
    local start = drum.start
    local duration = drum.duration
    softcut.play(voice, 0)
    softcut.level(voice, value*0.33)
    softcut.loop_start(voice, start)
    softcut.loop_end(voice, start + duration - 0.01)
    softcut.position(voice, start)
    softcut.play(voice, 1)
end

function sequencer.save_steps_to_file(filename)
    local file = io.open(patterns_directory .. filename, 'w')

    if file then 
        for i = 1, 8 do
            local line = ""
            for j = 1, 16 do
                local step = sequencer.get_step(j, i)
                line = line .. step .. " "
            end
            file:write(line:sub(1, -2) .. "\n")
        end
        file:close()
        print("Steps saved to file: " .. filename)
    else
        print("Failed to save steps to file: " .. filename)
    end
end

function sequencer.set_step(x, y, value)
    sequencer.steps[y][x] = value
end

function sequencer.update()
    sequencer.beat_position = sequencer.beat_position % 16 + 1
    sequencer.play(sequencer.beat_position)
    sequencer.grid_redraw()
    sequencer.draw_beat()
end

return sequencer
