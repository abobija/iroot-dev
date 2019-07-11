local M = {}

local ws = nil
local connected = false
local on_connection_callback = nil
local subscriptions = {}

local function add_subscription(channel, callback)
    table.insert(subscriptions, {
        channel  = channel,
        callback = callback
    })
end

local function get_subscription(channel)
    for _, s in pairs(subscriptions) do
        if s.channel == channel then
            return s
        end
    end

    return nil
end

M.on = function(callback_name, callback_foo)
    if callback_name == 'connection' then
        on_connection_callback = callback_foo
    end

    return M
end

M.connect = function()
    ws.connect('ws://' .. M.url, { 
        auto_reconnect = true,
        extra_handshake_headers = {
            { 'Authorization', 'Basic ' .. M.auth_key }
        }
    })

    return M
end

M.subscribe = function(channel, message_callback)
    if connected == false then
        print('iroot device not connected so cannot subscribe')
        return
    end

    if message_callback ~= nil then
        add_subscription(channel, message_callback)
    end

    ws.send(sjson.encode({
        type = 'subscribe',
        channel = channel
    }))
	
	return M
end

M.publish = function(channel, topic, data)
    if connected == false then
        print('iroot device not connected so cannot publish')
        return
    end

    ws.send(sjson.encode({
        type = 'publish',
        channel = channel,
        topic = topic,
        data = data
    }))

    return M
end

return function(url, username, password)
    M.url = url
    M.auth_key = encoder.toBase64(username .. ':' .. password)
    
    ws = require('ws32_client')
        .on('receive', function(data, ws)
            --print('ws received: ', data)

            if #subscriptions == 0 then return end

            local ok, msg = pcall(sjson.decode, data)

            if ok then
                local sub = get_subscription(msg.channel)
                
                if sub ~= nil then
                    sub.callback(msg.topic, msg.data)
                end
            end
        end)
        .on('connection', function(ws)
            --print('ws connected')
            connected = true
            
            if on_connection_callback ~= nil then
                on_connection_callback(M)
            end
        end)
        .on('disconnection', function(err, ws)
            --print('ws disconnected')
            connected = false
        end)

    return M
end
