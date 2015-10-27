###=============================================================================
#
#          FILE: CloudArray.jl
# 
#         USAGE: include("CloudArray.jl")
# 
#   DESCRIPTION: Implements the CloudArrays functionalities for Julia
# 
#       OPTIONS: ---
#  DEPENDENCIES: DistributedArrays
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Naelson Douglas C. Oliveira
#  ORGANIZATION: GSD-UFAL
#       CREATED: 2015-10-04 16:32
###=============================================================================
###=========================   Environment setup   =============================

#set this as true if you want to get the execution time of the CArray (the default is false), if true our constructors outputs will be
#data, number of chunks created, time to create the container   eg.: darray,n_containers, time = DArray("floats.txt")
#if false it will return only the DArray
local_workers = false
include("Infra.jl")

@everywhere using DistributedArrays

###=============================================================================
###=========================   Auxiliary functions   ===========================

@doc """
### rmall()
Remove all workers.
The same as rmprocs(workers())
WARNING: Every data stored in the workers will be lost.
""" ->
#Removes all the workers()
function rmprocs_all()
	rmprocs(workers())
end


@doc """
### compose(carray1::DArray, carray2::DArray)
Gets 2 DArrays and return both as one. No data IO is involved, only the references
""" ->
function compose(array1::DArray, carray2::DArray)
	return DArray([carray1.chunks;carray2.chunks])
end


@doc """
### lines_producer(input::String)
Takes an input filepath and returns a task which generetas one of the file by call.
## use consume(::Task) to get the lines in the task
"""->
function lines_producer(input::AbstractString="floats.txt")
	file = open(input)
	for line in eachline(file)
		produce(line)
	end
	close(file)
end

@doc """
Gets two values, low and high and produces these values one by one. If low > high, the are swaped
"""->
function seq_producer(low::Int, high::Int)

	if (low > high)
		low, high = high, low
	end
	
	for i=low:high
		produce(i)
	end
end

@doc """
An auxiliary function for the CloudArray. It gets a line of data, which was previously generated by a task, and parse this line as a float or only removes the eol's from the line and outputs it as a string.
"""->
function parse_by_type(data, is_numeric::Bool=false)
	if (is_numeric)				
		return 	parse(chomp(string(data)))
	else
		return chomp(string(data))
	end
end


@doc """
Gets an Array produces it with produce(value) for each line of the Array.
This function is use to cread tasks in the task_from_array(...) function
"""->
function array_producer(a::AbstractArray)
           for i in a
               produce(i)
       end
end

@doc """
### task_from_text(input::AbstractString)
Gets a filepath as input and returns a task which produces the lines from the file.
"""->
function task_from_text(input::AbstractString="floats.txt",delim::Char='\n')
	return ( Task( () -> lines_producer(input)))
end

@doc """
Gets  an Array as input and creates a task whose will produce every values in the array one by one with consume(::Task) calls
"""->
function task_from_array(input::AbstractArray)
	return(Task(()->array_producer(input)))
end

@doc """
The same as DistributedArrays.distribute(::AbstractArray), but using the CloudArray management.
"""->
distribute_cloud(input::AbstractArray) = carray_from_task(task_from_array(input))

@doc """
Creates a CloudArray from an Array. It's actualt a call of distribute_cloud(input::AbstractArray) with other name
"""->
DistributedArrays.DArray(input::AbstractArray) = begin distribute_cloud(input) end


###=============================================================================
###=========================   Core Constructors   =============================







@doc """
Core constructor of the CloudArray

It gets a Task as input and creates a CloudArray from it. The task must generate lines of data by each consume(::Task) call. Each call is a cell of the CloudArray.

is_numeric::Bool --> you tell if your input data is composed by numbers. The default is true, if you use an input with strings, you will get some errors.

chunk_max_size::Int --> Maximum size of each chunk for the CloudArray in bytes. The default is 1MB (1024*1024)

debug::Bool --> Enables the debug mode, default is false. If you use it as true, the function output will be: the_carray, [number_of_chunks], [time_to_instance_each_chunk] instead of only the_carray


This constructor was created with tasks to make easier to tune a custom CArray, since all the user needs to do is to create a task which generates the lines of the CloudArray by each call 
eg: task_from_array(...) and task_from_text(...)
"""->
function carray_from_task(generator::Task=task_from_text("floats.txt"), is_numeric::Bool=true, chunk_max_size::Int=1024*1024,debug::Bool=false)
	
	plot_data =  []
	containers = []
	time = []
	refs = Array(RemoteRef,0)
	while (generator.state != :done) #while there's something to be read in the source
		
		#creates an array to buffer the lines from the source		
		if (is_numeric)
			local_array = Array(Float64,0)  
		else
			local_array = Array(AbstractString,0)
		end
			
		while ((sizeof(local_array) < chunk_max_size) & (generator.state != :done)) #while the current container still have free space, store the lines in the buffer	

			line = consume(generator)
			if (typeof(line) != Void && line !='\n') #we don't want empty lines in our CArray, right?				
				
			push!(local_array,parse_by_type(line,is_numeric))	
			end
			
		end
		size_local = length(local_array)		

		tic()	
		if !local_workers

			create_containers(1,0,250)		
			#push!(plot_data, [time;workers])
		else			
			addprocs(1)			
		end
		println("New worker added\nTotal: ",nworkers())

		
		push!(containers,ncontainers())
		push!(time,toc())
		@everywhere using DistributedArrays

		container_chunk = distribute(local_array, procs=[workers()[nworkers()]])  #stores a chunk(as an independent darray) in a container
		refs = vcat(refs, container_chunk.chunks)

	end
	
	if debug
		return DArray(refs),containers,time #this return is used for debugs and tests purposes. 
	end
		return DArray(refs) #This is the standard return
end


###=============================================================================
###=========================   Constructors   ==================================

@doc """
### DArray(input::AbstractString,args...)
creates a CloudArray from the file used on the input
""" ->
DistributedArrays.DArray(input::AbstractString, args...) = begin
	return	carray_from_task(task_from_text(input), args...)
end

DistributedArrays.DArray(input::Array, is_numeric::Bool=true,args...) = begin
	return	carray_from_task(task_from_array(input), is_numeric, args...)
end

###=============================================================================

