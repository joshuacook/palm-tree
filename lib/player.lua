local fade_time = 0.01

function configure_voice(voice, path, start)
    softcut.buffer_read_mono(_path.dust..path, 0, start, -1, 1, 1)        
    softcut.loop(voice, 0)
    softcut.enable(voice, 1)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, fade_time)
    softcut.level_slew_time(voice, 0.01)
end

function play_voice(voice, value, start, dur)
    softcut.play(voice, 0)
    softcut.level(voice, value*0.33)
    softcut.loop_start(voice, start)
    softcut.loop_end(voice, start + dur - fade_time)
    softcut.position(voice, start)
    softcut.play(voice, 1)
end