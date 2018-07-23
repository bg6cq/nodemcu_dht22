if (file.exists("config.lua") and (not file.exists("flashkey.txt"))) then
  print("normal startup")
  dofile("dht22.lua")
else
  -- enter setup mode
  print("go in setup mode")
  file.remove("flashkey.txt")
  dofile("setup.lua")
end
