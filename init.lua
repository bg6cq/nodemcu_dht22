-- D5, GPIO14 connect to G will enter setup mode
gpio.mode(5, gpio.INPUT, gpio.PULLUP)
gpio.mode(0, gpio.OUTPUT)

if gpio.read(5) == gpio.LOW then
  -- enter setup mode, light LED
  print("go in setup mode");
  gpio.write(0, gpio.LOW)
  do("setup.lua")
else
  gpio.write(0, gpio.HIGH)
  dofile("dht22.lua")
end)
