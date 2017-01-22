using ParallelAccelerator
using ImageView
using StatsBase



include("/home/douglas/repositories/PolSARCloud.jl/src/ZoomImage.jl")
include("/home/douglas/repositories/PolSARCloud.jl/src/PauliDecomposition.jl")
imageFolder = "images/"
test_output="test_output.csv"
tic()
toc()


if(isfile("test_output.csv"))
	test_log = readcsv(test_output)
else
	
	test_log = ["Zoom_A","Zoom_B","Zoom_C","Decomposition","Filter_A","Filter_B","Filter_C","Process_Time"]'
	writecsv(test_output,test_log)	
end



tracing = true


type Trace
	step
	algorithm
	summary_size
	roi
	start
	image
end

global_trace = Trace(0,[],[],[],[],[])


function insertfilter!(trace::Trace, algorithm, pos::Int)
	trace.algorithm[pos] = algorithm
end

function appendfilter!(trace::Trace, algorithm)	
	insertfilter!(trace,algorithm,length(trace.algorithm))
end


function stackfilter!(trace::Trace, algorithm)

end

#"/home/naelson/Área\ de\ Trabalho/"



function selectImage(filetype;folder=imageFolder)    
    
    files = readdir(folder)
    filter!(files) do a
        contains(a,filetype)
    end

    #an image can have multiple bands in multiple files
    imagePaths = Array(AbstractString, length(files))

    for (i = 1:length(imagePaths))
        imagePaths[i] = joinpath(folder, files[i])
    end
    return imagePaths
end







function initiate(image_id::Int64, business_model)
end

function set_up_VM(resource_requirements)
end

function book_and_start(VM) #Most likely a VM id, so in this case it would be an integer. TODO
end

function load_time(image_id::Int64)
end

function view(output_id::Int64, format::AbstractString)
end

function stop_and_get_bill()
end

function get_bill()
end




function stacktrace!(algorithm, summary_size, roi,start,image; trace::Trace=global_trace)
	trace.step+=1
	push!(trace.algorithm,algorithm)
	push!(trace.summary_size,summary_size)
	push!(trace.roi,roi)
	push!(trace.start,start)
	push!(trace.image,image)
end
	


#Sample algorithm
function box_filter(a) 
	((a[-1,-1]+ a[-1,+1] + a[-1,0] + a[0,+1]+a[0,-1]+a[+1,+1]+a[+1,0]+a[+1,-1])/8)
end

function blur(a)
			(a[-2,-2] * 0.003  + a[-1,-2] * 0.0133 + a[0,-2] * 0.0219 + a[1,-2] * 0.0133 + a[2,-2] * 0.0030 +
             a[-2,-1] * 0.0133 + a[-1,-1] * 0.0596 + a[0,-1] * 0.0983 + a[1,-1] * 0.0596 + a[2,-1] * 0.0133 +
             a[-2, 0] * 0.0219 + a[-1, 0] * 0.0983 + a[0, 0] * 0.1621 + a[1, 0] * 0.0983 + a[2, 0] * 0.0219 +
             a[-2, 1] * 0.0133 + a[-1, 1] * 0.0596 + a[0, 1] * 0.0983 + a[1, 1] * 0.0596 + a[2, 1] * 0.0133 +
             a[-2, 2] * 0.003  + a[-1, 2] * 0.0133 + a[0, 2] * 0.0219 + a[1, 2] * 0.0133 + a[2, 2] * 0.0030)
end



src_height= 11858
src_width = 1650
roiHeight= 1001
roiWidth = 1001
zoomHeight  = 1000
zoomWidth   = 1000
startPos = (1,1)
src = open("images/SanAnd_05508_10007_005_100114_L090HHHH_CX_01.mlc")


function areLimitsWrong(summary_height,src_height,summary_width,src_width,starting_line,roi_height,roi_width,starting_col)


	if (summary_height > src_height || summary_width > src_width)
		println("Your summary size overleaps the ROI size")
		return true	
	end

	#Checking if roi_y > src_y
	if ( (starting_line-1 + roi_height) > src_height)
		
		println("Your ROI height overleaps the source height")
		return true
	end
		#Checking if roi_x > src_x		
	if (starting_col-1 + roi_width > src_height)
		println("Your ROI width overleaps the source frame.")
		return true
	end
	return false
end







#This function process the algorithm in the image following the specified roi begining in the start(int int) point
function process(algorithm, summary_size::Tuple{Int64,Int64}, roi::Tuple{Int64,Int64}, start::Tuple{Int64,Int64},shiftTrace::Bool=true; debug::Bool=false) 
	starting_line = start[1]
	starting_col = start[2]	
	starting_pos =  starting_line + (starting_col-1)*src_width

	roi_height = roi[1]
	roi_width = roi[2]

	summary_height = summary_size[1]
	summary_width = summary_size[2]

	


	if (areLimitsWrong(summary_height,src_height,summary_width,src_width,starting_line,roi_height,roi_width,starting_col))				
		else

			srcs = selectImage("mlc")
			tic() #for total time
			tic()
			band_A = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[1]))
			zoomA_time = toc()

			tic()
			band_B = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[2]))
			zoomB_time = toc()

			tic()
			band_C = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[3]))
			zoomC_time = toc()

			#println("Deu zoom suave")		
			#println("Deu reshape suave")

			#roi_subarray = PauliDecomposition(band_A, band_B, band_C, summary_height, summary_width)
			tic()
	 		band_A, band_B, band_C = PauliDecomposition(band_A, band_B, band_C, summary_height, summary_width)
	 		decomposition_time = toc()

			output,filters_time = process(algorithm,summary_size::Tuple{Int64,Int64}, roi::Tuple{Int64,Int64},band_A,band_B,band_C) 			
			
			#We only want to measure the filter processing time. Not the matrix operations
			total_time = toc()  - (zoomA_time+zoomB_time+zoomC_time+decomposition_time)
			
			new_test = round([zoomA_time,zoomB_time,zoomC_time,decomposition_time,filters_time[1],filters_time[2],filters_time[3],total_time]',4)
			new_test = vcat(test_log, new_test)			
			writecsv(test_output,new_test)
			return output
		end
end




#This function process a matrix. It's a subrotine for the bigger process function
function process(algorithm,summary_size, roi, band_A,band_B,band_C,shiftTrace::Bool=true) 	

		
		#buffer = zeros(Real,length(img[:,1,1]),length(img[1,:,1]),length(img[1,1,:]))




		buffer_A = reshape(band_A,(summary_size[1],summary_size[2]))
		buffer_B = reshape(band_B,(summary_size[1],summary_size[2]))
		buffer_C = reshape(band_C,(summary_size[1],summary_size[2]))
		
		

		buffer = Array(Real,summary_size[1],summary_size[2], 3)
		


		cpBand_A = copy(buffer_A)
		cpBand_B = copy(buffer_B)
		cpBand_C = copy(buffer_C)
		






		
		iterations = 1
		#println("Criou buffer ")	


		#TODO criar uma função para englobar estas chamadas da runStencil
		tic()
		runStencil(buffer_A, cpBand_A, iterations, :oob_src_zero) do b, a
			b[0,0] =  blur(a)
			return a, b
		end
		filter_A = toc()


		tic()
		runStencil(buffer_B, cpBand_B, iterations, :oob_src_zero) do b, a
			b[0,0] =  blur(a)
			return a, b
		end
		filter_B = toc()


		tic()
		runStencil(buffer_C, cpBand_C, iterations, :oob_src_zero) do b, a
			b[0,0] =  blur(a)
			return a, b
		end
		filter_C = toc()
		


		buffer[:,:,1] = buffer_A
		buffer[:,:,2] = buffer_B
		buffer[:,:,3] = buffer_C
		
		
		#Todo these vec calls are dumb and the should be removed
		buffer_A = vec(buffer_A)
		buffer_B = vec(buffer_B)
		buffer_C = vec(buffer_C)
		#println("Criou buffer x")
		#print("BUFFER A ",length(buffer_A))
		#print("\n")
		#print("BUFFER B ",length(buffer_B))
		#print("\n")
		#print("BUFFER C ",length(buffer_C))
		#print("\n")

		#print("SUmmary size 1 ",summary_size[1])
		#print("\n")
		#print("SUmmary size 2 ",summary_size[2])
		#print("\n")


		buffer = reshape([[buffer_A],[buffer_B],[buffer_C]],(summary_size[1],summary_size[2],3))

		if (shiftTrace)
			stacktrace!(algorithm, summary_size, roi,start,buffer)
		end

		#return reshape([[band_A],[band_B],[band_C]], (150,150,3))
		return buffer,[filter_A,filter_B,filter_C]'
end


function process(algorithm, img,shiftTrace::Bool=true)
	ylen = length(img[:,:,1][:,1])
	xlen = length(img[:,:,1][1,:])

 	process(algorithm,(xlen,ylen), (xlen,ylen), img[:,:,1],img[:,:,2],img[:,:,3],shiftTrace) 
end


function walktrace(trace::Trace, img,shiftTrace::Bool=false)
	algs = trace.algorithm
	newImg = -1
	for i = 1:length(algs)
		#println(i)
		newImg = process(algs[i],img,shiftTrace)		
		img = copy(newImg)
	end
	
	return newImg
end



function process() #Method designed for implementation tests
	return process(blur, (zoomWidth,zoomHeight), (roiHeight-1,roiWidth-1), startPos)  
end


function removefilter!(trace::Trace, index)
	if ((index < 1) || (index > length(trace.algorithm)))
		#print("There's no such filter in this index")
	else
		deleteat!(trace.algorithm, index)
		#print("Filter removed")
	end
end



#x = process()

#ImageView.view(x)


