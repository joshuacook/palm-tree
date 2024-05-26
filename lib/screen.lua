function page_1(screen, bpm, output_level)
    screen.clear()
    screen.move(8, 8)
    screen.text("BPM: " .. bpm)
    screen.move(8, 16)
    screen.text("Output Level: " .. (output_level == -math.huge and "-inf" or string.format("%.2f", output_level)))
    screen.update()
end

function page_2(screen, current_filename)
    screen.clear()
    screen.move(64, 32)
    screen.text_center("Load Screen")
    screen.move(64, 48)
    screen.text_center("File: " .. current_filename)
    screen.move(64, 64)
    screen.text_center("Press K2 to Load")
    screen.update()
end

function page_3(screen, current_filename)
    screen.clear()
    screen.move(64, 32)
    screen.text_center("Save Screen")
    screen.move(64, 48)
    screen.text_center("File: " .. current_filename)
    screen.move(64, 64)
    screen.text_center("Press K2 to Save")
    screen.update()
end

