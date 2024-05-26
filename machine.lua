include('lib/helpers')
include('lib/screen')

sequencer = include('lib/sequencer')

local my_grid = grid.connect()
local page = 1
local current_filename = "steps-001.txt"
local output_position = 7
params:set("output_level", -30.00)

steps = include('data/steps')

function init()
    audio.level_cut(1.0)

    softcut.buffer(1, 1)
    softcut.buffer(2, 1)
    softcut.buffer(3, 1)
    softcut.buffer_clear()

    drum_players = dofile(_path.dust .. "code/beat/lib/drum_players.lua")
    sequencer.init(drum_players, my_grid)

    connect_hid()

    sequencer.load_steps_from_file(current_filename)

    redraw()
end

-- NORNS INTERFACE

function enc(n, d)
    if n == 1 then
        page = util.clamp(page + d, 1, 3)
    elseif n == 2 then
        if page == 1 then
            sequencer.bpm = sequencer.bpm + d
            sequencer.clock:bpm_change(sequencer.bpm)
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
            sequencer.load_steps_from_file(current_filename)
        elseif page == 3 then
            sequencer.save_steps_to_file(current_filename)
        end
    end
end

-- NORNS SCREEN

function redraw()
    screen.clear()
    if page == 1 then
        local output_level = params:get("output_level")
        page_1(screen, sequencer.bpm, output_level)
    elseif page == 2 then
        page_2(screen, current_filename)
    elseif page == 3 then
        page_3(screen, current_filename)
    end
    screen.update()
end

-- GRID INTERFACE

function my_grid.key(x, y, z)
    if z == 1 then 
        sequencer.set_step(x, y, (sequencer.steps[y][x] + 1) % 4)
    end
    sequencer.grid_redraw()
end

-- CONTROL INTERFACE

function connect_hid()
    keyb = hid.connect()
    keyb.event = keyboard_event
end

function keyboard_event(typ, code, val)
    if code == 312 then
        sequencer.clock:stop()
    elseif code == 313 then
        sequencer.clock:start()
    elseif val == 1 and (code == 712 or code == 713) then
        local output_level, position = compute_output_level(code, output_position)
        params:set("output_level", output_level)
        output_position = position
    end
    redraw()
end