-- D5, GPIO14 connect to G will enter setup mode
gpio.mode(5, gpio.INPUT, gpio.PULLUP)

if ( file.exists("config.lua") and (gpio.read(5) == gpio.HIGH)) then
  print("normal startup")
  dofile("dht22.lua")
else
  -- enter setup mode
  print("go in setup mode")
  dofile("setup.lua")
end
