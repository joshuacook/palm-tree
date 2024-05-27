include('lib/screen')
my_hid = include('lib/hid')
sequencer = include('lib/sequencer')

local my_grid = grid.connect()
local page = 1
local current_filename = "steps-001.txt"
local output_position = 7
params:set("output_level", 6.00)

function init()
    audio.level_cut(1.0)

    softcut.buffer(1, 1)
    softcut.buffer(2, 1)
    softcut.buffer(3, 1)
    softcut.buffer_clear()

    drum_players = dofile(_path.dust .. "code/palm-tree/lib/drum_players.lua")
    sequencer.init(drum_players, my_grid)
    sequencer.load_steps_from_file(current_filename)

    interface = hid.connect()
    print(interface)
    if interface ~= nil then
        my_hid.init(sequencer, interface, params)
    end

    prev_output_level = params:get("output_level")

    metro.init{
      event = check_param_change,
      time = 0.2,
      count = -1
    }:start()

    redraw()
end

function check_param_change()
    local current_output_level = params:get("output_level")

    if current_output_level ~= prev_output_level then
      prev_output_level = current_output_level
      redraw()
    end
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
    elseif n == 3 then
        if page == 1 then
            local current_output_level = params:get("output_level")
            params:set("output_level", util.clamp(current_output_level + d, -60.00, 60.00))
        end
    end
    redraw()
end

function key(n, z)
    if n == 2 and z == 1 then
        if page == 1 then
            if sequencer.playing then
                sequencer.clock:stop()
                sequencer.playing = false
            else
                sequencer.clock:start()
                sequencer.playing = true
            end
        elseif page == 2 then
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