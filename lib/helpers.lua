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