--wifi module
wifi_ssid = "ustcnet"
wifi_password = ""

--every 3 seconds read temp&humi，send out every send_count_interval read 
send_count_interval = 100

send_http = true
http_url = "http://202.38.64.40/upload_temp_humi.php"

send_aprs = true
aprs_server = "202.141.176.2"
aprs_port = 14580
aprs_prefix = "BG6CQ-12>ES66:=3149.29N/11716.18E_"

--dht module
dht_pin = 2  -- Pin for DHT22 sensor (GPIO4)
-- dht_pin = 3 -- GPIO0
-- dht_pin = 4 -- GPIO2
print("Global variables loaded")
