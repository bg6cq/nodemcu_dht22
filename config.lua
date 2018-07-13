--[[
config.lua | Tiest van Gool

Global variables definitions for usage across various lua scripts
--]]

--wifi module
wifi_ssid = "ustcnet"
wifi_password = ""
http_url = "http://202.38.64.40/upload_temp_humi.php"
temp_humi = ""
count = 0

FLOAT_FIRMWARE = (1/3) > 0

--dht module
dht_pin = 2  -- Pin for DHT22 sensor (GPIO4)
-- dht_pin = 3 -- GPIO0
-- dht_pin = 4 -- GPIO2

-- Status Message
print("Global variables loaded")
