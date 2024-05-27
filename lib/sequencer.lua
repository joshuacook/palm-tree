    local patterns_directory = _path.dust .. "code/palm-tree/patterns/"
    local sequencer = {}
    local BeatClock = require 'beatclock'
    local drums = {
        kick = {
            file = "audio/common/808/808-BD.wav",
            start = 0,
            duration = 0.255,
        },
        snare = {
            file = "audio/common/808/808-SD.wav",
            start = 0.255,
            duration = 0.387,
        },
        ohhihat = {
            file = "audio/common/808/808-OH.wav",
            start = 0.642,
            duration = 0.291,
        },
        clhihat = {
            file = "audio/common/808/808-CH.wav",
            start = 0.933,
            duration = 0.133,
        },
        cymbal = {
            file = "audio/common/808/808-CY.wav",
            start = 1.066,
            duration = 0.834,
        },
    }

    function sequencer.init(grid)
        sequencer.clock = BeatClock.new()
        sequencer.beat_position = 0
        sequencer.bpm = 91
        sequencer.clock:bpm_change(sequencer.bpm)
        sequencer.clock.on_step = sequencer.update
        sequencer.grid = grid
        sequencer.playing = false

        sequencer.steps = {}
        for y = 1, 5 do
            sequencer.steps[y] = {}
            for x = 1, 16 do
                sequencer.steps[y][x] = 0
            end
        end

        sequencer.load_buffer(drums.kick.file, drums.kick.start)
        sequencer.load_buffer(drums.snare.file, drums.snare.start)
        sequencer.load_buffer(drums.ohhihat.file, drums.ohhihat.start)
        sequencer.load_buffer(drums.clhihat.file, drums.clhihat.start)
        sequencer.load_buffer(drums.cymbal.file, drums.cymbal.start)

        sequencer.configure_voice(1)
        sequencer.configure_voice(2)
        sequencer.configure_voice(3)

        sequencer.players = {
            function (value) sequencer.play_voice(1, value, drums.kick.start, drums.kick.duration) end,
            function (value) sequencer.play_voice(2, value, drums.snare.start, drums.snare.duration) end,
            function (value) sequencer.play_voice(3, value, drums.ohhihat.start, drums.ohhihat.duration) end,
            function (value) sequencer.play_voice(3, value, drums.clhihat.start, drums.clhihat.duration) end,
            function (value) sequencer.play_voice(3, value, drums.cymbal.start, drums.cymbal.duration) end
        }
    end

    function sequencer.configure_voice(voice)
        softcut.loop(voice, 0)
        softcut.enable(voice, 1)
        softcut.rate(voice, 1)
        softcut.fade_time(voice, 0.01)
        softcut.level_slew_time(voice, 0.01)
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
            for j = 1, 5 do 
                local step_value = sequencer.steps[j][i]
                if step_value > 0 then
                    sequencer.grid:led(i, j, step_value * 5)
                end
            end
        end
        sequencer.grid:refresh()
    end

    function sequencer.load_buffer(path, start)
        softcut.buffer_read_mono(_path.dust..path, 0, start, -1, 1, 1)    
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
        for y = 1, 5 do
            local value = sequencer.steps[y][beat_position]
            if value > 0 then
                sequencer.players[y](value)
            end
        end
    end

    function sequencer.play_voice(voice, value, start, duration)
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
            for i = 1, 5 do
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

