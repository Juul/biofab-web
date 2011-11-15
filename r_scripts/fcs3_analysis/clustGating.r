        
# Return a list containing the filtered flowframe and a vector containing length of minor pop

clustGating = function(flowframe, 
                       mapping=FALSE,
                       fluo.channel="", 
                       scale.gating="Lin",
                       scale.analysis="Log", 
                       levels=c(0.95,0.95), 
                       out.path.plot=FALSE) {

  fluo = get.fluo(fluo.channel, scale.gating)
  fluo.gating = get.fluo(fluo.channel, scale.gating)
  fluo.analysis = get.fluo(fluo.channel, scale.analysis)

  mix = NULL
  noclust = 0

  # Refine forward and side scatter gating
  clust.cell = flowClust(flowframe, varNames=c("FSC-HLog", "SSC-HLog"), K=1, level=levels[1])
  flowframe = Subset(flowframe, clust.cell)

  # skip if less than 10 measurements
  if(nrow(flowframe@exprs) <= 50) {
    return(error.data("Too few events remaining after forward and side scatter gating"))
  }

  # Then on the channel, choosing the best of 1 or 2 cluster(s)
  # based on the Integrated Completed Likelihood measure
  # retain the most abundant pop as the good one and status the other

  clust.fluo = flowClust(flowframe, varNames=fluo.analysis, K=1:2, level=levels[2], criterion="ICL", nu=4, nu.est=0, trans=0, randomStart=25)
  clust.fluo = refine.selection(clust.fluo)
  noclust = clust.fluo[[clust.fluo@index]]@K

  cat("Number of clusters: ", noclust, "\n")

  if (noclust == 1) {

    flowframe = Subset(flowframe, clust.fluo)

    cat("In cluster: ", nrow(flowframe@exprs), "\n")

    # skip if less than 10 measurements
    if(nrow(flowframe@exprs) <= 50) {
      return(error.data("Too few events in only cluster"))
    }

    if (nrow(flowframe > 2)) {
      flowframe@description$"sw.p.value"=shapiro.test(flowframe@exprs[,fluo])$p.value
    }

    if (out.path.plot != FALSE) {
      draw.plot(flowframe, fluo.analysis, out.path.plot)
    }

  } else if (noclust == 2) {

    subpop = split(flowframe, clust.fluo) 

    cat("In cluster 1: ", nrow(subpop[[1]]@exprs), "\n")
    cat("In cluster 2: ", nrow(subpop[[2]]@exprs), "\n")

    # ensure minimum expressions
    if((nrow(subpop[[1]]@exprs) < 50) | (nrow(subpop[[2]]@exprs) < 50)) {
      return(error.data("Too few events in one of the two clusters"))
    }

    if (out.path.plot != FALSE) {

      mix = draw.plot.double(flowframe, subpop, fluo.analysis, out.path.plot)
    }
  }

  if (class(mix) != 'NULL') { # if there were two clusters

    # TODO removed nameByWell calls. not sure if it will break something
    clust.data = list(cluster1=flowframe, cluster2=mix)
    nclust = list(cluster1=noclust, cluster2=2) 

  } else { # if there was only one cluster

    clust.data = list(cluster1=flowframe, cluster2=NULL)
    nclust=list(cluster1= noclust, NULL)
  }


  # update descriptions

  for (i in 1:length(clust.data)) {
    if (is.null(clust.data[[i]])) {
      next
    }

    clust.data[[i]]@description$cell.nbr=nrow(clust.data[[i]])
    clust.data[[i]]@description$cluster=nclust[[i]]


    if (nrow(clust.data[[i]])>2) {

      clust.data[[i]]@description[paste(fluo.analysis,".sw.p.value",sep="")]=shapiro.test(clust.data[[i]]@exprs[,fluo.analysis])$p.value

      if (clust.data[[i]]@description[paste(fluo.analysis,".sw.p.value",sep="")] <1e-10) {
        if (!is.null(clust.data[[i]]@description$status)) {

          if (clust.data[[i]]@description$status != "Not set") {
  
            clust.data[[i]]@description$status=paste(clust.data[[i]]@description$status, paste("Non-Normal",fluo.analysis,"distribution"), sep=" / ")

          } else {
            clust.data[[i]]@description$status=paste("Non-Normal",fluo.analysis,"distribution")
          }
        } else {
          clust.data[[i]]@description$status=paste("Non-Normal",fluo.analysis,"distribution")
        }
      }
    }


    if (clust.data[[i]]@description$cell.nbr <=1000) {

      if ((class(clust.data[[i]]@description$status) == 'NULL')) {
        clust.data[[i]]@description$status="Low cell number"
      } else if(clust.data[[i]]@description$status != "Not set") {
        clust.data[[i]]@description$status="Low cell number"
      } else {
        clust.data[[i]]@description$status=paste(clust.data[[i]]@description$status, "Low cell number", sep=" / ")
      }
    }
  }

  return(clust.data)

}



