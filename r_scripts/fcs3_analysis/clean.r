
clean=function(flowset, mapping=FALSE, fluo=FALSE, cluster=TRUE, scale="Log", verbose=TRUE)
{
	#out.message=file("sink_out.txt", open="wt")
	#sink(out.message, type="message")
	if (verbose) cat("Fluorescence channels:", paste(fluo),"\n")
	if (verbose) cat("Cleaning... \n")
	flowset =clean.flowSet(flowset, mapping, fluo, scale)
	if (verbose) cat("Gating... \n")
	filter  =ellipseGateFilter(flowset)
	flowset =Subset(flowset, filter)
	if (cluster & (is.list(mapping) | fluo!=FALSE))
	{
		clust = clustGating(flowset,mapping,fluo)
		#sink(type="message")
		#close(out.message)
		return(clust[[1]])
	}
	#sink(type="message")
	#close(out.message)
	return(flowset)
}
