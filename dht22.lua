dofile("config.lua")

count = 0

wifi_connect_event = function(T)
  print("Connection to AP("..T.SSID..") established!")
  print("Waiting for IP address...")
  if disconnect_ct ~= nil then disconnect_ct = nil end
end

wifi_got_ip_event = function(T)
  print("Wifi connection is ready! IP address is: "..T.IP)
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
    print("try send to aprs "..aprs_server)
    str=aprs_prefix.."000/000g000t"..string.format("%03d", temp*9/5+32).."r000p000h"..string.format("%02d",humi).."b00000".."ESP8266 MAC "..wifi.sta.getmac()
    print(str)
    conn=net.createUDPSocket()
    conn:send(aprs_port,aprs_server,str)
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
    count = count + 1
    if(count == 4) then
      if wifi.sta.status() == 5 then  --STA_GOTIP
         send_data(temp, humi)
      else
         print("wifi still connecting...")
      end
    end
    if(count >= send_count_interval) then
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

tmr.alarm(1,3000,tmr.ALARM_AUTO,func_read_dht)

