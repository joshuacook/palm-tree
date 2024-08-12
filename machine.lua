-- machine.lua

my_hid = include('lib/interface')
include('lib/screen')
sequencer = include('lib/sequencer')

local my_grid = grid.connect()
print("Grid connected:", my_grid.device)

local page = 1
local confirmation_mode = nil
local my_number = nil
local typing_number = false

local AUDIO_DIRECTORY = norns.state.path .. "audio/"

local selected_param = 1
local params_list = {"fade_time", "attack_time"}

local function get_duration(file)
    local handle = io.popen("soxi -D " .. file)
    local result = handle:read("*a")
    handle:close()
    return tonumber(result)
end

function load_buffer(path, start)
    softcut.buffer_read_mono(path, 0, start, -1, 1, 1)
end

function buffer_init()
    local sample_library = {}
    local sample_keys = {}
    local files = norns.system_glob(AUDIO_DIRECTORY .. "*.wav")
    local start = 0
    for _, file in ipairs(files) do
        local filename = file:match("([^/]+)%.wav$")
        sample_keys[#sample_keys + 1] = filename
        local duration = get_duration(file)
        load_buffer(file, start)
        sample_library[filename] = { file = file, duration = duration, start = start }
        start = start + duration
    end

    
    for _, drum in ipairs(sample_library) do
        drum.start = start
        load_buffer(drum.file, start)
        start = start + drum.duration
    end
    return sample_library, sample_keys
end

function voices_init()
    softcut.buffer_clear()
    for voice = 1, 6 do
        configure_voice(voice)
    end
end

function configure_voice(voice)
    local fade_time = params:get("fade_time")
    local attack_time = params:get("attack_time")
    softcut.buffer(voice, 1)
    softcut.loop(voice, 0)
    softcut.enable(voice, 1)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, fade_time)
    softcut.level_slew_time(voice, fade_time)
    softcut.recpre_slew_time(voice, attack_time)
end

function init()
    midi_out = midi.connect(1)
    midi_out.channel = 16
    print("MIDI out connected:", midi_out.device)

    audio.level_cut(1.0)
    
    params:add_control("fade_time", "Fade Time", controlspec.new(0.001, 0.5, 'exp', 0.001, 0.01, 's'))
    params:set("fade_time", 0.01)
    params:add_control("attack_time", "Attack Time", controlspec.new(0, 1, 'lin', 0.01, 0.01, 's'))
    params:set("attack_time", 0.01)

    params:set_action("fade_time", function(value)
        for voice = 1, 6 do
            softcut.fade_time(voice, value)
            softcut.level_slew_time(voice, value)
            softcut.recpre_slew_time(voice, value)
        end
    end)
    
    params:set_action("attack_time", function(value)
        for voice = 1, 6 do
            softcut.recpre_slew_time(voice, value)
        end
    end)

    voices_init()
    sample_library, sample_keys = buffer_init()
    sequencer.init(my_grid, sample_library, sample_keys)

    params:set("output_level", tonumber(sequencer.song.output_level))
    prev_output_level = params:get("output_level")

    metro.init{
        event = check_param_change,
        time = 0.2,
        count = -1
    }:start()


    redraw()
end

function keyboard.code(code, value)
    if value == 1 then
        if page == 2 then
            if code == "KPENTER" then
                if typing_number then
                    typing_number = false
                    local new_level = tonumber(my_number)
                    local selected_drum = sequencer.selected_drum
                    if new_level then
                        sequencer.drum_levels[selected_drum] = new_level
                    end
                    my_number = nil
                    redraw()
                end
            elseif code == "KPMINUS" then
                if typing_number and #my_number > 0 then
                    my_number = my_number:sub(1, -2)
                    redraw()
                end
            elseif code == "KPDOT" then
                if typing_number and not my_number:find("%.") then
                    my_number = my_number .. "."
                    redraw()
                end
            elseif code:match("^KP%d$") then
                local digit = code:sub(3)
                if typing_number then
                    my_number = my_number .. digit
                else
                    my_number = digit
                    typing_number = true
                end
                redraw()
            end
        else
            if code == "KPENTER" then
                if typing_number then
                    typing_number = false
                    my_number = tonumber(my_number)
                    sequencer.switch_pattern(my_number)
                    my_number = nil
                    redraw()
                end
            elseif code == "KPMINUS" then
                if typing_number and #my_number > 0 then
                    my_number = my_number:sub(1, -2)
                    redraw()
                end
            elseif code == "NUMLOCK" then
                if typing_number then
                    typing_number = false
                    my_number = nil
                    redraw()
                end
            elseif code:match("^KP%d$") then
                local digit = code:sub(3)
                if typing_number then
                    my_number = my_number .. digit
                else
                    my_number = digit
                    typing_number = true
                end
                redraw()
            end
        end
    end
end

function check_param_change()
    local current_output_level = params:get("output_level")

    if current_output_level ~= prev_output_level then
        prev_output_level = current_output_level
        redraw()
    end
end

function enc(current_encoder, value)
    if current_encoder == 1 then
        page = enc_global(current_encoder, value, page)
    elseif page == 1 then
        enc_main(current_encoder, value, sequencer)
    elseif page == 2 then
        enc_sampler(current_encoder, value, sequencer)
    elseif page == 3 then
        enc_load_and_save(current_encoder, value, sequencer)
    elseif page == 4 then
        if current_encoder == 2 then
            selected_param = util.clamp(selected_param + value, 1, #params_list)
        elseif current_encoder == 3 then
            params:delta(params_list[selected_param], value)
        end
    end
    redraw()
end

function key(current_key, value)
    if confirmation_mode then
        confirmation_mode = key_confirmation_mode(current_key, value, sequencer, confirmation_mode, redraw)
    else
        if page == 1 or page == 2 then
            key_main(current_key, value, sequencer, midi_out)
        elseif page == 3 then
            confirmation_mode = key_load_and_save(current_key, value)
        end
    end
    redraw()
end

function redraw()
    screen.clear()
    if confirmation_mode then
        confirmation_screen(screen, confirmation_mode)
    else
        if page == 1 then
            local output_level = params:get("output_level")
            page_main(screen, sequencer, output_level, my_number)
        elseif page == 2 then
            page_sampler(screen, sequencer)
        elseif page == 3 then
            page_load_and_save(screen, sequencer)
        elseif page == 4 then
            page_parameters(screen, selected_param, params_list)
        end
    end
    screen.update()
end

function my_grid.key(x, y, z)
    if z == 1 then
        sequencer.step_cycle(x, y)
    end
    sequencer.grid_redraw()
end
