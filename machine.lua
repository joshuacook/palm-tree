-- machine.lua

include('lib/interface')
include('lib/screen')
sequencer = include('lib/sequencer')

local my_grid = grid.connect()
print("Grid connected:", my_grid.device)

local page = 1
local confirmation_mode = nil
local my_number = nil
local typing_number = false

-- Recording state
local rec_armed_5 = false
local rec_armed_6 = false
local rec_active_5 = false
local rec_active_6 = false
local rec_start_pos_5 = 4.0  -- Start at 4 second mark in buffer
local rec_start_pos_6 = 5.0  -- Start at 5 second mark in buffer
local REC_LENGTH = 1.0       -- Record for 1 second

local AUDIO_DIRECTORY = norns.state.path .. "audio/"

local selected_param = 1
local params_list = {"fade_time"}

function init()
    midi_out = midi.connect(1)
    midi_out.channel = 16
    print("MIDI out connected:", midi_out.device)

    audio.level_cut(1.0)
    
    params:add_control("fade_time", "Fade Time", controlspec.new(0.001, 0.5, 'exp', 0.001, 0.01, 's'))
    params:set("fade_time", 0.01)

    params:set_action("fade_time", function(value)
        for voice = 1, 6 do
            softcut.fade_time(voice, value)
            softcut.level_slew_time(voice, value)
            softcut.recpre_slew_time(voice, value)
        end
    end)

    voices_init()
    sample_library, sample_keys = buffer_init()
    sequencer.init(my_grid, clock, sample_library, sample_keys)

    params:set("output_level", tonumber(sequencer.song.output_level))
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

function enc(current_encoder, value)
    if current_encoder == 1 then
        page = util.clamp(page + value, 1, 5)  -- Now 5 pages total
    elseif page == 1 then
        enc_main(current_encoder, value, sequencer)
    elseif page == 2 then
        -- Blackbox control page
        if handle_blackbox_enc(current_encoder, value) then
            -- Handled by blackbox screen
        end
    elseif page == 3 then
        enc_sampler(current_encoder, value, sequencer)
    elseif page == 4 then
        enc_load_and_save(current_encoder, value, sequencer)
    elseif page == 5 then
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
            if confirmation_mode == "load" then
                local success = sequencer.load_song(sequencer.song.filename)
                if success then
                    sequencer.grid_redraw()
                    print("Song loaded successfully")
                else
                    print("Failed to load song")
                end
                confirmation_mode = nil
            end
        elseif page == 5 then
            if value == 1 then  -- Key press
                if current_key == 2 then
                    rec_armed_5 = not rec_armed_5
                    if not rec_armed_5 then rec_active_5 = false end
                elseif current_key == 3 then
                    rec_armed_6 = not rec_armed_6
                    if not rec_armed_6 then rec_active_6 = false end
                end
            end
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
            page_blackbox(screen)
        elseif page == 3 then
            page_sampler(screen, sequencer)
        elseif page == 4 then
            page_load_and_save(screen, sequencer)
        elseif page == 5 then
            page_parameters(screen, selected_param, params_list)
        end
    end
    screen.update()
end

function my_grid.key(x, y, z)
    if page == 2 then
        -- Blackbox control page - don't trigger sequencer
        return
    end
    
    if z == 1 then
        sequencer.step_cycle(x, y)
    end
    sequencer.grid_redraw()
end

function load_buffer(path, start)
    softcut.buffer_read_mono(path, 0, start, -1, 1, 1)
end

function buffer_init()
    local sample_library = {}
    local sample_keys = {}
    local files = norns.system_glob(AUDIO_DIRECTORY .. "*.wav")
    
    -- Fixed 1 second per sample
    local SAMPLE_DURATION = 1.0
    
    for i, file in ipairs(files) do
        local filename = file:match("([^/]+)%.wav$")
        sample_keys[#sample_keys + 1] = filename
        local start = (i - 1) * SAMPLE_DURATION
        load_buffer(file, start)
        sample_library[filename] = { 
            file = file, 
            duration = SAMPLE_DURATION,
            start = start 
        }
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
    softcut.buffer(voice, 1)
    softcut.loop(voice, 0)
    softcut.enable(voice, 1)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, fade_time)
    softcut.level_slew_time(voice, fade_time)
    
    -- Configure recording voices
    if voice == 5 or voice == 6 then
        softcut.level_input_cut(1, voice, 1.0)
        softcut.level_input_cut(2, voice, 1.0)
        softcut.rec_level(voice, 1.0)
        softcut.pre_level(voice, 0.0)
    end
end
