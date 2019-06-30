# iroot-dev
[**iroot**](https://github.com/abobija/iroot) esp32 device

## Usage

This example will **subscribe** device to `/home/room/led` **channel**. Controlling LED attached to gpio 2 can be done by sending **data** `ON` or `OFF` to the **topic** `state`.

```lua
local function init_dev()
    local channel_path = '/home/room/led'
    local led_gpio = 2

    gpio.config({ gpio = led_gpio, dir = gpio.IN_OUT })
    gpio.write(led_gpio, 0)

    require('iroot_dev')('192.168.0.105:8080', 'dev32', 'test1234')
        .on('connection', function(dev)
            dev.subscribe(channel_path)
        end)
        .on('message', function(channel, topic, data)
            if channel == channel_path and topic == 'state' then
                if data == 'ON' then
                    gpio.write(led_gpio, 1)
                elseif data == 'OFF' then
                    gpio.write(led_gpio, 0)
                end
            end
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
