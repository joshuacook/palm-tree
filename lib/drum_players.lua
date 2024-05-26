include('lib/player')

local drums = {
    kick = {
        file = "audio/common/808/808-BD.wav",
        start = 0,
        duration = 0.255,
    },
    snare = {
        file = "audio/common/808/808-SD.wav",
        start = 0.255,
        duration = 0.387,
    },
    ohhihat = {
        file = "audio/common/808/808-OH.wav",
        start = 0.642,
        duration = 0.291,
    },
    clhihat = {
        file = "audio/common/808/808-CH.wav",
        start = 0.933,
        duration = 0.133,
    },
    cymbal = {
        file = "audio/common/808/808-CY.wav",
        start = 1.066,
        duration = 0.834,
    },
}

configure_voice(1, drums.kick.file, drums.kick.start)
configure_voice(2, drums.snare.file, drums.snare.start)
configure_voice(3, drums.ohhihat.file, drums.ohhihat.start)
configure_voice(3, drums.clhihat.file, drums.clhihat.start)
configure_voice(3, drums.cymbal.file, drums.cymbal.start)

drum_players = {
    function(value) play_voice(1, value, drums.kick.start, drums.kick.duration) end,
    function(value) play_voice(2, value, drums.snare.start, drums.snare.duration) end,
    function(value) play_voice(3, value, drums.ohhihat.start, drums.ohhihat.duration) end,
    function(value) play_voice(3, value, drums.clhihat.start, drums.clhihat.duration) end,
    function(value) play_voice(3, value, drums.cymbal.start, drums.cymbal.duration) end
}
return drum_players

