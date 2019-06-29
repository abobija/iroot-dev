local M = {}

local ws = nil
local connected = false
local on_connection_callback = nil
local on_message_callback = nil

M.on = function(callback_name, callback_foo)
    if callback_name == 'connection' then
        on_connection_callback = callback_foo
    elseif callback_name == 'message' then
        on_message_callback = callback_foo
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

M.subscribe = function(channel)
    if connected == false then
        print('iroot device not connected so cannot subscribe')
        return
    end

    ws.send(sjson.encode({
        type = 'subscribe',
        channel = channel
    }))
	
	return M
end

return function(url, username, password)
    M.url = url
    M.auth_key = encoder.toBase64(username .. ':' .. password)
    
    ws = require('ws32_client')
        .on('receive', function(data, ws)
            --print('ws received: ', data)

            if on_message_callback == nil then return end

            local ok, msg = pcall(sjson.decode, data)

            if ok then
                on_message_callback(msg.channel, msg.topic, msg.data)
            end
        end)
        .on('connection', function(ws)
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