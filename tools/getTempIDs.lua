dsModule = require("ds18b20")

-- Pin that the probes are connected to
-- In this case this is pin D1
dsModule.setup(1)

-- Initializes addresses and the number of probes
-- Reads the probes three times to stop it from returning 85C
function initDS()
    addrs = dsModule.addrs()
    num_probes = table.getn(addrs)

    for j = 1, 3 do
        for i = 1, num_probes do
            temp = dsModule.read(addrs[i],dsModule.C)
        end
	end
    
    tmr.alarm(0,500, 0, getDSids)
end

-- Prints information about the probes
function getDSids()
	print("Number of Sensors: "..num_probes)
	id_int_format = "%u,%u,%u,%u,%u,%u,%u,%u"

	if (num_probes > 0) then
		for i = 1, num_probes do
			string_id=string.format(id_int_format,addrs[i]:byte(1,9))
			print("Probe "..i.." Unique ID: "..string_id.." ")
		end
	end

	for i = 1, num_probes do
		temp = dsModule.read(addrs[i],dsModule.C)
		print("Temp Probe "..i..": "..temp.." deg C")
	end 

	-- Cleanup
	dsModule = nil
	ds18b20 = nil
	package.loaded["ds18b20"]=nil
end

initDS()