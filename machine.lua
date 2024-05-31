include('lib/encoders')
my_hid = include('lib/hid')
include('lib/keys')
include('lib/screen')
sequencer = include('lib/sequencer')

local my_grid = grid.connect()
local page = 1
local audio_directory = _path.dust .. "audio/palm/"
local current_filename = "song-001.yaml"

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
    
    load_drum_keys()
    
    interface = hid.connect()
    print(interface)
    if interface ~= nil then
        my_hid.init(sequencer, interface, params)
    end

    sequencer.init(my_grid)
    
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
        enc_global(current_encoder, value, page)
    elseif page == 1 then
        enc_main(current_encoder, value, sequencer)
    elseif page == 2 then
        enc_sampler(current_encoder, value, sequencer, drum_keys)
    elseif page == 3 then
        enc_load_and_save(current_encoder, value, sequencer)
    end
    redraw()
end

function key(current_key, value)
    if confirmation_mode then
        confirmation_mode = key_confirmation_mode(current_key, value, sequencer, confirmation_mode, redraw)
    else
        if page == 1 then
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
            page_main(screen, sequencer, output_level)
        elseif page == 2 then
            page_sampler(screen, sequencer, selected_drum)
        elseif page == 3 then
            page_load_and_save(screen, current_filename)
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
