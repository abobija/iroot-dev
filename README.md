# iroot-dev
[**iroot**](https://github.com/abobija/iroot) esp32 device

## Usage

This example will **subscribe** device to `/home/room/led` **channel**. Controlling LED attached to gpio 2 can be done by sending **data** `ON` or `OFF` to the **topic** `state`.

_Device 1_

```lua
local dev = nil

local function init_dev()
    if dev ~= nil then return end

    local led_gpio = 2

    gpio.config({ gpio = led_gpio, dir = gpio.IN_OUT })
    gpio.write(led_gpio, 0)

    dev = require('iroot_dev')('192.168.0.105:8080', 'dev32', 'test1234')
        .on('connection', function(dev)
            dev.subscribe('/home/room/led', function(topic, data)
                if topic == 'state' then
                    if data == 'ON' then
                        gpio.write(led_gpio, 1)
                    elseif data == 'OFF' then
                        gpio.write(led_gpio, 0)
                    end
                end
            end)
        end)
        .connect()
end

wifi.mode(wifi.STATION)

wifi.sta.config({
    ssid = "YOUR_WIFI_SSID",
    pwd  = "PLS_LET_ME_IN",
    auto = false
})

wifi.sta.on('got_ip', init_dev)

wifi.start()
wifi.sta.connect()
```

And this code will **publish** `ON` | `OFF` **data** to **topic** `state` on **channel** `/home/room/led` every 5 sec.

_Device 2_

```lua
local dev = nil

local function init_dev()
    if dev ~= nil then return end
    
    local channel_path = '/home/room/led'
    local state_for_send = true
    local timer = tmr.create()
    
    timer:register(5000, tmr.ALARM_AUTO, function() 
         if state_for_send == true then
            dev.publish(channel_path, 'state', 'OFF')
            state_for_send = false
         else
            dev.publish(channel_path, 'state', 'ON')
            state_for_send = true
         end
    end)

    dev = require('iroot_dev')('192.168.0.105:8080', 'dev32-led', 'test1234')
        .on('connection', function(_dev)
            dev.subscribe(channel_path)

            timer:start()
        end)
        .connect()
end

wifi.mode(wifi.STATION)

wifi.sta.config({
    ssid = "YOUR_WIFI_SSID",
    pwd  = "PLS_LET_ME_IN",
    auto = false
})

wifi.sta.on('got_ip', init_dev)

wifi.start()
wifi.sta.connect()
```
