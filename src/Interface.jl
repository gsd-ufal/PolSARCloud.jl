function getdatasets_metadata(service_address)
	#TODO Metadata includes name of UAVSAR data sets and their metadata (.ann files, e.g., http://uavsar.jpl.nasa.gov/science/documents/example_polsar.ann.txt)
	return metadata
	#PROTOTYPE 12GB PolSAR data set, 150MB, PolSAR data set, 1GB Parkinson exam data set, 50MB PNG file
end

function getSLAs(service_address)
	#TODO SLAs include informaticon such as QoS and pricing
	return SLAs
	#PROTOTYPE QoS lelves according to execution resorces:
		# dedicated (no resource sharing, implies using dedicated VMs) 
		# shared (shares resources equally in a VM, eg: docker run )
		# low priority (processing is constrained to minimal when disputing for resources, eg: nice 20 docker ...)
		#OBS resources are CPU and network
			#TODO investigate if we can set up network bandwidith constraints too
end

function proposeSLA(service_address, auth_token, SLA, dataset, ...)
	# returns -1 if the IPS hasn't accepted a new service contract based on the proposed SLA terms
	
	#TODO enable authentication through Google, Github, Facebook, Linkedin, etc.
	
	#TODO decide to use whether
	#	 1. DC/OS + marathon-lb: https://azure.microsoft.com/en-us/documentation/articles/container-service-load-balancing/
	#		OBS: takes 15 minutes to set up a cluster ("data center")
	#	 2. or Swarn + its native scaling/balancing mechanism: https://docs.docker.com/engine/swarm/
	
	#TODO translates QoS: eg, through marathon parameters when creating containers: https://youtu.be/VdhJ_Fm3_mk?t=282
	#TODO configures and deploys container
	#TODO start billing
	
	#TODO investigate if it is useful to use https://dcos.io , https://docs.docker.com/swarm/ instead of directly managing Docker containers (n.b. http://unikernel.org)
	
	return session_id # session_id includes the entry point address (VM/container IP) to where the processing will be performed
end

function process(service_address, session_id, dataset, algorithm, [subset])
	#TODO ...
	return algorithm_output # output could be replaced by the address/link to which the data is stored (eg, output is too big or user prefer to keep it in the Cloud). I see 4 options: returns output, output link, output + link, output ID (in this case output is kept in the Cloud and backtrace ID should be returned)
end

function finish(service_address, session_id, [backtrace::Boolean, backtrace_data ])
	#TODO free resources (memory and CPU) and bill user
	return bill [ + backtrace + backtrace_data]
end
TODO opção de deixar backtrace + backtrace_data na nuvem, com opções de compartilhamento no service_address, github, facebook, LinkedIn, Twitter, Academia, Instagrem, etc.
