function play(beat_position, players)
    for y = 1, 5 do
        local value = steps[y][beat_position]
        if value > 0 then
            players[y](value)
        end
    end
end