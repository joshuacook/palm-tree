function enc_global(encoder, value, page)
    if encoder == 1 then
        page = util.clamp(page + value, 1, 3)
    end
end

function enc_load_and_save(encoder, value, sequencer)
    if encoder == 2 then
        local base, num, ext = string.match(current_filename, "(song%-)(%d+)(%.yaml)")
        num = util.clamp(tonumber(num) + value, 1, 999)
        current_filename = base .. string.format("%03d", num) .. ext
        sequencer.song.filename = current_filename
    end
end

function enc_main(encoder, value, sequencer)
    if encoder == 2 then
        sequencer.song.bpm = sequencer.song.bpm + value
        sequencer.clock:bpm_change(sequencer.song.bpm)
    elseif encoder == 3 then
        local current_output_level = params:get("output_level")
        sequencer.song.output_level = util.clamp(current_output_level + value, -60.00, 6.00)
        params:set("output_level", sequencer.song.output_level)
    end
end

function enc_sampler(encoder, value, sequencer, drum_keys)
    if encoder == 2 then
        local current_key_index = nil
        for i, key in ipairs(drum_keys) do
            if key == sequencer.drum_keys[selected_drum] then
                current_key_index = i
                break
            end
        end
        if current_key_index then
            local new_key_index = util.clamp(current_key_index + value, 1, #drum_keys)
            sequencer.drum_keys[selected_drum] = drum_keys[new_key_index]
        end
    elseif encoder == 3 then
        selected_drum = util.clamp(selected_drum + value, 1, #sequencer.drum_keys)
        sequencer.set_selected_drum(selected_drum)
    end
end
