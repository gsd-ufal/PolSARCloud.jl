# PolSARCloud.jl


#Dependencies
##These are the packages you'll need to install in your Julia:

* [ParallelAccelerator package](https://github.com/IntelLabs/ParallelAccelerator.jl)

* [Images package](https://github.com/JuliaImages/Images.jl)

#Usage

In order to import and use PolSARCloud you nedd to include the file [Image_Processing_Service.jl](https://github.com/gsd-ufal/PolSARCloud.jl/blob/master/src/Image_Processing_Service.jl) with:
  	 
     include("src/Image_Processing_Service.jl")
     
 
The main method of the package is the process(...), which in it's simplest form takes two arguments as process(algorithm, image), where
   
* algorithm is a function writen in the [ParallelAccelerator notation](https://github.com/gsd-ufal/PolSARCloud.jl/blob/master/src/Image_Processing_Service.jl#L119)    
* image is the input matrix to be processed by the algorithm.

 
