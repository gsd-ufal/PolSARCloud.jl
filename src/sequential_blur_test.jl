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
			
			
			
			return band_A,band_B,band_C
		end
end

band_A,band_B,band_C = getbands((roiHeight,roiWidth), (roiHeight,roiWidth),startPos)