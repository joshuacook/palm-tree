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
local FADE_TIME = 0.01

local AUDIO_DIRECTORY = norns.state.path .. "audio/"

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
    softcut.buffer(voice, 1)
    softcut.loop(voice, 0)
    softcut.enable(voice, 1)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, FADE_TIME)
    softcut.level_slew_time(voice, FADE_TIME)
end

function init()
    audio.level_cut(1.0)

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
    end
    redraw()
end

function key(current_key, value)
    if confirmation_mode then
        confirmation_mode = key_confirmation_mode(current_key, value, sequencer, confirmation_mode, redraw)
    else
        if page == 1 or page == 2 then
            key_main(current_key, value, sequencer)
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
