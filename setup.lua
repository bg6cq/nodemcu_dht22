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
  dofile("config.lua")
else
  wifi_ssid = "ustcnet"
  wifi_password = ""
  send_interval = 300
  send_http = true
  http_url = "http://202.38.64.40/upload_temp_humi.php"
  send_aprs = true
  aprs_server = "202.141.176.2"
  aprs_port = 14580
  aprs_prefix = "BG6CQ-12>ES66:=3149.29N/11716.18E_"
  --dht module
  dht_pin = 2  -- Pin for DHT22 sensor (GPIO4)
end

print("Setting up Wifi AP")
wifi.setmode(wifi.SOFTAP)
wifi.ap.config({ssid="ESP8266"})  
wifi.ap.setip({ip="192.168.0.1",netmask="255.255.255.0",gateway="192.168.0.1"})
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
      end
    end
             
    if (_GET.wifi_ssid ~= nil) then
      client:send("Saving data..")
      file.open("config.lua", "w")
      file.writeline('wifi_ssid = "' .. _GET.wifi_ssid .. '"')
      file.writeline('wifi_password = "' .. _GET.wifi_password .. '"')
      file.writeline('send_interval = "' .. _GET.send_interval.. '"')
      file.writeline('send_http = true')
      file.writeline('http_url = "' .. _GET.http_url.. '"')
      file.writeline('send_aprs = false')
      file.writeline('dht_pin = "' .. _GET.dht_pin.. '"')
      file.close()
      client:send(buf)
      node.restart()
    end
   
    buf = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\r\n<html><body>"
    buf = buf .. "<h3>Configure WiFi</h3><br>"
    buf = buf .. "<form method='get' action='http://" .. wifi.ap.getip() .."'>"
    buf = buf .. "Enter wifi SSID: <input type='text' name='wifi_ssid' value='"..wifi_ssid.."'></input><br>"
    buf = buf .. "Enter wifi password: <input type='password' name='wifi_password' value='"..wifi_password.."'></input><br>"
    buf = buf .. "DHT PIN: <input type='text' name='dht_pin' value='"..dht_pin.."'></input>(should be 2, GPIO4)<br>"
    buf = buf .. "Send interval: <input type='text' name='send_interval' value='"..send_interval.."'></input><br>"
    buf = buf .. "Send URL: <input type='text' name='http_url' value='"..http_url.."'></input><br>"
    buf = buf .. "<br><button type='submit'>Save</button>"                   
    buf = buf .. "</form></body></html>"
    client:send(buf)
    client:close()
    collectgarbage()
  end)
end)
   
print("Please connect to: do setup" .. wifi.ap.getip())
