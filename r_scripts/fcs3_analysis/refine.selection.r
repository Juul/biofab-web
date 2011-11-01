
# In-house ad-hoc selection criterion for clustering

refine.selection = function(flowclustlist, verbose=FALSE) {

	if (flowclustlist[[flowclustlist@index]]@ICL <= 0)
	{
		# ICL have preceedence
		if (flowclustlist[[2]]@ICL/flowclustlist[[1]]@ICL<1) {
			flowclustlist@index = 2
			if (verbose) cat("Negative likelihood but favorable ICL", flowclustlist[[2]]@ICL/flowclustlist[[1]]@ICL," : keep 2 cluster\n")}
		# likelihood change sign: typical of very close clusters
		#else if (flowclustlist[[2]]@logLike/flowclustlist[[1]]@logLike <0) {
		#	flowclustlist@index = 2
		#	cat("likelihood switch: keep 2 cluster\n")}
		# 2 or 3 work well
		else if (abs(flowclustlist[[2]]@ICL/flowclustlist[[2]]@BIC)>=2.5) {
			flowclustlist@index = 1
			if (verbose) cat("Way High ICL/BIC ratio ", abs(flowclustlist[[2]]@ICL/flowclustlist[[2]]@BIC)," : keep 1 cluster\n") }
		else if (flowclustlist[[2]]@BIC/flowclustlist[[1]]@BIC<1) {
			flowclustlist@index = 2
			if (verbose) cat("BIC based clustering", flowclustlist[[2]]@BIC,"\n")}
	}
	return(flowclustlist)
}