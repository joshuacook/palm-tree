function page_main(screen, sequencer, output_level)
    local bpm = sequencer.song.bpm
    local title = sequencer.song.title
    local current_grid_page = sequencer.current_page

    screen.clear()
    screen.move(8, 8)
    screen.text("Song: " .. title)
    screen.move(8, 16)
    screen.text("BPM: " .. bpm)
    screen.move(8, 24)
    screen.text("Output Level: " .. (output_level == -math.huge and "-inf" or string.format("%.2f", output_level)))
    screen.move(8, 32)
    screen.text("Grid: " .. current_grid_page)
    screen.move(8, 52)
    screen.text("K2: Toggle Play")
    screen.move(8, 60)
    screen.text("K3: Toggle Page")
    screen.update()
end

function page_sampler(screen, sequencer, selected_drum)
    screen.clear()
    screen.font_face(21)

    local column_width = 64
 
    for i = 1, #sequencer.drum_keys do
        local column = math.floor((i - 1) / 8)
        local row = (i - 1) % 8
        local x_pos = 8 + column * column_width
        local y_pos = 8 + row * 8
     
        screen.move(x_pos, y_pos)
        screen.text((i == selected_drum and ">" or " ") .. string.format("%02d", i) .. " " .. sequencer.drum_keys[i])
    end

    screen.update()
end


function page_load_and_save(screen, current_filename)
    screen.clear()
    screen.move(64, 16)
    screen.text_center("File: " .. current_filename)
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