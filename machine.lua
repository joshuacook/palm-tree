include('lib/io')
include('lib/sequencer')

local players = include('lib/voice')
local drums = include('data/drums')

local BeatClock = require 'beatclock'
local clock = BeatClock.new()
local g = grid.connect()

local beat_position = 1
local page = 1
local bpm = 91
local current_filename = "steps-001.txt"
local output_position = 7
local position = 1

function connect()
    keyb = hid.connect()
    keyb.event = keyboard_event
end

function keyboard_event(typ, code, val)
    print("hid.event ", typ, code, val)
    if code == 312 then
        clock:stop()
    elseif code == 313 then
        clock:start()
    elseif code == 712 and val == 1 then
        output_position = output_position - 1
        update_output_level(output_position)
    elseif code == 713 and val == 1 then
        output_position = output_position + 1
        update_output_level(output_position)
    end
    redraw()
end

function update_output_level(position)
    if position >= 1 and position <= 15 then
        local min_val = -57.0
        local max_val = 6.0
        local output_level = ((position - 1) / 14) * (max_val - min_val) + min_val
        print(output_level)
        params:set("output_level", output_level)
    end
end

function init()
    audio.level_cut(1.0)
    
    softcut.buffer(1, 1)
    softcut.buffer(2, 1)
    softcut.buffer(3, 1)
    softcut.buffer_clear()
    
    configure_voice(1, drums.kick.file, drums.kick.start)
    configure_voice(2, drums.snare.file, drums.snare.start)
    configure_voice(3, drums.ohhihat.file, drums.ohhihat.start)
    configure_voice(3, drums.clhihat.file, drums.clhihat.start)
    configure_voice(3, drums.cymbal.file, drums.cymbal.start)

    g = grid.connect()
    steps = include('data/steps')
    clock.on_step = beat
    clock:bpm_change(bpm)
    connect()

    load_steps_from_file(current_filename)

    redraw()
end

function enc(n, d)
    if n == 1 then
        page = util.clamp(page + d, 1, 3)
    elseif n == 2 then
        if page == 1 then
            set_bpm(bpm + d)
        elseif page == 2 or page == 3 then
            local base, num, ext = string.match(current_filename, "(steps%-)(%d+)(%.txt)")
            num = tonumber(num) + d
            current_filename = base .. string.format("%03d", num) .. ext
        end
    end
    redraw()
end

function key(n, z)
    if n == 2 and z == 1 then
        if page == 2 then
            load_steps_from_file(current_filename)
        elseif page == 3 then
            save_steps_to_file(current_filename)
        end
    end
end

function g.key(x, y, z)
    if z == 1 then 
        steps[y][x] = (steps[y][x] + 1) % 4
    end
end

function redraw()
    screen.clear()
    if page == 1 then
        screen.move(8, 8)
        screen.text("BPM: " .. bpm)
        screen.move(8, 16)
        local output_level = params:get("output_level")
        screen.text("Output Level: " .. (output_level == -math.huge and "-inf" or string.format("%.2f", output_level)))
    elseif page == 2 then
        screen.move(64, 32)
        screen.text_center("Load Screen")
        screen.move(64, 48)
        screen.text_center("File: " .. current_filename)
        screen.move(64, 64)
        screen.text_center("Press K2 to Load")
    elseif page == 3 then
        screen.move(64, 32)
        screen.text_center("Save Screen")
        screen.move(64, 48)
        screen.text_center("File: " .. current_filename)
        screen.move(64, 64)
        screen.text_center("Press K2 to Save")
    end
    screen.update()
end

function draw_beat()
    g:led(beat_position, 8, 15)
    g:refresh()
end

function grid_redraw()
    g:all(0)
    for i = 1, 16 do
        for j = 1, 5 do
            local step_value = steps[j][i]
            if step_value > 0 then
                g:led(i, j, step_value * 5)
            end
        end
    end
    g:refresh()
end

function beat()
    play(beat_position, players)
    beat_position = (beat_position % 16) + 1
    grid_redraw()
    draw_beat()
    redraw()
end

function set_bpm(new_bpm)
    bpm = new_bpm
    clock:bpm_change(bpm)
end