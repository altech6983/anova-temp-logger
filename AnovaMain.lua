dsModule = require("ds18b20")

local temp_count = 0
local probe1_temp = 0
local probe2_temp = 0

function round(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then 
        return math.floor(num * mult + 0.5) / mult
    else
        return math.ceil(num * mult - 0.5) / mult
    end
end

function build_post_request(host, uri, data_table)

    local data = data_table.Measurement .. ",unit=" .. data_table.Unit .. ",probe=" .. data_table.Probe .. " " .. "value=" .. data_table.Value
    
    --for param,value in pairs(data_table) do
    --      data = data .. param.."="..value.."&"
    -- end
    --print(data)
    
    request = "POST "..uri.." HTTP/1.1\r\n"..
    "Host: "..host.."\r\n"..
    "Connection: close\r\n"..
    "Content-Type: application/x-www-form-urlencoded\r\n"..
    "Content-Length: "..string.len(data).."\r\n"..
    "\r\n"..
    data
    
    --print(request)
    
    return request
end

local function display(sck,response)
--print(response)
end

local function send_data(measurement,unit,probe,value)

    local data = {
        Measurement = measurement,
        Unit = unit,
        Probe = probe,
        Value = value
    }

    socket = net.createConnection(net.TCP,0)
    socket:on("receive",display)
    socket:connect(8086,HOST)
    
    socket:on("connection",function(sck) 
        local post_request = build_post_request(HOST,URI,data)
        sck:send(post_request)
    end)     
end

function getTemp()

    local temp1 = nil
    local temp2 = nil
    
    --addrs = dsModule.addrs()
    --if (addrs ~= nil) then
        --print("Total DS18B20 sensors: "..table.getn(addrs))
    --end
    
    --if (table.getn(addrs) >= 1) then
        temp1 = dsModule.read(PROBE1_ROMCODE,dsModule.F) + PROBE1_CAL
        --print("First sensor: "..temp1.."'F")
    --end
    
    --if (table.getn(addrs) >= 2) then
        temp2 = dsModule.read(PROBE2_ROMCODE,dsModule.F) + PROBE2_CAL
        --print("Second sensor: "..temp2.."'F")
    --end
    
    return temp1, temp2
end

function send_temps(t1,t2)
    local ip = wifi.sta.getip()
    
    if ip~=nil then
        send_data(MEASUREMENT, UNIT, "probe_1", t1)
        send_data(MEASUREMENT, UNIT, "probe_2", t2)
    end
end

function update_temps()
    if temp_count >= 5 then
        temp_count = 0

        probe1_temp = round(probe1_temp / TEMP_SAMPLES,1)
        probe2_temp = round(probe2_temp / TEMP_SAMPLES,1)
        
        print("Avg Temp 1:".. probe1_temp .." F")
        print("Avg Temp 2:".. probe2_temp .." F\n")
        
        send_temps(probe1_temp,probe2_temp)
        
        probe1_temp = 0
        probe2_temp = 0
        tmr.start(0)
    else
        temp_count = temp_count + 1

        local t1, t2 = getTemp()
        probe1_temp = probe1_temp + t1
        probe2_temp = probe2_temp + t2
        
        tmr.start(1)
    end
end

dsModule.setup(TEMPERATUREPIN)

getTemp()
getTemp()
getTemp()

tmr.register(1,TEMP_SAMP_DELAY,tmr.ALARM_SEMI,update_temps)
tmr.alarm(0,TEMP_UPDATE,tmr.ALARM_SEMI,update_temps)



-- Don't forget to release it after use
--dsModule = nil
--ds18b20 = nil
--package.loaded["ds18b20"]=nil
