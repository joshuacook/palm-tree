local patterns_directory = _path.dust .. "code/beat/patterns/"
local sequencer = {}
local BeatClock = require 'beatclock'

function sequencer.init(players, grid)
    sequencer.clock = BeatClock.new()
    sequencer.beat_position = 1
    sequencer.bpm = 91
    sequencer.clock:bpm_change(sequencer.bpm)
    sequencer.players = players
    sequencer.clock.on_step = sequencer.update
    sequencer.grid = grid

    sequencer.steps = {}
    for y = 1, 5 do
        sequencer.steps[y] = {}
        for x = 1, 16 do
            sequencer.steps[y][x] = 0
        end
    end
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

function sequencer.play(beat_position, players)
    for y = 1, 5 do
        local value = sequencer.steps[y][beat_position]
        if value > 0 then
            print("playing " .. y .. " " .. value)
            players[y](value)
        end
    end
end

function sequencer.save_steps_to_file(filename)
    local file = io.open(patterns_directory .. filename, 'w')
    if file then 
        for i = 1, 5 do
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
    sequencer.play(sequencer.beat_position, sequencer.players)
    sequencer.beat_position = sequencer.beat_position % 16 + 1
    sequencer.grid_redraw()
    sequencer.draw_beat()
end

return sequencer

