local patterns_directory = _path.dust .. "code/beat/patterns/"

function load_steps_from_file(filename)
    local file = io.open(patterns_directory .. filename, "r")
    if file then
        local content = file:read("*a")
        file:close()

        local row = 1
        for line in string.gmatch(content, "[^\r\n]+") do
            local col = 1
            for step in string.gmatch(line, "%d") do
                steps[row][col] = tonumber(step)
                col = col + 1
            end
            row = row + 1
        end
    else
        print("Failed to open file: " .. filename)
    end
end

function save_steps_to_file(filename)
    local file = io.open(patterns_directory .. filename, "w")

    if file then
        for i = 1, 5 do
            local line = ""
            for j = 1, 16 do
                line = line .. steps[i][j] .. " "
            end
            file:write(line:sub(1, -2) .. "\n")
        end
        file:close()
        print("Steps saved to " .. filename)
    else
        print("Failed to save steps to file")
    end
end