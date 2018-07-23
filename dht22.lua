dofile("config.lua")

count = 0

wifi_connect_event = function(T)
  print("Connection to AP("..T.SSID..") established!")
  print("Waiting for IP address...")
  if disconnect_ct ~= nil then disconnect_ct = nil end
end

wifi_got_ip_event = function(T)
  print("Wifi connection is ready! IP address is: "..T.IP)
  if (send_mqtt and not mqtt_connected) then
    print("mqtt try connect to "..mqtt_host..":"..mqtt_port)
    m:connect(mqtt_host, mqtt_port, 0, function(c)
      print("mqtt online")
      mqtt_connected = true
    end)
  end
end

wifi_disconnect_event = function(T)
  print("wifi disconnect")
end

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)

print("Connecting to WiFi access point...")

wifi.setmode(wifi.STATION)
wifi.sta.config({ssid=wifi_ssid, pwd=wifi_password})
wifi.sta.autoconnect(1)
wifi.sta.connect()

function send_data(temp, humi) 
  print("My IP is "..wifi.sta.getip())
  if (send_aprs) then
    print("try send to aprs "..aprs_host)
    str=aprs_prefix.."000/000g000t"..string.format("%03d", temp*9/5+32).."r000p000h"..string.format("%02d",humi).."b00000".."ESP8266 MAC "..wifi.sta.getmac()
    print(str)
    conn=net.createUDPSocket()
    conn:send(aprs_port,aprs_host,str)
    conn:close()
    print("aprs send ok")
  end
  if (send_http) then      
    req_url= http_url.."?mac="..wifi.sta.getmac().."&"..string.format("temp=%.1f&humi=%.1f",temp,humi)
    print("try send to "..req_url)
    http.get(req_url, nil, function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        print(code, data)
      end
    end)
  end
end

-- Read out DHT22 sensor using dht module
function func_read_dht()
  status, temp, humi, temp_dec, humi_dec = dht.read(dht_pin)
  if(status == dht.OK) then
    print("DHT read count="..string.format("%d: temp=%.1f, humi=%.1f",count,temp,humi))
    if (mqtt_connected) then
       print("publish")
       m:publish(mqtt_topic .. "/temperature", string.format("%.1f", temp),0,0)
       m:publish(mqtt_topic .. "/humidity", string.format("%.1f", humi),0,0)
    end
    count = count + 1
    if(count == 4) then
      if wifi.sta.status() == 5 then  --STA_GOTIP
         send_data(temp, humi)
         if (send_mqtt and not mqtt_connected) then
           print("mqtt try connect to "..mqtt_host..":"..mqtt_port)
           m:connect(mqtt_host, mqtt_port, 0, function(c)
             print("mqtt online")
             mqtt_connected = true
           end)
         end
      else
         print("wifi still connecting...")
      end
    end
    if(count*3 >= send_interval) then
      count = 0
    end
  elseif(dht_status == dht.ERROR_CHECKSUM) then
    print("DHT read Checksum error")
  elseif(dht_status == dht.ERROR_TIMEOUT) then
    print("DHT read Time out")
  else
    print("DHT read null")
  end
end

mqtt_connected = false

if (send_mqtt) then
  print("init mqtt sensor ID=".. node.chipid())
  m = mqtt.Client("Sensor (ID=" .. node.chipid() .. ")", 180, mqtt_user, mqtt_password)
  m:on("offline", function(c)
    print("mqtt offline, try connect to "..mqtt_host..":"..mqtt_port)
    mqtt_connected = false 
    m:connect(mqtt_host, mqtt_port, 0, function(c)
      mqtt_connected = true
      end)
    end)
end

tmr.alarm(1,3000,tmr.ALARM_AUTO,func_read_dht)

