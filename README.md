## 使用nodemcu+DHT22 采集温湿度, 并通过wifi发送

特点：

* 成本低 20-40元
* 灵活，简单写lua程序


购买链接：

主控芯片：

* [ESP8266 Lua WIFI V3](https://item.taobao.com/item.htm?id=531755241333) 15.40元

温度传感器可二选一（DHT11误差大，DHT22更精确）:

* [DHT 11](https://item.taobao.com/item.htm?id=19526179299) 5.00元
* [DHT 22](https://item.taobao.com/item.htm?id=551955065907) 19.80元

外加手机淘汰的USB线和充电器就可以工作。

连线图：

![IMG](dht22_schematic.png)

参考网页：

https://tiestvangool.ghost.io/2016/09/04/capturing-sensor-data-dht22/
https://gist.github.com/thomo/bb539bb7d5b5f2398a62c7d6ef1231b4


步骤：

1. 安装esptool.py

   请参考 https://github.com/espressif/esptool 安装esptool.py

2. 将ESP8266 板子通过USB线连接PC，安装USB驱动，查看得知串口是COM3

3. 执行如下命令，如果能看到芯片类型，说明串口工作正常

   `esptool.py --port COM3 chip_id`

4. 执行如下命令刷新flash

   `esptool.py --port COM3 write_flash 0 nodemcu-master-12-modules-2018-07-22-07-55-18-float.bin`

   说明：nodemcu-master-12-modules-2018-07-22-07-55-18-float.bin 由 https://nodemcu-build.com/ 生成，选择的模块信息请见 modules.md 。

5. 安装ESPlorer

   请参考 https://esp8266.ru/esplorer/ 安装

6. 打开ESPlorer

   选择COM3，115200，open

   按8266板子USB一侧的RST按钮，能看到“Formatting file system. Please wait..."，等结束。

7. 写入程序

   依次打开 dht22.lua init.lua setup.lua 三个文件上传到ESP8266

8. 设置
   可以修改 config.lua 上传，也可以不上传 config.lua，进入设置模式修改配置

9. 配置模式
   如果 config.lua 不存在，或者 将ESP8266板子的D5引脚与相邻的G引脚短接 开机，自动进入配置模式。
这时请用无线终端连接至ESP8266（由ESP8266板子提供，支持DHCP）无线网络，访问 http://192.168.0.1 ，修改配置后单击 "save" 保存。

   
   
   