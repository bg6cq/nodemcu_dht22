--[[
dht22.lua | Tiest van Gool
Script connects to internet through NodeMCU wifi module.
Once connection is established dht module and temperature and humidity is retrieved.
--]]

-- Load global user-defined variables
dofile("config.lua")

temp_humi = ""
count = 0

-- Connect to the wifi network using wifi module
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
      print("send ok")
  end
  if (send_http) then      
      req_url= http_url.."?mac="..wifi.sta.getmac().."&"..string.format("temp=%.1f&humi=%.1f",temp,humi)
      print("try send to http://"..http_host..req_url)
      conn=net.createConnection(net.TCP, 0) 
      conn:on("receive", function(conn, payload) print(payload) end)
      conn:connect(80,host) 
      conn:send("GET "..req_url.." HTTP/1.1\r\n") 
      conn:send("Host: "..http_host.."\r\n") 
      conn:send("Accept: */*\r\n") 
      conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
      conn:send("\r\n")
      conn:on("sent",function(conn)
        print("send ok")
        conn:close()
        end)
      conn:on("disconnection", function(conn)
        print("Got disconnection...")
        end)
  end
end
-- Read out DHT22 sensor using dht module
function func_read_dht()
  print ("starting read")
  status, temp, humi, temp_dec, humi_dec = dht.read(dht_pin)
  if( status == dht.OK ) then
    temp_humi = string.format("temp=%.1f, humi=%.1f",temp,humi)
    print(temp_humi)
    count = count + 1
    if( count == send_count_interval ) then
      count = 0
      if wifi.sta.status() == 5 then  --STA_GOTIP
         send_data(temp, humi)
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

