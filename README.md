#Temperature Logger
##About
I built this temperature logger to log the temperature of the Anova water bath over long cooks because I have heard stories of units freezing and not keeping the water warm or random temperature changes.

**Note:** The random temperature changes happened for about 4 days before they pushed a phone app update and said everything was fixed. I have used it lots since then and have had no problems. The freezing is extremely rare and I have only seen two post on reddit about it.

---

##How It Works
###Overview
The system collects the temperature of the water using two DS18B20 sensors. That data is then sent to an InfluxDB database. From there Grafana charts the data for a visual interface. Kapacitor also runs checks against all incoming data and can send Pushover alerts when conditions aren't met.

###Hardware
####DS18B20
The hardware consist of two DS18B20 sensors that are accurate to 0.5C. In practice, I have found that accuracy to be between units. Between measurements I have seen a precision and accuracy of around 0.1C once calibrated.

####NodeMCU
The NodeMCU is a dev board and api that simplifies working with the ESP8266. It is a all in one WiFi/MCU board that is simple to use. It is programmed in lua (api) or Arduino (does not use NodeMCU api).

####Other
Power supply for the NodeMCU. Case for the project. One 2.2K pull-up resistor.

---

###Software
####InfluxDB
InfluxDB is a time series metric database which is best suited for storing values that change over time. My database for the temperature logger is called AnovaStats and the structure looks like this:

    AnovaStats
      --temperature (measurement)
      ----unit (tag), probe (tag), value (field)
InfluxDB doesn't have to be used, it would only require a few changes to the lua code to switch to a different storage scheme.

####Grafana
Grafana, also made by the InfluxDB people, is the visual interface that provides graphs of the temperature over time. This is mostly user preference on how it is setup so I am not going into detail.

####Kapacitor
Kapacitor is made by the same people as InfluxDB and is their answer to alerting. Kapacitor is setup to access InfluxDB and each time InfluxDB receives data Kapacitor also gets that data. Then it runs that data against the currently enabled tick scripts and determines if it needs to take action. Mine is setup to send a critical pushover alert if the temperature of either probe is outside ±1F of the set temperature.


##How To Build
###Parts (links to Amazon)
* [NodeMCU Dev Board](https://amzn.com/B010O1G1ES)
* [DS18B20 Temperature Sensor](https://amzn.com/B00CHEZ250)
* 2.2k Ohm Resistor, 1/8 watt or higher
* Micro-USB to USB Cable
* Cellphone charger

###Hardware
For my sensors:

* Red wire to 3.3V
* Grey wire to GND
* Yellow wire (data) to NodeMcu pin D1

Because these are one-wire sensors both sensors can be hooked to D1 as they are read using the unique device id. You also need to add the 2.2k resistor from the yellow wires to the red wires (pull up).

###Software

####[ESP8266Flasher](https://github.com/nodemcu/nodemcu-flasher)
Used to flash the nodemcu with the os that supports one-wire.

[OS image I flashed](/NodeMCU-firmware/nodemcu-master-8-modules-2016-07-15-20-25-35-float.bin)

or you can make a [custom build](https://nodemcu-build.com/)

####[ESPlorer](http://esp8266.ru/esplorer/#download)

ESPlorer is used to edit and upload the lua files for the NodeMCU when it is connected to your computer.

* [AnovaMain.lua](/AnovaMain.lua)
* [ds18b20.lua](/ds18b20.lua)
* [init.lua](/init.lua)
* settings.lua*

The above files need to be uploaded to the NodeMCU for it to work.

*You will have to update [settings.lua.template](/settings.lua.template) with your own values and remove the ".template" before uploading. 

Specifically you need to edit the following:

* WIFI Credentials
* InfluxDB Credentials
* InfluxDB Host and Database
* Temp Probe device ids
* Probe Calibration values

To make editing easier you may want to add these snippets under the ESPlorer Snippets tab.

Snippet0 - Name "Stop Init":

    file.rename("init.lua", "init.lua.stop")

Snippet1 - Name "Start Init":

    file.rename("init.lua.stop", "init.lua")
    node.restart()

The first two snippets allow you to just click those buttons to rename the init file to stop/start the boot process. The third allows you to delete the init.lua.stop file if you upload a new one.

After you upload the above files and reset the nodemcu you will see this.

    NodeMCU custom build by frightanic.com
    	branch: master
    	commit: b580bfe79e6e73020c2bd7cd92a6afe01a8bc867
	    SSL: false
	    modules: file,gpio,net,node,ow,tmr,uart,wifi
     build 	built on: 2016-07-15 20:24
     powered by Lua 5.1.4 on SDK 1.5.1(e67da894)
    Connecting to WiFi access point...
    > Waiting for IP address...
    Waiting for IP address...
    Waiting for IP address...
    WiFi connection established, IP address: 192.168.1.156
    You have 3 seconds to abort
    Waiting...

Anywhere in there you can click the Stop Init button at the bottom and it will rename the init.lua to init.lua.stop and halt the booting.

Then you can proceed to get the probe ids as described below.

[getTempIDs.lua](/tools/getTempIDs.lua) Is a quick script for printing out all of the attached sensors. Once you have the above files and *getTempIDs.lua* uploaded you can click the reload button on the right side. Then you can click the *getTempIDs.lua* button and it will execute that file. That will print the addresses and temperatures of those addresses. The only file that *getTempIDs.lua* requires is *db18s20.lua*

For the calibration values, get the system working and then put in a pot with Anova, find the difference for each sensor and put in the settings file.

####[InfluxDB](https://influxdata.com/time-series-platform/influxdb/)
InfluxDB setup is just the standard setup using the [InfluxDB Introduction](https://docs.influxdata.com/influxdb/v0.13/introduction/). After that you need to add a database called AnovaStats. Then add a measurement called temperature to that database.

####[Grafana](http://grafana.org/)
Another standard setup using the [documentation](http://docs.grafana.org/). Then the InfluxDB data source is added and the graphs setup.

I have included the json export of my AnovaStats dashboard. It is a very simple dashboard so don't expect much.

That file can be found in the [Grafana Folder](/Grafana)

####[Kapacitor](https://influxdata.com/time-series-platform/kapacitor/)
Standard setup using the [Kapacitor Introduction](https://docs.influxdata.com/kapacitor/v0.13/introduction/). Once that is done and connected to your InfluxDB then you need to create the anova alert tick script and python script for pushover.

Those two scripts can be found in the [Kapacitor Folder](/Kapacitor)

[anova\_alert.tick](/Kapacitor/anova_alert.tick) has to be defined and enabled every time you need to change the setpoint. I do not have a better way to do this yet so you will have to edit the file and then run the define and enable commands:

    kapacitor define anova_alert -type stream -tick anova_alert.tick -dbrp AnovaStats.default

The above command should be executed in the folder where anova\_alert.tick resides.

    kapacitor enable anova_alert

Will start kapacitor to processing the incoming data against the conditions in the tick script.

    kapacitor disable anova_alert

Will stop the processing of data.

####Kapacitor/Pushover
The Kapacitor tick script calls [anova\_alert.py.template](/Kapacitor/anova_alert.py.template) when a condition is met. In this case the script process the status and then sends the post to pushover.

**This script has to be edited with the user key and app api key for pushover.**

##Enclosure
###Parts (links to Amazon)
* 4-40 bolts and nuts (probably 3/8" or 1/2", I cut mine to fit)
* [Female Headers](https://amzn.com/B00899WQ6U)
* 1 - [Proto-board](https://amzn.com/B00NQ37V0K)
* 1 - [Box](https://amzn.com/B00O9Y633G)
* 2 - [1/8" Stereo Jack](https://amzn.com/B000ML4A2Q)
* 2 - [1/8" Stereo Plugs](https://amzn.com/B00MFRZ2SG)

This was a really tight fit in this box so you will have to be very carefull where you drill the holes for the jacks. You will also have to cut the supports out so that the board will fit in the box with the female headers. If you don't want to use female headers then you will be fine leaving them there.

I also recommend a differnt plug because those are a little flimsy. Also no measurements as I did it all by eye, sorry.

####Board Cut - Top
![Board_Cut_Top](https://cloud.githubusercontent.com/assets/20709731/18496356/d81c774c-79ea-11e6-8ec8-1604a50bb831.jpg)

####Board Cut - Angle
![Board_Cut_Angle](https://cloud.githubusercontent.com/assets/20709731/18496358/d8244b48-79ea-11e6-90f5-ccfef28d3716.jpg)

####Board - Bottom
![Board_Bottom](https://cloud.githubusercontent.com/assets/20709731/18496355/d81b8620-79ea-11e6-82fd-91775fcce3ec.jpg)

####Board - Top
![Board_Top](https://cloud.githubusercontent.com/assets/20709731/18496353/d8101b78-79ea-11e6-9878-4e7e9742de13.jpg)

####Jacks - Straight
![Jacks_Straight](https://cloud.githubusercontent.com/assets/20709731/18496361/d8395e52-79ea-11e6-9e1e-b553c97137f7.jpg)

####Jacks - Angle
![Jacks_Angle](https://cloud.githubusercontent.com/assets/20709731/18496363/d847f732-79ea-11e6-9205-397943019c05.jpg)

####Jacks Wired - Straight
![Jacks_Wired_Straight](https://cloud.githubusercontent.com/assets/20709731/18496360/d8372e52-79ea-11e6-9c05-cdde045a2e2d.jpg)

####Jacks Wired - Angle
![Jacks_Wired_Angle](https://cloud.githubusercontent.com/assets/20709731/18496359/d82a383c-79ea-11e6-86e7-bb45c495a491.jpg)

####Box with Bolts
![Box_with_Bolts](https://cloud.githubusercontent.com/assets/20709731/18496354/d8181a94-79ea-11e6-8a78-83d3247458d1.jpg)

####Box with nodemcu
![Box_with_nodemcu](https://cloud.githubusercontent.com/assets/20709731/18496357/d8222480-79ea-11e6-8818-eeb948289ac4.jpg)

####Box Top
![Box_Top](https://cloud.githubusercontent.com/assets/20709731/18496362/d8418d70-79ea-11e6-88c7-6744a5056fe0.jpg)


##Thoughts
* If a file has ".template" on the end that means there is stuff to edit inside

* Make sure you enable the kapacitor alert

* You can test the system by manually inserting an out of range value ("1" is nice to find and remove) into influx and see if kapacitor produces an alert

* Yes I have been bitten by the above
