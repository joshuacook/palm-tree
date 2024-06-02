-- encoders.lua

function enc_global(encoder, value, page)
    if encoder == 1 then
        page = util.clamp(page + value, 1, 3)
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
