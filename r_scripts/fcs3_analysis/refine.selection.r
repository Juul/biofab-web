
# In-house ad-hoc selection criterion for clustering

# If more two clusters found, and no good ICL found for selected, 
# then choose the best cluster based on these BIOFAB-specific criteria.

refine.selection = function(flowclustlist, verbose=FALSE) {

  if(length(flowclustlist) < 2) {
    return(flowclustlist)
  }

  if(flowclustlist[[flowclustlist@index]]@ICL > 0) {
    return(flowclustlist)  
  }

  if(is.na(flowclustlist[[1]]@ICL)) {
    return(flowclustlist)
  }

  if(is.na(flowclustlist[[2]]@ICL)) {
    return(flowclustlist)
  }

  # TODO shouldn't the clustering already have selected the cluster with the best ICL? event if both are negative?
  # ICL have preceedence
  if(flowclustlist[[2]]@ICL / flowclustlist[[1]]@ICL < 1) {

    flowclustlist@index = 2
    if(verbose) {
      cat("Negative likelihood but favorable ICL", flowclustlist[[2]]@ICL/flowclustlist[[1]]@ICL," : keep 2nd cluster\n")
    }

  } else if(abs(flowclustlist[[2]]@ICL / flowclustlist[[2]]@BIC) >= 2.5) {

    flowclustlist@index = 1
    if(verbose) {
      cat("Way High ICL/BIC ratio ", abs(flowclustlist[[2]]@ICL/flowclustlist[[2]]@BIC)," : keep 1 cluster\n") 
    }

  } else if(flowclustlist[[2]]@BIC/flowclustlist[[1]]@BIC < 1) {

    flowclustlist@index = 2
    if (verbose) {
      cat("BIC based clustering", flowclustlist[[2]]@BIC,"\n")
    }

  }

  return(flowclustlist)
}