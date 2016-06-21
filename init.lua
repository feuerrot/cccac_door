bmp180 = require("bmp180")

m = mqtt.Client("outdoor", 120, nil, nil)

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
	m:publish("sensors/outdoor/temperature", t_t, 0, 1)
	m:publish("sensors/outdoor/pressure", p_t, 0, 1)
end

function wlan_init()
	print("wlan_init()")
	wifi.sta.eventMonReg(wifi.STA_GOTIP, function() mqtt_init() end)

	wifi.setmode(wifi.STATION)
	wifi.sta.config("CCCAC_PSK_2.4GHz", "23cccac42")
	wifi.sta.eventMonStart()
	print(wifi.sta.getip())
end

function mqtt_connected()
	print("mqtt_connected()")
	tmr.start(0)
end

function mqtt_init()
	print("mqtt_init()")
	m:on("message", mqtt_parsemsg)
	m:on("connect", function(client) mqtt_connected() end)

	m:connect("172.20.122.11")
end

function timer_init()
	print("timer_init()")
	tmr.register(0, 5000, tmr.ALARM_AUTO, bmp180_senddata)
end

wlan_init()
timer_init()
bmp180_init()
