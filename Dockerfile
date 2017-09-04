FROM julialang/julia:v0.6.0-dev
MAINTAINER Naelson Douglas (naelson.dc.oliveira@gmail.com) VOLUME /data
CMD julia
RUN apt-get update && \
    apt-get install -y sudo gcc g++ && \
    rm -rf /var/lib/apt/lists/*
RUN julia -e 'Pkg.clone("https://github.com/IntelLabs/CompilerTools.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/IntelLabs/ParallelAccelerator.jl.git")'
RUN julia -e 'Pkg.build("ParallelAccelerator")'             
RUN sudo apt-get install git-all                         
RUN git clone https://github.com/IntelLabs/ParallelAccelerator.jl.git
