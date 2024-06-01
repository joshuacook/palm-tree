-- machine.lua

include('lib/encoders')
my_hid = include('lib/hid')
include('lib/keys')
include('lib/screen')
sequencer = include('lib/sequencer')

local my_grid = grid.connect()

local page = 1
local confirmation_mode = nil
local my_number = nil
local typing_number = false

function init()
    audio.level_cut(1.0)
    softcut.buffer_clear()

    interface = hid.connect()
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

function keyboard.code(code, value)
    if value == 1 then
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
