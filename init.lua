-- Set local variable
FileToExecute="dht22.lua"

-- D5, GPIO14 connect to G will do setup
gpio.mode(5, gpio.INPUT, gpio.PULLUP)

if gpio.read(5) == gpio.LOW then
   -- go in setup mode LED
   gpio.mode(0, gpio.OUTPUT)
   gpio.write(0, gpio.LOW)
   do("setup.lua")
else
-- Set timer to abort initialization of actual program
print("You have 15 second to enter file.remove('init.lua') to abort")
tmr.alarm(0, 15000, 0, function()
  print("Executing: ".. FileToExecute)
  dofile(FileToExecute)
end)
