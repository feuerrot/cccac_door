bmp180 = require("bmp180")

door_open = "none"
door_move = "none"
door_move_corridor = "none"
shutdown = 0
status = "public"

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
	gpio.mode(5, gpio.INPUT, 0)
	gpio.mode(6, gpio.INPUT, 0)
end

function gpio_move()
	if (gpio.read(5) == 0 and door_move ~= 0) then
		door_move = 0
		m:publish("sensors/door/movement", "0", 0, 1)
	elseif (gpio.read(5) == 1 and door_move ~= 1) then
		door_move = 1
		m:publish("sensors/door/movement", "1", 0, 1)
	end
	if (gpio.read(6) == 0 and door_move_corridor ~= 0) then
		door_move_corridor = 0
		m:publish("sensors/door/movement_corridor", "0", 0, 1)
	elseif (gpio.read(6) == 1 and door_move_corridor ~= 1) then
		door_move_corridor = 1
		m:publish("sensors/door/movement_corridor", "1", 0, 1)
	end
end

function gpio_door()
	if (gpio.read(0) == 0 and door_open ~= 0) then
		door_open = 0
		m:publish("sensors/door/open", "0", 0, 1)
	elseif (gpio.read(0) == 1 and door_open ~= 1) then
		door_open = 1
		m:publish("sensors/door/open", "1", 0, 1)
	end
end

function bmp180_init()
	print("bmp_init()")
	bmp180.init(1, 2)
end

function bmp180_senddata()
	bmp180.read(2)
	local t = bmp180.getTemperature()
	local t_t = (t/10) .. "." .. (t%10)
	local p = bmp180.getPressure()
	local p_t = (p/100) .. "." .. (p%100)
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
	elseif topic == "runlevel" then
		mqtt_parserunlevel(data)
	end
end

function mqtt_parsestatus(msg)
	status = msg
	if shutdown == 0 then
		if status == "public" then
			led_green()
		elseif status == "private" then
			led_blue()
		elseif status == "closed" then
			led_red()
		end
	end
end

function mqtt_parserunlevel(msg)
	if msg == "launch" then
		shutdown = 0
		mqtt_parsestatus(status)
	elseif msg == "shutdown" then
		shutdown = 1
		led_off()
	end
end

function mqtt_subscribe()
	print("mqtt_subscribe()")
	m:subscribe("status/status",0, function(client) print("subscribe success: status/status") end)
	m:subscribe("runlevel",0, function(client) print("subscribe success: runlevel") end)
	tmr.start(0)
	tmr.start(1)
	tmr.start(2)
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
	tmr.register(2, 100, tmr.ALARM_AUTO, gpio_move)
end

ws2812.init()
led = ws2812.newBuffer(10,3)
led_off()

gpio_init()
wlan_init()
timer_init()
bmp180_init()

-- mqtt_init()
