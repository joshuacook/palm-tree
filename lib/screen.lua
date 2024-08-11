-- lib/screen.lua

function page_main(screen, sequencer, output_level, my_number)
    local bpm = sequencer.song.bpm
    local title = sequencer.song.title
    local current_grid_page = sequencer.current_grid_page
    if my_number then
        my_number = my_number .. ".."
    end
    screen.clear()
    screen.move(8, 8)
    screen.text("Song: " .. title)
    screen.move(8, 16)
    screen.text("BPM: " .. bpm)
    screen.move(8, 24)
    screen.text("Output Level: " .. (output_level == -math.huge and "-inf" or string.format("%.2f", output_level)))
    screen.move(8, 32)
    screen.text("Grid: " .. current_grid_page)
    screen.move(48, 32)
    screen.text("Active: " .. (my_number or sequencer.active_pattern_index))
    screen.move(8, 40)
    -- screen.text("MIDI Target: " .. sequencer.midi_device_names[sequencer.target_device])
    screen.move(8, 52)
    screen.text("K2: Toggle Play")
    screen.move(8, 60)
    screen.text("K3: Toggle Page")
    screen.update()
end

function page_sampler(screen, sequencer)
    screen.clear()
    screen.font_face(21)

    local column_width = 56
    local selected_drum = sequencer.selected_drum
    for i = 1, #sequencer.steps do
        local column = math.floor((i - 1) / 8)
        local row = (i - 1) % 8
        local x_pos = 8 + column * column_width
        local y_pos = 8 + row * 8
        local drum_key = sequencer.drum_keys[i]
        local drum_level = sequencer.drum_levels[i] or 1 -- Default level is 1 if not specified
        screen.move(x_pos, y_pos)
        screen.text((i == selected_drum and ">" or " ") .. " " .. drum_key .. " " .. drum_level .. "")
    end

    screen.update()
end

function page_load_and_save(screen, sequencer)
    screen.clear()
    screen.move(64, 16)
    screen.text_center("File: " .. sequencer.song.filename)
    screen.move(64, 32)
    screen.text_center("Press K2 to Load")
    screen.move(64, 48)
    screen.text_center("Press K3 to Save")
    screen.update()
end

function confirmation_screen(screen, mode)
    screen.clear()
    screen.move(64, 16)
    screen.text_center("Are you sure you")
    screen.move(64, 32)
    screen.text_center("want to " .. mode .. "?")
    screen.move(64, 48)
    screen.text_center("K2: Confirm | K3: Cancel")
    screen.update()
end
