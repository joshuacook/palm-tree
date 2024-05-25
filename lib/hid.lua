-- lib/hid.lua

local hid = {}

function hid.setup(beatclock)
    hid.clock = beatclock
end

hid.hid_to_device = {
    [313] = "switch_1_up",
    [312] = "switch_1_down",
    [311] = "switch_2_up",
    [310] = "switch_2_down",
    [309] = "switch_3_up",
    [308] = "switch_3_down",
    [307] = "switch_4_up",
    [306] = "switch_4_down",
    [305] = "switch_5_up",
    [304] = "switch_5_down",
    [712] = "dial_1_left",
    [713] = "dial_1_right",
    [714] = "dial_2_left",
    [715] = "dial_2_right",
    [716] = "dial_3_left",
    [717] = "dial_3_right",
    [718] = "dial_4_left",
    [719] = "dial_4_right",
    [319] = "button_1",
    [318] = "button_2",
    [317] = "button_3",
    [316] = "button_4",
    [315] = "button_5",
}

hid.playing = true

function hid.connect()
    local keyb = hid.connect()
    keyb.event = hid.keyboard_event
end

function hid.keyboard_event(typ, code, val)
    print("hid.event ", typ, code, val)
    if code == 312 then
        hid.playing = false
        hid.clock:stop()
    elseif code == 313 then
        hid.playing = true
        hid.clock:start()
    end
end

return hid