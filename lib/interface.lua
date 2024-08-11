-- lib/interface.lua

my_hid = {}

function enc_global(encoder, value, page)
    if encoder == 1 then
        page = util.clamp(page + value, 1, 4)
    end
    return page
end

function enc_load_and_save(encoder, value, sequencer)
    local current_filename = sequencer.song.filename
    if encoder == 2 then
        local base, num, ext = string.match(current_filename, "(song%-)(%d+)(%.yaml)")
        num = (tonumber(num) + value - 1) % 999 + 1
        current_filename = base .. string.format("%03d", num) .. ext
        sequencer.song.filename = current_filename
    end
end

function enc_main(encoder, value, sequencer)
    if encoder == 2 then
        sequencer.song.bpm = util.clamp(sequencer.song.bpm + value, 20, 300)
        sequencer.clock:bpm_change(sequencer.song.bpm)
    elseif encoder == 3 then
        local current_output_level = params:get("output_level")
        sequencer.song.output_level = util.clamp(current_output_level + value, -60.00, 6.00)
        params:set("output_level", sequencer.song.output_level)
    end
end

function enc_sampler(encoder, value, sequencer)
    if encoder == 2 then
        local selected_drum = sequencer.selected_drum
        local drum = sequencer.drum_keys[selected_drum]

        local current_key_index = nil

        for i, key in ipairs(sequencer.sample_keys) do
            if key == drum then
                current_key_index = i
                break
            end
        end

        if current_key_index then
            local n_samples = #sequencer.sample_keys
            local new_key_index = util.clamp(current_key_index + value, 1, n_samples)

            if new_key_index >= 1 and new_key_index <= #sequencer.sample_keys then
                sequencer.drum_keys[selected_drum] = sequencer.sample_keys[new_key_index]
            else
                print("Error: new_key_index is out of range")
            end
        else
            print("Error: current_key_index is nil")
        end
    elseif encoder == 3 then
        local selected_drum = sequencer.selected_drum
        selected_drum = (selected_drum + value - 1) % sequencer.n_players + 1
        sequencer.set_selected_drum(selected_drum)
    end
end

function key_confirmation_mode(
    key,
    value,
    sequencer,
    confirmation_mode,
    redraw
)
    if value == 1 then
        if confirmation_mode == "load" then
            if key == 2 then
                sequencer.load_song(sequencer.song.filename)
                sequencer.grid_redraw()
            elseif key == 3 then
                -- Cancel the action
            end
        elseif confirmation_mode == "save" then
            if key == 2 then
                sequencer.save_song()
            elseif key == 3 then
                -- Cancel the action
            end
        end
        confirmation_mode = nil
        if page == 3 then
            redraw()
        end
    end
    return confirmation_mode
end

function key_load_and_save(key, value)
    if key == 2 and value == 1 then
        return "load"
    elseif key == 3 and value == 1 then
        return "save"
    end
    return nil
end

function key_main(key, value, sequencer)
    if key == 2 and value == 1 then
        if sequencer.playing then
            sequencer.clock:stop()
            sequencer.playing = false
        else
            sequencer.beat_position = 0
            sequencer.clock:start()
            sequencer.playing = true
        end
    elseif key == 3 and value == 1 then
        if sequencer.current_grid_page == 1 then
            sequencer.set_selected_drum(9)
        else
            sequencer.set_selected_drum(1)
        end
    end
end

function my_hid.init(sequencer, interface, params)
    my_hid.interface = interface
    my_hid.interface.event = my_hid.event_handler
    my_hid.output_level_position = 7
    my_hid.output_level = -30.00
    my_hid.min_val = -57.0
    my_hid.max_val = 6.0
    my_hid.sequencer = sequencer
    my_hid.params = params
    my_hid.screen = screen
end

function my_hid.compute_output_level(code)
    if code == 712 then
        my_hid.output_level_position = my_hid.output_level_position - 1
    elseif code == 713 then
        my_hid.output_level_position = my_hid.output_level_position + 1
    end

    if my_hid.output_level_position < 0 then
        my_hid.output_level_position = 0
    elseif my_hid.output_level_position > 15 then
        my_hid.output_level_position = 15
    end
    my_hid.output_level = my_hid.min_val + (my_hid.max_val - my_hid.min_val) * (my_hid.output_level_position - 1) / 14
end

function my_hid.event_handler(type, code, val)
    if code == 312 then
        my_hid.sequencer.clock:stop()
        my_hid.sequencer.playing = false
    elseif code == 313 then
        my_hid.sequencer.clock:start()
        my_hid.sequencer.playing = true
    elseif val == 1 and (code == 712 or code == 713) then
        my_hid.compute_output_level(code)
        my_hid.params:set("output_level", my_hid.output_level)
    end
end

return my_hid

