function page_main(screen, bpm, output_level)
    screen.clear()
    screen.move(8, 8)
    screen.text("BPM: " .. bpm)
    screen.move(8, 16)
    screen.text("Output Level: " .. (output_level == -math.huge and "-inf" or string.format("%.2f", output_level)))
    screen.update()
end

function page_sampler(screen, sequencer, selected_drum)
    screen.clear()
    screen.move(8, 8)
    
    for i = 1, #sequencer.drum_keys do
        local y_pos = 8 + (i - 1) * 8
        screen.move(8, y_pos)
        screen.text((i == selected_drum and ">" or " ") .. i .. " " .. sequencer.drum_keys[i])
    end

    screen.update()
end

function page_load(screen, current_filename)
    screen.clear()
    screen.move(64, 32)
    screen.text_center("Load Screen")
    screen.move(64, 48)
    screen.text_center("File: " .. current_filename)
    screen.move(64, 64)
    screen.text_center("Press K2 to Load")
    screen.update()
end

function page_save(screen, current_filename)
    screen.clear()
    screen.move(64, 32)
    screen.text_center("Save Screen")
    screen.move(64, 48)
    screen.text_center("File: " .. current_filename)
    screen.move(64, 64)
    screen.text_center("Press K2 to Save")
    screen.update()
end
