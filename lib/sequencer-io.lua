-- sequencer-io.lua

local PATTERNS_DIRECTORY = _path.dust .. "code/palm-tree/songs/"

function load_song(sequencer, filename)
    local full_path = PATTERNS_DIRECTORY .. filename
    local file, err = io.open(full_path, "r")

    if file then
        local content = file:read("*a")
        file:close()

        local song = parse_song(content)
        sequencer.song = song
        print("title: " .. song.title)
        print("bpm: " .. song.bpm)
        print("output_level: ", song.output_level)
        print("patterns: " .. #song.patterns)
        sequencer.song.filename = filename
        sequencer.song.patterns = parse_patterns(song.patterns)

        sequencer.clock:bpm_change(sequencer.song.bpm)
    else
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
    end
end

function parse_patterns(patterns)
    local parsed_patterns = {}
    for _, pattern_str in ipairs(patterns) do
        local pattern = {}
        local row = 1
        for line in string.gmatch(pattern_str, "[^\n]+") do
            local col = 1
            pattern[row] = {}
            for step in string.gmatch(line, "%S+") do
                if col <= 16 then
                    pattern[row][col] = tonumber(step)
                elseif col == 17 then
                    pattern[row].drum_key = step
                end
                col = col + 1
            end
            row = row + 1
        end
        table.insert(parsed_patterns, pattern)
    end
    return parsed_patterns
end

function parse_song(content)
    local song = {}
    local metadata_section, patterns_section = content:match("(.-)\n+patterns:\n(.*)")
    if not metadata_section:match("\n$") then
        metadata_section = metadata_section .. "\n"
    end

    for key, value in metadata_section:gmatch("([%w_]+):%s*([^\n]+)\n") do
        local num_value = tonumber(value)
        if num_value then
            song[key] = num_value
        else
            song[key] = value:match('^"(.*)"$') or value
        end
    end
    
    song.patterns = {}
    local current_pattern = nil
    local line_count = 0

    for line in patterns_section:gmatch("[^\r\n]+") do
        if line:find("%- |") then
            if current_pattern then
                table.insert(song.patterns, current_pattern)
            end
            current_pattern = ""
            line_count = 0
        elseif current_pattern then
            current_pattern = current_pattern .. line .. "\n"
            line_count = line_count + 1
            if line_count == 16 then
                table.insert(song.patterns, current_pattern)
                current_pattern = nil
            end
        end
    end

    if current_pattern then
        table.insert(song.patterns, current_pattern)
    end

    return song
end


function save_song(sequencer)
    local filename = sequencer.song.filename
    local full_path = PATTERNS_DIRECTORY .. filename
    local file, err = io.open(full_path, "w")
    if file then
        local serialized_patterns = serialize_patterns(sequencer.song.patterns)
        sequencer.song.patterns = serialized_patterns
        file:write(serialize_song(sequencer.song))
        file:close()
    else
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
    end
end

function serialize_song(song)
    local serialized = ""
    for key, value in pairs(song) do
        if key ~= "patterns" and key ~= "filename" then
            if type(value) == "string" then
                serialized = serialized .. key .. ': "' .. value .. '"\n'
            else
                serialized = serialized .. key .. ': ' .. tostring(value) .. '\n'
            end
        end
    end
    serialized = serialized .. "patterns:\n"
    for _, pattern in ipairs(song.patterns) do
        serialized = serialized .. "  - |\n" .. pattern .. "\n\n"
    end
    return serialized
end

function serialize_patterns(patterns)
    local serialized_patterns = {}
    for _, pattern in ipairs(patterns) do
        local pattern_str = ""
        for _, row in ipairs(pattern) do
            for col = 1, 16 do
                if col == 1 then
                    pattern_str = pattern_str .. "    "
                end
                pattern_str = pattern_str .. row[col] .. " "
            end
            pattern_str = pattern_str .. (row.drum_key or "default_key") .. "\n"
        end
        table.insert(serialized_patterns, pattern_str)
    end
    return serialized_patterns
end
