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
      file.writeline('wifi_ssid = "' .. _GET.wifissid .. '"')
      if (_GET.wifipassword == nil) then
        file.writeline('wifi_password = ""')
      else
        file.writeline('wifi_password = "' .. _GET.wifipassword .. '"')
      end
      file.writeline('send_interval = ' .. _GET.sendinterval .. '')
      file.writeline('send_http = true')
      file.writeline('http_url = "' .. _GET.httpurl .. '"')
      file.writeline('send_aprs = false')
      file.writeline('dht_pin = "' .. _GET.dhtpin .. '"')
      file.close()
      buf = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\n<html><body>"
      buf = buf .. "config saved, please reboot"
      client:send(buf)
      print("data saved")
      return
    end
    buf = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML>\n<html><body>"
    buf = buf .. "<h3>Configure WiFi & params</h3><br>"
    buf = buf .. "<form method='get' action='http://" .. wifi.ap.getip() .."'>\n"
    buf = buf .. "wifi SSID: <input type='text' name='wifissid' value='"..wifi_ssid.."'></input><br>"
    buf = buf .. "wifi password: <input type='text' name='wifipassword' value='"..wifi_password.."'></input><br>\n"
    buf = buf .. "DHT22 PIN: <input type='text' name='dhtpin' value='"..dht_pin.."'></input>(should be 2, GPIO4)<br>"
    buf = buf .. "Send interval: <input type='text' name='sendinterval' value='"..send_interval.."'></input>seconds<br>\n"
    buf = buf .. "Send URL: <input type='text' size=100 name='httpurl' value='"..http_url.."'></input><br>"
    buf = buf .. "<br><button type='submit'>Save</button>\n"
    buf = buf .. "</form><a href=https://github.com/bg6cq/nodemcu_dht22>https://github.com/bg6cq/nodemcu_dht22</a> by james@ustc.edu.cn</body></html>\n"
    client:send(buf)
    -- client:close()
    collectgarbage()
  end)
end)
   
print("Please connect to: " .. wifi.ap.getip() .. " do setup")
