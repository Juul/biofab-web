
# Correct for background and reference as applicable (defined in mapping)
# Somewhat arbitrarily, eliminate measures which are below twice the background on the denominator channel, if applicable

extractData = function(flowset, 
                       mapping=FALSE, 
                       fluo="", 
                       scale="Lin", 
                       CV.treshold=1, 
                       low.rm=FALSE) {

	if (class(flowset) != "flowSet") {
    return(NULL)
  }
	
	# Initialization
	names=c()
	is.bkgd = FALSE
	is.ref  = FALSE
	if (is.list(mapping)) {
		names =c("description")
		fluo.type = names(table(unlist(strsplit(mapping$fluo,"/"))))
		if ("background" %in% colnames(mapping)) is.bkgd = TRUE
		if ("reference"  %in% colnames(mapping)) is.ref  = TRUE
	}
	if(fluo != "") {
		fluo.type=fluo
  }

	names =c(names, "cluster.nbr", "cell.nbr")
	fluos = get.fluo(fluo.type, scale)
	fluos.log = get.fluo(fluo.type, scale="Log")
	for (i in 1:length(fluos)) {
		names =c(names, paste("mean.",fluos[i],sep=""), paste("sd.",fluos[i],sep=""), paste("pval.",fluos.log[i],sep=""))
		if (is.bkgd) names=c(names,paste("mean.bkgd.",fluos[i],sep=""))
	}
	TE=NULL
	if (is.ref) {
		names=c(names,"ratio.bulk","mean.ratio.cell","sd.ratio.cell", "TE.bulk", "TE.cell")
		TE   = vector("list", length(flowset))
		names(TE)=sampleNames(flowset)
	}
	names=c(names,"status")
	data = matrix(data=NA, ncol=length(names), nrow=length(flowset), dimnames=list(sampleNames(flowset), names))
	## Initial calculations for background, making sure all samples are in the dataset
	if (is.bkgd) {
		simple_names  = names(table(unlist(strsplit(mapping$background,"/"))))
		# check wells are in dataset
		check=simple_names %in% sampleNames(flowset)
		if (!all(check)) {
			cat("These background samples (", paste(simple_names[!check],sep=", "),") are not included in the dataset (",paste(sampleNames(flowset),sep=", "),")\n")
			simple_names=simple_names[check] }
		formula_names = c()
		for (name in names(table(mapping$background)))
			if ((!name %in% simple_names) & (all(unlist(strsplit(name,"/")) %in% simple_names)))
				 formula_names=c(formula_names, name)
		bkgk.names = c(simple_names, formula_names)
		# mean calculation
		bkgd = matrix(data=NA, nrow=length(bkgk.names), ncol=length(fluo.type), dimnames=list(bkgk.names, fluos))
		for (sample in simple_names)
			for (f in fluos) 
				bkgd[sample, f]  = mean(flowset[[sample]]@exprs[, f], na.rm=TRUE)
		for (sample in formula_names)
			for (f in fluos) 
				bkgd[sample, f]  = mean(bkgd[unlist(strsplit(sample,"/")), f], na.rm=TRUE)
	}
	
	## Initial calculations for references, making sure all samples are in the dataset
	if (is.ref)
	{
		simple_names =names(table(unlist(strsplit(mapping$reference,"/"))))
		# check reference are in dataset
		check=simple_names %in% sampleNames(flowset)
		if (!all(check)) {
			cat("These reference samples (", paste(simple_names[!check],sep=", "),") are not included in the dataset (",paste(sampleNames(flowset),sep=", "),")\n")
			simple_names=simple_names[check] }
		# further checks that corresponding backgrounds are in dataset
		check= mapping[simple_names,"background"] %in% sampleNames(flowset)
		if (!all(check)) {
			cat("These reference samples (", paste(simple_names[!check],sep=", "),") have no corresponding background in the dataset (",paste(sampleNames(flowset),sep=", "),")\n")
			simple_names=simple_names[check] }
		formula_names = c()
		for (name in names(table(unlist(mapping$reference))))
			if ((!name %in% simple_names) & (all(unlist(strsplit(name,"/")) %in% simple_names)))
				formula_names=c(formula_names, name)
		names = c(simple_names, formula_names)
		# background-substracted mean calculation
		ref = matrix(data=NA, nrow=length(names), ncol=2, dimnames=list(names, c("bulk","cell")))
		for (sample in simple_names)
		{
			#remove cells below twice the background on denominator
			if (low.rm)
				flowset[[sample]]=flowset[[sample]][flowset[[sample]]@exprs[, fluos[2]] >= 2*bkgd[mapping[sample,"background"], fluos[2]]]
			fluos = get.fluo(unlist(strsplit(mapping[sample,"fluo"], "/")), scale)
			ref[sample,"bulk"] = ( (mean(flowset[[sample]]@exprs[, fluos[1]]) - bkgd[mapping[sample,"background"], fluos[1]]) 
		 						  / (mean(flowset[[sample]]@exprs[, fluos[2]]) - bkgd[mapping[sample,"background"], fluos[2]]) )
			ref[sample,"cell"] = ( mean( (flowset[[sample]]@exprs[, fluos[1]] - bkgd[mapping[sample,"background"], fluos[1]]) 
							   	        / (flowset[[sample]]@exprs[, fluos[2]] - bkgd[mapping[sample,"background"], fluos[2]]), na.rm=TRUE) )
		}
		for (sample in formula_names)
			for (type in c("bulk","cell"))
				ref[sample, type] = mean(ref[unlist(strsplit(sample,"/")), type], na.rm=TRUE)
	}
	
	# Calculations for all samples
	for (well in sampleNames(flowset))
	{
		if (fluo!=FALSE) fluos = get.fluo(fluo, scale)
		else if (is.list(mapping)) fluos = get.fluo(mapping[well,"fluo"], scale)
		#remove cells below twice the background on denominator channel
		if (low.rm & is.bkgd & is.ref)
			if ((!well %in% bkgk.names) & (mapping[well,"background"] %in% row.names(bkgd))) {
				flowset[[well]]=flowset[[well]][flowset[[well]]@exprs[, fluos[2]] >= 2*bkgd[mapping[well,"background"],fluos[2]]]
				flowset[[well]]@description$cell.nbr = nrow(flowset[[well]])
			}
		if (flowset[[well]]@description$cell.nbr<=0){
			if (flowset[[well]]@description$status!="Not set")
				flowset[[well]]@description$status=paste(flowset[[well]]@description$status, "No cells", sep=" / ")
	  	    else
         		flowset[[well]]@description$status="No cells"
		}
		else {
			for (f in fluos) {
				data[well,paste("mean.", f, sep="")] = mean(flowset[[well]]@exprs[, f], na.rm=TRUE)
				data[well,paste("sd."  , f, sep="")] =   sd(flowset[[well]]@exprs[, f], na.rm=TRUE)
				if (data[well,paste("sd.", f, sep="")]/data[well,paste("mean.", f, sep="")]>=CV.treshold){
        			if (flowset[[well]]@description$status!="Not set")
						flowset[[well]]@description$status=paste(flowset[[well]]@description$status, paste(f, " CV>", CV.treshold, sep=""), sep=" / ")
			  		else
          				flowset[[well]]@description$status=paste(f, " CV>", CV.treshold, sep="")
          		}
      			if (is.bkgd)
					if (mapping[well,"background"] %in% row.names(bkgd)) {
						data[well,paste("mean.",f,sep="")]
						data[well,paste("mean.bkgd.",f,sep="")] =data[well,paste("mean.",f,sep="")]-bkgd[mapping[well,"background"],f]
					}
			} 
			if (is.ref){
				if (!(well %in% row.names(bkgd)) & (mapping[well,"background"] %in% row.names(bkgd))){
					data[well,"ratio.bulk"] = data[well, paste("mean.bkgd.", fluos[1],sep="")] / data[well, paste("mean.bkgd.", fluos[2],sep="")]
					r = ( (flowset[[well]]@exprs[, fluos[1]] - bkgd[mapping[well,"background"], fluos[1]]) 
			    		 / (flowset[[well]]@exprs[, fluos[2]] - bkgd[mapping[well,"background"], fluos[2]]) )
					data[well, "mean.ratio.cell"] = mean(r, na.rm=TRUE)
					data[well, "sd.ratio.cell"]   =   sd(r, na.rm=TRUE)
					if (mapping[well,"reference"] %in% row.names(ref)) {
						data[well,"TE.bulk"] = 100 * (1 - data[well,"ratio.bulk"] / ref[mapping[well,"reference"],"bulk"])
						data[well,"TE.cell"] = 100 * (1 - data[well, "mean.ratio.cell"] / ref[mapping[well,"reference"],"cell"]) 
						TE[[well]]=100 * (1 - r / ref[mapping[well,"reference"],"cell"])
					}
				}
			}
			if (fluo!=FALSE) fluos = get.fluo(fluo, "Log")
			else if (is.list(mapping)) fluos = get.fluo(mapping[well,"fluo"], "Log")
			for (f in fluos)
				data[well,paste("pval.",f,sep="")] =as.numeric(flowset[[well]]@description[[paste(f,".sw.p.value",sep="")]])
		}
	}
	data[,"cell.nbr"]    = as.numeric(unlist(keyword(flowset,"cell.nbr"), use.names=FALSE))
	data[,"cluster.nbr"] = as.numeric(unlist(keyword(flowset,"cluster"), use.names=FALSE))
	data=data.frame(data)
	# add text component last to avoid global coercion problem in matrix
	if ("description" %in% colnames(data))
		data[,"description"] = unlist(keyword(flowset,"description"), use.names=FALSE)
	data[,"status"] =unlist(keyword(flowset,"status"), use.names=FALSE)
  	data[,"status"][data[,"status"]=="Not set"]="OK"
  	data = data[order(row.names(data)),]
  	if (!is.null(TE)) names(TE)=paste(keyword(flowset,"description")," (",sampleNames(flowset),")",sep="")
	return(list(data,TE))
}