dofile("config.lua")

mqtt_connected = false
count = 0
temp = 0
humi = 0
rssi = 0

local ledpin = 4
gpio.mode(ledpin, gpio.OUTPUT)
gpio.write(ledpin, 1)

function blinkled(t)
  if not flash_led then
    return
  end
  gpio.write(ledpin, 0)
  tmr.alarm(0, t, 0, function ()
    gpio.write(ledpin, 1)
  end)
end

function mqtt_connect()
  m:connect(mqtt_host, mqtt_port, 0, function(c)
    mqtt_connected = true
    print("mqtt online")
    if mqtt_update then
      m:subscribe("/cmd/"..node.chipid(),0,function(conn)
        print("subscribe to cmd topic")
      end)
    end
  end)
end

wifi_connect_event = function(T)
  print("Connection to AP("..T.SSID..") established!")
  print("Waiting for IP address...")
end

wifi_got_ip_event = function(T)
  print("Wifi ready! IP is: "..T.IP)
  if (send_mqtt and not mqtt_connected) then
    print("mqtt try connect to "..mqtt_host..":"..mqtt_port)
    mqtt_connect()
  end
end

wifi_disconnect_event = function(T)
  print("wifi disconnect")
  mqtt_connected = false
end

function send_data()
  if send_aprs then
    print("aprs send "..aprs_host)
    str = aprs_prefix.."000/000g000t"..string.format("%03d", temp*9/5+32).."r000p000h"..string.format("%02d",humi).."b00000"
    str = str.."ESP8266 MAC "..wifi.sta.getmac().." RSSI: "..rssi
    print(str)
    conn = net.createUDPSocket()
    conn:send(aprs_port,aprs_host,str)
    conn:close()
    data_send = true
  end
  if send_http then
    req_url = http_url.."?mac="..wifi.sta.getmac().."&"..string.format("temp=%.1f&humi=%.1f&rssi=%d",temp,humi,rssi)
    print("http send "..req_url)
    http.get(req_url, nil, function(code, data)
      if code < 0 then
        print("HTTP request failed")
      else
        print(code, data)
        data_send = true
      end
    end)
  end
end

function func_read_dht()
  count = count + 1
  if count*3 >= send_interval then
    count = 0
  end
  status, temp, humi, temp_dec, humi_dec = dht.readxx(dht_pin)
  if status ~= dht.OK then
    if dht_status == dht.ERROR_CHECKSUM then
      print("DHT read Checksum error")
    elseif dht_status == dht.ERROR_TIMEOUT then
      print("DHT read Time out")
    else
      print("DHT read null")
    end
    blinkled(100)
    return
  end
  if wifi.sta.status() ~= 5 then
    print("wifi still connecting...")
    blinkled(100)
    return
  end

  rssi = wifi.sta.getrssi()
  if rssi == nil then
    rssi = -100
  end
  data_send = false
  print("DHT read count="..string.format("%d: temp=%.1f, humi=%.1f, rssi=%d, uptime=%d",
    count,temp,humi,rssi,tmr.time()))
  if mqtt_connected then
    print("mqtt publish")
    m:publish(mqtt_topic, string.format("{\"temperature\": %.1f, \"humidity\": %.1f, \"rssi\": %d, \"uptime\": %d}",
      temp, humi, rssi, tmr.time()),0,0)
    data_send = true
  end
  if count == 4 then
    send_data()
  end
  if data_send then
    blinkled(500)
  else
    blinkled(100)
  end
 --    if send_mqtt and not mqtt_connected then
 --          print("mqtt try connect to "..mqtt_host..":"..mqtt_port)
 --          mqtt_connect()
end

if send_interval < 15 then
  send_interval = 15
end

if send_mqtt then
  print("init mqtt ChipID"..node.chipid().." "..mqtt_user.." "..mqtt_password)
  m = mqtt.Client("ESP8266SensorChipID"..node.chipid() .. ")",180,mqtt_user,mqtt_password)
  if mqtt_update then
    m:on("message",function(conn, topic, data)
      if data ~= nil then
        print(topic .. ": " .. data)
        if data == "update" then
           print("reboot into update mode")
           file.open("update.txt","w")
           file.close()
           node.restart()
        end
      end
    end)
  end
  m:on("offline", function(c)
    print("mqtt offline, try connect to "..mqtt_host..":"..mqtt_port)
    mqtt_connected = false
    mqtt_connect()
  end)
end

print("My MAC is: "..wifi.sta.getmac())
print("Connecting to AP...")

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)
wifi.setmode(wifi.STATION)
wifi.sta.config({ssid=wifi_ssid, pwd=wifi_password})
wifi.sta.autoconnect(1)
wifi.sta.connect()

flashkeypressed = false
function flashkeypress()
  if flashkeypressed then
    return
  end
  flashkeypressed = true
  print("flash key pressed, next boot into config mode")
  file.open("flashkey.txt","w")
  file.close()
end

-- flash key io
gpio.mode(3, gpio.INPUT, gpio.PULLUP)
gpio.trig(3, "low", flashkeypress)

tmr.alarm(1,3000,tmr.ALARM_AUTO,func_read_dht)
