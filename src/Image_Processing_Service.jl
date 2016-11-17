using ParallelAccelerator
using ImageView
using StatsBase











include("/home/douglas/repositories/PolSARCloud.jl/src/ZoomImage.jl")
include("/home/douglas/repositories/PolSARCloud.jl/src/PauliDecomposition.jl")
imageFolder = "images/"



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
roiHeight= 151
roiWidth = 151
zoomHeight  = 150
zoomWidth   = 150
startPos = (1300,1300)
src = open("images/SanAnd_05508_10007_005_100114_L090HHHH_CX_01.mlc")


function areLimitsWrong(summary_height,src_height,summary_width,src_width,starting_line,roi_height,roi_width,starting_col)
#checking if the summary overleaps the roi
print("\n")
print("summary_height: ",summary_height,"\n")
print("src_height: ",src_height,"\n")
print("src_width: ",src_width,"\n\n")
print("starting_col: ",starting_col,"\n")
print("starting_line: ",starting_line,"\n\n")
print("roi_width: ",roi_width,"\n")
print("roi_height: ",roi_height,"\n")

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
		

		band_A = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[1]))
		band_B = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[2]))
		band_C = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[3]))

		println("Deu zoom suave")		
		println("Deu reshape suave")

		#roi_subarray = PauliDecomposition(band_A, band_B, band_C, summary_height, summary_width)

 		band_A, band_B, band_C = PauliDecomposition(band_A, band_B, band_C, summary_height, summary_width)

		output = process(algorithm,summary_size::Tuple{Int64,Int64}, roi::Tuple{Int64,Int64},band_A,band_B,band_C) 			

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
		println("Criou buffer ")	


		#TODO criar uma função para englobar estas chamadas da runStencil
	
		runStencil(buffer_A, cpBand_A, iterations, :oob_src_zero) do b, a
			b[0,0] =  blur(a)
			return a, b
		end

		runStencil(buffer_B, cpBand_B, iterations, :oob_src_zero) do b, a
			b[0,0] =  blur(a)
			return a, b
		end

		runStencil(buffer_C, cpBand_C, iterations, :oob_src_zero) do b, a
			b[0,0] =  blur(a)
			return a, b
		end
		


		buffer[:,:,1] = buffer_A
		buffer[:,:,2] = buffer_B
		buffer[:,:,3] = buffer_C
		

		#Todo these vec calls are dumb and the should be removed
		buffer_A = vec(buffer_A)
		buffer_B = vec(buffer_B)
		buffer_C = vec(buffer_C)

		buffer = reshape([[buffer_A],[buffer_B],[buffer_C]],(summary_size[1],summary_size[2],3))
		if (shiftTrace)
			stacktrace!(algorithm, summary_size, roi,start,buffer)
		end
		return buffer
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
		println(i)
		newImg = process(algs[i],img,shiftTrace)		
		img = copy(newImg)
	end
	
	return newImg
end



function process() #Method designed for implementation tests
	return process(blur, (zoomWidth,zoomHeight), (roiHeight-1,roiWidth-1), startPos)  
end


function removefilter(trace::Trace, index)
	if (index > 1)
		print("There's no such filter in this index")
	end
end



x = process()

#ImageView.view(x)


