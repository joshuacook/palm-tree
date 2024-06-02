--hid.lua

my_hid = {}

function my_hid.init(sequencer, interface, params)
    my_hid.interface = interface
    my_hid.interface.event = my_hid.event_handler
    my_hid.output_level_position = 7
    my_hid.output_level = -30.00
    my_hid.min_val = -57.0
    my_hid.max_val = 6.0
    my_hid.sequencer = sequencer
    my_hid.params = params
    my_hid.screen = screen
end

function my_hid.compute_output_level(code)
    if code == 712 then
        my_hid.output_level_position = my_hid.output_level_position - 1
    elseif code == 713 then
        my_hid.output_level_position = my_hid.output_level_position + 1
    end

    if my_hid.output_level_position < 0 then
        my_hid.output_level_position = 0
    elseif my_hid.output_level_position > 15 then
        my_hid.output_level_position = 15
    end
    my_hid.output_level = my_hid.min_val + (my_hid.max_val - my_hid.min_val) * (my_hid.output_level_position - 1) / 14
end

function my_hid.event_handler(type, code, val)
    if code == 312 then
        my_hid.sequencer.clock:stop()
        my_hid.sequencer.playing = false
    elseif code == 313 then
        my_hid.sequencer.clock:start()
        my_hid.sequencer.playing = true
    elseif val == 1 and (code == 712 or code == 713) then
        my_hid.compute_output_level(code)
        my_hid.params:set("output_level", my_hid.output_level)
    end
end

return my_hid

