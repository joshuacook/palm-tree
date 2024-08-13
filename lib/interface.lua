-- lib/interface.lua

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
        local new_bpm = util.clamp(params:get("clock_tempo") + value, 20, 300)
        params:set("clock_tempo", new_bpm)
        sequencer.song.bpm = new_bpm
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

function key_main(key, value, sequencer, midi_out)
    if key == 2 and value == 1 then
        if sequencer.clock.id then
            sequencer.clock.transport.stop()
            midi_out:stop()
        else
            sequencer.beat_position = 0
            sequencer.clock.transport.start()
            midi_out:start()
        end
    elseif key == 3 and value == 1 then
        if sequencer.current_grid_page == 1 then
            sequencer.set_selected_drum(9)
        else
            sequencer.set_selected_drum(1)
        end
    end
end