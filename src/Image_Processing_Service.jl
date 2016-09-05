using ParallelAccelerator
using ImageView
using StatsBase











include("/home/naelson/repositories/PolSARCloud.jl/src/ZoomImage.jl")
include("/home/naelson/repositories/PolSARCloud.jl/src/PauliDecomposition.jl")
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
roiHeight= 260
roiWidth = 260
zoomHeight  = 250
zoomWidth   = 250
startPos = (1000,1000)
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
function process(algorithm, summary_size::Tuple{Int64,Int64}, roi::Tuple{Int64,Int64}, start::Tuple{Int64,Int64}; debug::Bool=false) 
	starting_line = start[1]
	starting_col = start[2]	
	starting_pos =  starting_line + (starting_col-1)*src_width

	roi_height = roi[1]
	roi_width = roi[2]

	summary_height = summary_size[1]
	summary_width = summary_size[2]

	row_step = Int64(round(roi_height/summary_height))
	col_step = Int64(round(roi_width/summary_width))	


	if (areLimitsWrong(summary_height,src_height,summary_width,src_width,starting_line,roi_height,roi_width,starting_col))		
	else

		srcs = selectImage("mlc")
		roi_subarray = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, src) 

		band_A = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[1]))
		band_B = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[2]))
		band_C = ZoomImage(starting_pos, roi_height, roi_width, summary_height, summary_width, src_height, src_width, open(srcs[3]))

		println("Deu zoom suave")		
		println("Deu reshape suave")

		roi_subarray = PauliDecomposition(band_A, band_B, band_C, summary_height, summary_width)			

		return process(algorithm,summary_size, roi,roi_subarray)
	end
end

#This function process a matrix. It's a subrotine for the bigger process function
function process(algorithm,summary_size, roi, img) 
		

		
		buffer = copy(img)
		iterations = 1
		println("Criou buffer suave")
		runStencil(buffer, img, iterations, :oob_src_zero) do b, a
			b[0,0] =  algorithm(a)
			return a, b
		end
		stacktrace!(algorithm, summary_size, roi,start,buffer)
		return buffer
		
end


function process()
	return process(blur, (zoomWidth,zoomHeight), (roiHeight-1,roiWidth-1), startPos) 
end