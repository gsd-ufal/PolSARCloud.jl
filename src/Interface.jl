function get_data_sets_metadata()
	#TODO Metadata includes name of UAVSAR data sets and their metadata (.ann files, e.g., http://uavsar.jpl.nasa.gov/science/documents/example_polsar.ann.txt)
	return metadata
end

function get_SLAs()
	#TODO SLAs include informaticon such as QoS and pricing
	return SLAs
end

function propose_SLA(auth_token, SLA, data_set, ...)
	#TODO translates QoS, configures and deploys container, and start billing
	return session_id #return -1 if the IPS hasn't accepted a new service contract based on the proposed SLA terms
end

function process(session_id, data_set, algorithm, summary_size, roi, start)
	#TODO ...
	return algorithm output = summary # this ensures low data exchange, only summary physical size is sent to the client
end

function finish(session_id, [backtrace::Boolean, backtrace_data ])
	#TODO free resources (memory and CPU) and bill user
	return detailed bill [ + backtrace + backtrace_data]
end
