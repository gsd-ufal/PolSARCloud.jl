using Images
include("Image_Processing_Service.jl")

function getbands(summary_size::Tuple{Int64,Int64}, roi::Tuple{Int64,Int64}, start::Tuple{Int64,Int64}) 
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

			
	 		band_A, band_B, band_C = PauliDecomposition(band_A, band_B, band_C, summary_height, summary_width)
	 		

			#output,filters_time = process(algorithm,summary_size::Tuple{Int64,Int64}, roi::Tuple{Int64,Int64},band_A,band_B,band_C) 			
			
			
			
			return reshape(band_A,roiHeight,roiWidth),reshape(band_B,roiHeight,roiWidth),reshape(band_C,roiHeight,roiWidth)
		end
end

band_A,band_B,band_C = getbands((roiHeight,roiWidth), (roiHeight,roiWidth),startPos)



serialtest_output = "serial_test_output.csv"

	if(isfile(serialtest_output))
		test_log = readcsv(serialtest_output)
	else	
		test_log = ["Filter_A","Filter_B","Filter_C","Total Time"]'
		writecsv(serialtest_output,test_log)	
	end

function serialtest()
	sigma=[5,5]
	tic()
	toc()
	for (i=1:30)
		test_log = readcsv(serialtest_output)
		tic()
		tic()
		imfilter_gaussian(band_A,[sigma[1],sigma[2]])
		bandA_time = toc()
		
		tic()
		imfilter_gaussian(band_B,[sigma[1],sigma[2]])
		bandB_time = toc()

		tic()
		imfilter_gaussian(band_C,[sigma[1],sigma[2]])
		bandC_time = toc()
		totalTime = toc()
		newtest = [bandA_time,bandB_time,bandC_time,totalTime]';
		

		newtest = vcat(test_log, newtest)	
		writecsv(serialtest_output,newtest)
	end

end