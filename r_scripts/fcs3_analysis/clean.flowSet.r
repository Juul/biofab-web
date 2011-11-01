

clean.flowSet=function(flowset, mapping=FALSE, fluo=FALSE, scale="Log")
{	
	## Clean all the mess
	well=vector("character", length(flowset))
	desc=vector("character", length(flowset))
	keep=rep(TRUE, length(flowset))
	for (i in 1:length(flowset))
	{
		channels = c()
		# Check Mapping and fluo channels
		if (is.list(mapping)) {
      		if (flowset[[i]]@description$`$WELLID` %in% row.names(mapping)) {
				desc[i] = mapping[flowset[[i]]@description$`$WELLID`,"description"]
				channels = get.fluo(mapping[flowset[[i]]@description$`$WELLID`,"fluo"], scale) }
			else keep[i] = FALSE 
		}
    	if (fluo!=FALSE) channels =get.fluo(fluo, scale)
		well[i] = flowset[[i]]@description$`$WELLID`
		# clean linear values
		if ("GRN-HLog" %in% channels & "RED2-HLog" %in% channels)
			flowset[[i]] =flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0 & flowset[[i]]@exprs[,"GRN-HLin"]>0 & flowset[[i]]@exprs[,"RED2-HLin"]>0]
		else if ("GRN-HLog" %in% channels)
			flowset[[i]] =flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0 & flowset[[i]]@exprs[,"GRN-HLin"]>0]
		else if ("RED2-HLog" %in% channels)
			flowset[[i]] =flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0 & flowset[[i]]@exprs[,"RED2-HLin"]>0]
		else
			flowset[[i]] =flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0]
		# correct for log transform
		flowset[[i]]@exprs[,"GRN-HLin"]=flowset[[i]]@exprs[,"GRN-HLin"]+1
		flowset[[i]]@exprs[,"RED2-HLin"]=flowset[[i]]@exprs[,"RED2-HLin"]+1
		# recalculate logs
		flowset[[i]]@exprs[,"FSC-HLog"] =log10(flowset[[i]]@exprs[,"FSC-HLin"])
		flowset[[i]]@exprs[,"SSC-HLog"] =log10(flowset[[i]]@exprs[,"SSC-HLin"])
		#if ("GRN-HLog" %in% channels)
			flowset[[i]]@exprs[,"GRN-HLog"] =log10(flowset[[i]]@exprs[,"GRN-HLin"])
		#if ("RED2-HLog" %in% channels)
			flowset[[i]]@exprs[,"RED2-HLog"] =log10(flowset[[i]]@exprs[,"RED2-HLin"])
	}
	# Name samples by well
	sampleNames(flowset) = well
	# Add new descriptions
	keyword(flowset) = list(description=desc)
	keyword(flowset) = list(status="Not set")
	keyword(flowset) = list("GRN-HLog.sw.p.value"=NA)
	keyword(flowset) = list("RED2-HLog.sw.p.value"=NA)
	keyword(flowset) = list(cluster=NA)
	keyword(flowset) = list(cluster.100=NA)
	keyword(flowset) = list(cell.nbr=NA)
	# Change descriptions messing with I/O
	keyword(flowset) = list("GTI$USERNAME"="GUAVAHTGTI")
	# Remove unmapped samples
	flowset = flowset[keep]
	# Re-order
	flowset = flowset[order(sampleNames(flowset)),]
	return(flowset)
}

