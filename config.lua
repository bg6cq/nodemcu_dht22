--wifi module
wifi_ssid = "ustcnet"
wifi_password = ""

send_http = true
http_host = "202.38.64.40"
http_url = "/upload_temp_humi.php"

send_count_interval = 10

send_aprs = true
aprs_server = "202.141.176.2"
aprs_port = 14580
aprs_prefix = "BG6CQ-15>ES66:=3150.59N/11716.00E_"


--dht module
dht_pin = 2  -- Pin for DHT22 sensor (GPIO4)
-- dht_pin = 3 -- GPIO0
-- dht_pin = 4 -- GPIO2

print("Global variables loaded")

