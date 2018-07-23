local unescape = function (s)
  s = string.gsub(s, "+", " ")
  s = string.gsub(s, "%%(%x%x)", function (h)
    return string.char(tonumber(h, 16))
    end)
  return s
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

if file.exists("config.lua") then
  print("config.lua exists")
  dofile("config.lua")
else
  print("config.lua do not exists, using default")
  wifi_ssid = "ustcnet"
  wifi_password = ""
  send_interval = 300
  send_mtqq = true
  mqtt_host= "202.38.64.40"
  mqtt_port = 1883
  mqtt_user = "user"
  mqtt_password = "password"
  mqtt_topic = "/sensor/" .. wifi.sta.getmac()
  send_http = true
  http_url = "http://202.38.64.40/upload_temp_humi.php"
  send_aprs = false
  aprs_host = "202.141.176.2"
  aprs_port = 14580
  aprs_prefix = "BG6CQ-12>ES66:=3149.29N/11716.18E_"
  --dht module
  dht_pin = 2  -- Pin for DHT22 sensor (GPIO4)
end

print("Setting up Wifi AP")
wifi.setmode(wifi.SOFTAP)
wifi.ap.config({ssid="ESP8266"})
wifi.ap.setip({ip="192.168.0.1", netmask="255.255.255.0", gateway="192.168.0.1"})
print("Setting up webserver")

--web server
srv = nil
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
  conn:on("receive", function(client,request)
    local buf = ""
    local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
    if(method == nil)then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
    end
    local _GET = {}
    if (vars ~= nil)then
      for k, v in string.gmatch(vars, "(%w+)=([^%&]+)&*") do
        _GET[k] = unescape(v)
        print(k .. ' ' .. _GET[k])
      end
    end
    if (_GET.wifissid ~= nil) then
      print("Saving data")
      file.open("config.lua", "w")
      
      if (_GET.wifissid == nil) then _GET.wifissid = "" end
      if (_GET.wifipassword == nil) then _GET.wifipassword = "" end
      if (_GET.dhtpin == nil) then _GET.dhtpin = "2" end
      
      file.writeline('wifi_ssid = "' .. _GET.wifissid .. '"')
      file.writeline('wifi_password = "' .. _GET.wifipassword .. '"')
      file.writeline('dht_pin = ' .. _GET.dhtpin )
      
      if (_GET.sendmqtt == nil) then _GET.sendmqtt = "false" end
      if (_GET.mqtthost == nil) then _GET.mqtthost = "" end
      if (_GET.mqttport == nil) then _GET.mqttport = "1883" end
      if (_GET.mqttuser == nil) then _GET.mqttuser = "" end
      if (_GET.mqttpassowrd == nil) then _GET.mqttpassword = "" end
      if (_GET.mqtttopic == nil) then _GET.mqtttopic = "" end
      file.writeline('send_mqtt = ' .. _GET.sendmqtt )
      file.writeline('mqtt_host = "' .. _GET.mqtthost .. '"')
      file.writeline('mqtt_port = ' .. _GET.mqttport )
      file.writeline('mqtt_user = "' .. _GET.mqttuser .. '"')
      file.writeline('mqtt_password = "' .. _GET.mqttpassword .. '"')
      file.writeline('mqtt_topic = "' .. _GET.mqtttopic .. '"')
      
      if (_GET.sendinterval == nil) then _GET.sendinterval = "300" end
      if (_GET.sendhttp == nil) then _GET.sendhttp = "false" end
      if (_GET.httpurl == nil) then _GET.httpurl = "" end            
      file.writeline('send_interval = ' .. _GET.sendinterval )
      file.writeline('send_http = '.. _GET.sendhttp)
      file.writeline('http_url = "' .. _GET.httpurl .. '"')

      if (_GET.sendaprs == nil) then _GET.sendaprs = "false" end
      if (_GET.aprshost == nil) then _GET.aprshost = "202.141.176.2" end
      if (_GET.aprsport == nil) then _GET.aprsport = "14580" end
      if (_GET.aprsprefix == nil) then _GET.aprsprefix = "" end
            
      file.writeline('send_aprs = '.. _GET.sendaprs)
      file.writeline('aprs_host = "' .. _GET.aprshost .. '"')
      file.writeline('aprs_port = ' .. _GET.aprsport )
      file.writeline('aprs_prefix = "' .. _GET.aprsprefix .. '"')
      
      file.close()
      buf = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\n<html><body>"
      buf = buf .. "config saved, please reboot"
      client:send(buf)
      print("data saved")
      dofile("config.lua")
      return
    end
    buf = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\n<html><body>"
    buf = buf .. "<h3>Configure WiFi & params</h3><br>"
    buf = buf .. "<form method='get' action='http://" .. wifi.ap.getip() .."'>\n"
    buf = buf .. "wifi SSID: <input type='text' name='wifissid' value='"..wifi_ssid.."'></input><br>"
    buf = buf .. "wifi password: <input type='text' name='wifipassword' value='"..wifi_password.."'></input><br>\n"
    buf = buf .. "DHT22 PIN: <input type='text' name='dhtpin' value='"..dht_pin.."'></input>(should be 2, GPIO4)<br>"
    
    buf = buf .. "<hr>MQTT send: <input type='radio' name='sendmqtt' value='true'"
    if (send_mqtt) then
       buf = buf .. " checked"
    end 
    buf = buf .. "></input><br>"
    
    buf = buf .. "MQTT host: <input type='text' name='mqtthost' value='"..mqtt_host.."'></input><br>\n"
    buf = buf .. "MQTT port: <input type='text' name='mqttport' value='"..mqtt_port.."'></input><br>\n"
    buf = buf .. "MQTT user: <input type='text' name='mqttuser' value='"..mqtt_user.."'></input><br>\n"
    buf = buf .. "MQTT password: <input type='text' name='mqttpassword' value='"..mqtt_password.."'></input><br>\n"
    buf = buf .. "MQTT topic: <input type='text' name='mqtttopic' value='"..mqtt_topic.."'></input><br>\n"
    
    buf = buf .. "<hr>HTTP and APRS<br>Send interval: <input type='text' name='sendinterval' value='"..send_interval.."'></input>seconds<br>\n"
    
    buf = buf .. "<hr>HTTP send: <input type='radio' name='sendhttp' value='true'"
    if (send_http) then
      buf = buf .. " checked"
    end
    buf = buf .. "></input><br>"
    buf = buf .. "Send URL: <input type='text' size=100 name='httpurl' value='"..http_url.."'></input><br>"

    buf = buf .. "<hr>APRS send: <input type='radio' name='sendaprs' value='true'"
    if (send_aprs) then
      buf = buf .. " checked"
    end
    buf = buf .. "></input><br>"
    buf = buf .. "APRS host: <input type='text' name='aprshost' value='"..aprs_host.."'></input><br>\n"
    buf = buf .. "APRS port: <input type='text' name='aprsport' value='"..aprs_port.."'></input><br>\n"
    buf = buf .. "APRS prefix: <input type='text' name='aprsprefix' size=100 value='"..aprs_prefix.."'></input><br>\n"
    
    buf = buf .. "<br><button type='submit'>Save</button>\n"
    buf = buf .. "</form><a href=https://github.com/bg6cq/nodemcu_dht22>https://github.com/bg6cq/nodemcu_dht22</a> by james@ustc.edu.cn</body></html>\n"
    client:send(buf)
    -- client:close()
    collectgarbage()
  end)
end)
   
print("Please connect to: " .. wifi.ap.getip() .. " do setup")
