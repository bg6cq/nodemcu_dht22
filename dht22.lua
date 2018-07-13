--[[
dht22.lua | Tiest van Gool
Script connects to internet through NodeMCU wifi module.
Once connection is established dht module and temperature and humidity is retrieved.
--]]

-- Load global user-defined variables
dofile("config.lua")

-- Connect to the wifi network using wifi module
wifi.setmode(wifi.STATION)
wifi.sta.config({ssid=wifi_ssid, pwd=wifi_password})
wifi.sta.autoconnect(1)
wifi.sta.connect()

-- Read out DHT22 sensor using dht module
function func_read_dht()
  print ("starting read")
  status, temp, humi, temp_dec, humi_dec = dht.read(dht_pin)
  if( status == dht.OK ) then
    if FLOAT_FIRMWARE then
      temp_humi = string.format("temp=%.1f&humi=%.1f",temp,humi)
    else
      temp_humi = string.format("temp=%d.%03d&humi=%d.%03d",temp, temp_dec, humi, humi_dec)
    end
    print(temp_humi)
    count = count + 1
    if( count == 10 ) then
      count = 0
      print("try to send to "..http_url)
      if wifi.sta.status() == 5 then  --STA_GOTIP
         print("Connected to "..wifi.sta.getip())
         url=http_url .. "?mac=" .. wifi.sta.getmac().. "&" .. temp_humi
         print(url)
         http.get(url, nil, function(code, data)
           if (code < 0) then
             print("HTTP request failed")
           else
             print(code, data)
           end
         end)
      else
         print("wifi still connecting...")
      end
    end
  elseif( dht_status == dht.ERROR_CHECKSUM ) then          
    print( "DHT Checksum error" )
  elseif( dht_status == dht.ERROR_TIMEOUT ) then
    print( "DHT Time out" )
  end
end

tmr.alarm(1,2500,tmr.ALARM_AUTO,func_read_dht)
