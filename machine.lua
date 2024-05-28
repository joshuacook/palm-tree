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

local confirmation_mode = nil

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
        page = util.clamp(page + d, 1, 3)
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
        elseif page == 3 then
            local base, num, ext = string.match(current_filename, "(steps%-)(%d+)(%.txt)")
            num = util.clamp(tonumber(num) + d, 1, 999)
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
    if z == 1 then
        if confirmation_mode then
            if n == 2 then
                if confirmation_mode == "load" then
                    sequencer.load_steps_from_file(current_filename)
                    sequencer.grid_redraw()
                elseif confirmation_mode == "save" then
                    sequencer.save_steps_to_file(current_filename)
                end
                confirmation_mode = nil
            elseif n == 3 then
                confirmation_mode = nil
            end
            redraw()
        else
            if n == 2 then
                if page == 1 then
                    if sequencer.playing then
                        sequencer.clock:stop()
                        sequencer.playing = false
                    else
                        sequencer.clock:start()
                        sequencer.playing = true
                    end
                elseif page == 2 then
                    selected_drum = (selected_drum - 2) % #sequencer.drum_keys + 1
                    sequencer.set_selected_drum(selected_drum)
                elseif page == 3 then
                    confirmation_mode = "load"
                end
            elseif n == 3 then
                if page == 1 then
                    if sequencer.current_page == 1 then
                        sequencer.set_selected_drum(9)
                    else
                        sequencer.set_selected_drum(1)
                    end
                elseif page == 2 then
                    selected_drum = selected_drum % #sequencer.drum_keys + 1
                    sequencer.set_selected_drum(selected_drum)
                elseif page == 3 then
                    confirmation_mode = "save"
                end
            end
            redraw()
        end
    end
end

-- NORNS SCREEN

function redraw()
    screen.clear()
    if confirmation_mode then
        confirmation_screen(screen, confirmation_mode)
    else
        if page == 1 then
            local output_level = params:get("output_level")
            page_main(screen, sequencer.bpm, output_level, sequencer.current_page)
        elseif page == 2 then
            page_sampler(screen, sequencer, selected_drum)
        elseif page == 3 then
            page_load_and_save(screen, current_filename)
        end
    end
    screen.update()
end

-- GRID INTERFACE

function my_grid.key(x, y, z)
    if z == 1 then
        sequencer.step_cycle(x, y)
    end
    sequencer.grid_redraw()
end