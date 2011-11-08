
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



options(keep.source = TRUE, error = 
  quote({ 
    cat("Environment:\n", file=stderr()); 

    # TODO: setup option for dumping to a file (?)
    # Set `to.file` argument to write this to a file for post-mortem debugging    
    dump.frames();  # writes to last.dump

    #
    # Debugging in R
    #   http://www.stats.uwo.ca/faculty/murdoch/software/debuggingR/index.shtml
    #
    # Post-mortem debugging
    #   http://www.stats.uwo.ca/faculty/murdoch/software/debuggingR/pmd.shtml
    #
    # Relation functions:
    #   dump.frames
    #   recover
    # >>limitedLabels  (formatting of the dump with source/line numbers)
    #   sys.frame (and associated)
    #   traceback
    #   geterrmessage
    #
    # Output based on the debugger function definition.

    n <- length(last.dump)
    calls <- names(last.dump)
    cat(paste("  ", 1L:n, ": ", calls, sep = ""), sep = "\n", file=stderr())
    cat("\n", file=stderr())

    if (!interactive()) {
      q()
    }
}))
