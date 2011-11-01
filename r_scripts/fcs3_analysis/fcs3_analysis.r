
# required packages
library(flowCore)
library(flowViz)
library(flowClust)
library(RSvgDevice)
#library(xlsx)

# parameters
layout.folder = file.path(getwd(),"Dropbox/BIOFAB/Wet Lab/Data/Plate layout") # TODO static!
fluo.type <<-c() # TODO why does this use <<- instead of <- ?

source('run.r')
source('norm2length.r')
source('get.fluo.r')
#source('clean.r')
source('clean.flowSet.r')
source('nameByWell.r')
source('getMapping.r')
source('ellipseGateFilter.r')
source('rectangularGateFilter.r')
source('cov.matrix.r')
source('clustGating.r')
source('refine.selection.r')
source('extractData.r')
source('combine.replicates.r')
source('write2xls.r')
source('multi.ecdf.r')


