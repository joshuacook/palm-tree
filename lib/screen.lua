-- lib/screen.lua

-- Screen state for blackbox control
local blackbox_state = {
    selected_pad = 1,
    recording = false,
    armed_pads = {},
    loop_length = 1,  -- In bars
    -- Store which middle row is lit for each column (2-7 valid)
    column_states = {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}
}

-- Handle grid input for blackbox page
function handle_grid_input(x, y, z)
    if z == 1 then  -- Only handle press
        if y >= 2 and y <= 7 then
            -- Middle rows - single value per column
            blackbox_state.column_states[x] = y
            return true
        end
    end
    return false
end

-- Draw grid for blackbox page
function draw_blackbox_grid(g)
    g:all(0)
    -- Draw middle row selections
    for x = 1,16 do
        g:led(x, blackbox_state.column_states[x], 15)
    end
    -- Top row for recording
    for x = 1,16 do
        if blackbox_state.armed_pads[x] then
            g:led(x, 1, blackbox_state.recording and 15 or 8)
        end
    end
    -- Bottom row for playback starts unlit
    for x = 1,16 do
        g:led(x, 8, 0)  -- Unlit by default
    end
    g:refresh()
end

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
    screen.move(8, 52)
    screen.text("K2: Toggle Play")
    screen.move(8, 60)
    screen.text("K3: Next Page")
    screen.update()
end

function page_blackbox(screen)
    screen.clear()
    screen.level(15)
    
    if blackbox_state.recording then
        -- Recording mode layout
        screen.move(8, 16)
        screen.text("RECORDING MODE")
        
        screen.move(8, 32)
        screen.text("TOP: Record Controls")
        screen.move(8, 40) 
        screen.text("MID: Loop Length (1-16)")
        screen.move(8, 48)
        screen.text("BOT: Playback Controls")
        
        screen.move(8, 60)
        screen.text("Length: " .. (blackbox_state.loop_length or "1") .. " bars")
    else
        -- Normal mode
        screen.move(8, 16)
        screen.text("BLACKBOX CONTROL")
        
        screen.move(8, 32)
        screen.text("PAD " .. blackbox_state.selected_pad)
        
        -- Draw controls
        screen.move(8, 52)
        screen.text("K2: Start Recording")
        screen.move(8, 60)
        screen.text("K3: Clear Pad")
    end
    
    screen.update()
end

-- Handle blackbox screen input
function handle_blackbox_enc(n, d)
    if n == 2 then
        -- Select pad
        blackbox_state.selected_pad = util.clamp(blackbox_state.selected_pad + d, 1, 16)
        return true
    end
    return false
end

function handle_blackbox_key(n, z)
    if n == 2 and z == 1 then
        -- Toggle record arm
        blackbox_state.armed_pads[blackbox_state.selected_pad] = not blackbox_state.armed_pads[blackbox_state.selected_pad]
        return true
    elseif n == 3 and z == 1 then
        -- Toggle recording
        blackbox_state.recording = not blackbox_state.recording
        return true
    end
    return false
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

function page_parameters(screen, selected_param, params_list)
    screen.clear()
    screen.font_face(1)
    screen.font_size(8)
    screen.level(15)
    
    screen.move(64, 10)
    screen.text_center("Parameters")
    
    for i, param_name in ipairs(params_list) do
        screen.move(10, 20 + i * 10)
        if i == selected_param then
            screen.level(15)
            screen.text("> " .. param_name .. ": " .. string.format("%.3f", params:get(param_name)))
        else
            screen.level(5)
            screen.text("  " .. param_name .. ": " .. string.format("%.3f", params:get(param_name)))
        end
    end
    
    screen.move(10, 60)
    screen.level(5)
    screen.text("E2: Select Parameter")
    screen.move(10, 70)
    screen.text("E3: Adjust Value")
    
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
