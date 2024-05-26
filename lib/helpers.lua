function compute_output_level(code, position)
    if code == 712 then
        position = position - 1
    else
        position = position + 1
    end
    if position >= 1 and position <= 15 then
        local min_val = -57.0
        local max_val = 6.0
        local output_level = ((position - 1) / 14) * (max_val - min_val) + min_val
        return output_level, position
    end
end

function draw_beat(g, beat_position)
    g:led(beat_position, 8, 15)
    g:refresh()
end

function grid_redraw(g, steps)
    g:all(0)
    for i = 1, 16 do
        for j = 1, 5 do
            local step_value = steps[j][i]
            if step_value > 0 then
                g:led(i, j, step_value * 5)
            end
        end
    end
    g:refresh()
end

function redraw(screen, page, bpm, params, current_filename)
    screen.clear()
    if page == 1 then
        screen.move(8, 8)
        screen.text("BPM: " .. bpm)
        screen.move(8, 16)
        local output_level = params:get("output_level")
        screen.text("Output Level: " .. (output_level == -math.huge and "-inf" or string.format("%.2f", output_level)))
    elseif page == 2 then
        screen.move(64, 32)
        screen.text_center("Load Screen")
        screen.move(64, 48)
        screen.text_center("File: " .. current_filename)
        screen.move(64, 64)
        screen.text_center("Press K2 to Load")
    elseif page == 3 then
        screen.move(64, 32)
        screen.text_center("Save Screen")
        screen.move(64, 48)
        screen.text_center("File: " .. current_filename)
        screen.move(64, 64)
        screen.text_center("Press K2 to Save")
    end
    screen.update()
end