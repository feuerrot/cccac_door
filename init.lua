bmp180 = require("bmp180")

door_open = "none"

m = mqtt.Client("clientid", 120, nil, nil)

function led_red()
	led:fill(0, 255, 0)
	led:write()
end

function led_blue()
	led:fill(0, 0, 255)
	led:write()
end

function led_green()
	led:fill(255, 0, 0)
	led:write()
end

function led_white()
	led:fill(255, 255, 255)
	led:write()
end

function led_off()
	led:fill(0,0,0)
	led:write()
end

function gpio_init()
	gpio.mode(0, gpio.INPUT, 1)
end

function gpio_door()
	if (gpio.read(0) == 0 and door_open ~= 0) then
		door_open = 0
		m:publish("door/status", "close", 0, 1)
	elseif (gpio.read(0) == 1 and door_open ~= 1) then
		door_open = 1
		m:publish("door/status", "open", 0, 1)
	end
end

function bmp180_init()
	print("bmp_init()")
	bmp180.init(1, 2)
end

function bmp180_senddata()
	bmp180.read(2)
	t = bmp180.getTemperature()
	t_t = (t/10) .. "." .. (t%10)
	p = bmp180.getPressure()
	p_t = (p/100) .. "." .. (p%100)
	m:publish("sensors/door/temperature", t_t, 0, 1)
	m:publish("sensors/door/pressure", p_t, 0, 1)
end

function wlan_init()
	print("wlan_init()")
	wifi.sta.eventMonReg(wifi.STA_GOTIP, function() mqtt_init() end)

	wifi.setmode(wifi.STATION)
	wifi.sta.config("CCCAC_PSK_2.4GHz", "23cccac42")
	wifi.sta.eventMonStart()
	print(wifi.sta.getip())
end

function mqtt_parsemsg(client, topic, data)
	if topic == "status/status" then
		mqtt_parsestatus(data)
	end
end

function mqtt_parsestatus(msg)
	if msg == "public" then
		led_green()
	elseif msg == "private" then
		led_blue()
	elseif msg == "closed" then
		led_red()
	end
end

function mqtt_subscribe()
	print("mqtt_subscribe()")
	m:subscribe("status/status",0, function(client) print("subscribe success") end)
	tmr.start(0)
	tmr.start(1)
end

function mqtt_init()
	print("mqtt_init()")
	m:on("message", mqtt_parsemsg)
	m:on("connect", function(client) mqtt_subscribe() end)

	m:connect("172.20.122.11")
end

function timer_init()
	print("timer_init()")
	tmr.register(0, 100, tmr.ALARM_AUTO, gpio_door)
	tmr.register(1, 10000, tmr.ALARM_AUTO, bmp180_senddata)
end

ws2812.init()
led = ws2812.newBuffer(10,3)
led_off()

gpio_init()
wlan_init()
timer_init()
bmp180_init()

-- mqtt_init()
