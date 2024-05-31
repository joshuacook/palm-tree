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
                sequencer.load_song(current_filename)
                sequencer.grid_redraw()
            elseif key == 3 then
                -- Cancel the action
            end
        elseif confirmation_mode == "save" then
            if key == 2 then
                sequencer.save_song(current_filename)
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
            sequencer.clock:start()
            sequencer.playing = true
        end
    elseif key == 3 and value == 1 then
        if sequencer.current_page == 1 then
            sequencer.set_selected_drum(9)
        else
            sequencer.set_selected_drum(1)
        end
    end
end

