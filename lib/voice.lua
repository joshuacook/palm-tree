local FADE_TIME = 0.01

function configure_voices()
    for voice = 1, 6 do
        configure_voice(voice)
    end
end

function configure_voice(voice)
    softcut.buffer(voice, 1)
    softcut.loop(voice, 0)
    softcut.enable(voice, 1)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, FADE_TIME)
    softcut.level_slew_time(voice, FADE_TIME)
end