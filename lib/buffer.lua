-- lib/buffer.lua

local AUDIO_DIRECTORY = norns.state.path .. "audio/"

local function get_duration(file)
    local handle = io.popen("soxi -D " .. file)
    local result = handle:read("*a")
    handle:close()
    return tonumber(result)
end

function buffer_init()
    local sample_library = {}
    local sample_keys = {}
    local files = norns.system_glob(AUDIO_DIRECTORY .. "*.wav")
    local start = 0
    for _, file in ipairs(files) do
        local filename = file:match("([^/]+)%.wav$")
        sample_keys[#sample_keys + 1] = filename
        local duration = get_duration(file)
        load_buffer(file, start)
        sample_library[filename] = { file = file, duration = duration, start = start }
        start = start + duration
    end

    
    for _, drum in ipairs(sample_library) do
        drum.start = start
        load_buffer(drum.file, start)
        start = start + drum.duration
    end
    return sample_library, sample_keys
end

function load_buffer(path, start)
    softcut.buffer_read_mono(path, 0, start, -1, 1, 1)
end