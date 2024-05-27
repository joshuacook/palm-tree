include('lib/screen')
my_hid = include('lib/hid')
sequencer = include('lib/sequencer')

local my_grid = grid.connect()
local page = 1
local audio_directory = _path.dust .. "audio/palm/"
local current_filename = "steps-001.txt"
local output_position = 7
params:set("output_level", -2.00)

local selected_drum = 1
local drum_keys = {}

local function load_drum_keys()
    local files = norns.system_glob(audio_directory .. "*.wav")
    for _, file in ipairs(files) do
        local filename = file:match("([^/]+)%.wav$")
        table.insert(drum_keys, filename)
    end
end

function init()
    audio.level_cut(1.0)
    softcut.buffer_clear()

    sequencer.init(my_grid, current_filename)

    load_drum_keys()

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
        page = util.clamp(page + d, 1, 4)
    elseif n == 2 then
        if page == 1 then
            sequencer.bpm = sequencer.bpm + d
            sequencer.clock:bpm_change(sequencer.bpm)
        elseif page == 2 then
            local current_key_index = nil
            for i, key in ipairs(drum_keys) do
                if key == sequencer.drum_keys[selected_drum] then
                    current_key_index = i
                    break
                end
            end
            if current_key_index then
                local new_key_index = util.clamp(current_key_index + d, 1, #drum_keys)
                sequencer.drum_keys[selected_drum] = drum_keys[new_key_index]
            end
        elseif page == 3 or page == 4 then
            local base, num, ext = string.match(current_filename, "(steps%-)(%d+)(%.txt)")
            num = util.clamp(tonumber(num) + d, 1, 999)
            current_filename = base .. string.format("%03d", num) .. ext
        end
    elseif n == 3 then
        if page == 1 then
            local current_output_level = params:get("output_level")
            params:set("output_level", util.clamp(current_output_level + d, -60.00, 60.00))
        elseif page == 2 then
            sequencer.drum_voice[selected_drum] = util.clamp(sequencer.drum_voice[selected_drum] + d, 1, 6)
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
            selected_drum = util.clamp(selected_drum - 1, 1, #sequencer.drum_keys)
            redraw()
        elseif page == 3 then
            sequencer.load_steps_from_file(current_filename)
        elseif page == 4 then
            sequencer.save_steps_to_file(current_filename)
        end
    elseif n == 3 and z == 1 then
        if page == 2 then
            selected_drum = util.clamp(selected_drum + 1, 1, #sequencer.drum_keys)
            redraw()
        end
    end
end

-- NORNS SCREEN

function redraw()
    screen.clear()
    if page == 1 then
        local output_level = params:get("output_level")
        page_main(screen, sequencer.bpm, output_level)
    elseif page == 2 then
        page_sampler(screen, sequencer, selected_drum)
    elseif page == 3 then
        page_load(screen, current_filename)
    elseif page == 4 then
        page_save(screen, current_filename)
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