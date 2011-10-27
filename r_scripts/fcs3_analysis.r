# Load packages
library(flowCore)
library(flowViz)
library(flowClust)
library(xlsx)
# parameters
#setwd("~")
layout.folder <- file.path(getwd(),"Dropbox/BIOFAB/Wet Lab/Data/Plate layout")
fluo.type   <<- c()

# source("./fcs3_analysis.r")
# path folder with fcs subfolders
# pattern pltFAB1_
# layout folder where pltFAB_
analyse<-function(out_path, path, pattern="", layout.path=layout.folder, layout.pattern=pattern, fluo=FALSE, clean=TRUE, cluster=TRUE, init.gate="ellipse", mode="auto", clust_levels=c(0.95,0.95), verbose=TRUE)
{
	# Guess whether to go in duplicate (if folder with correct pattern detected) or single mode (otherwise)
	folders <-dir(path=path, recursive=FALSE, full.names=TRUE, pattern=pattern)
	for (ignored.folders in c("plot","cleaned_data","bad"))
		folders<-folders[grep(ignored.folders, basename(folders), ignore.case=TRUE, value=FALSE, invert=TRUE)]
	folders <-folders[file.info(folders)$isdir==TRUE]
	if (mode == "auto") {
		if (length(folders)==0) mode="single"	
		else mode="replicate" }
	if (mode == "single") {
		if (verbose) cat("Run initiated in single mode\n")
		folders   <- path
		splitpath <- unlist(strsplit(path,"/"))
		path      <- do.call(file.path, as.list(splitpath[1:(length(splitpath)-1)])) } 
	else if (verbose) {
		cat("Run initiated in replicate mode\nFound the following folders:\n")
		cat(folders,sep="\n")}

	# Get layout file
	ismapped <- FALSE
	mapping  <- FALSE
	if (!file.info(layout.path)$isdir)
	{
		if (verbose) cat("Specified layout: ", layout.path,"\n")
		mapping <- getMapping(layout.path)
		ismapped=TRUE
	}
	else if (layout.pattern != "")
	{
		layout.files <- list.files(path=layout.path, pattern=layout.pattern, full.names=TRUE)

		if (length(layout.files) == 1) {
			if (verbose) cat("Found the following layout: ", layout.files,"\n")
			mapping <- getMapping(layout.files)
			ismapped=TRUE }
		else if (length(layout.files) > 1) {
			if (verbose) cat("Found several layouts, please refine matching pattern:\n")
			return(print(layout.files)) }
		else if (verbose)  {
      cat("No layout found...\n")
      return
    }
	}
	if (ismapped == FALSE) # try to search locally for files containing layout and same name as input
	{
		layout.files <- list.files(path=path, pattern="layout", recursive=TRUE, full.names=TRUE)
		layout.files <- layout.files[grep(basename(path), layout.files)]
		if (length(layout.files) == 1) {
			if (verbose) cat("Found the following layout: ", layout.files,"\n")
			mapping <- getMapping(layout.files)
			ismapped=TRUE }
		else if (length(layout.files) > 1) {
			if (verbose) {
				cat("Found several possible layouts, in specified path", layout.files,sep="\n")
				cat("Selected: ", min(layout.files))}
			mapping <- getMapping(min(layout.files))
			ismapped=TRUE }
	}
	if (ismapped == FALSE)
		if (verbose) cat("No layout specified...\n")
	# Process fluo
	# Processed in sub-functions
	if (fluo == FALSE & !ismapped & verbose) cat("No fluorescence channel selected...\n")
	# Cluster and restrictions
	if (is.logical(cluster)) {
		if (cluster==TRUE) clusterize<-TRUE }
	else if (is.list(cluster))
		clusterize<-TRUE
	else
		clusterize<-FALSE
	## analyse data
	data  <-vector("list")
	mixed <-vector("list")
	for (i in 1:length(folders)) {
		if (verbose) cat("Reading folder ",folders[i],"...\n",sep="")
		pheno=FALSE
		if (length(list.files(path=folders[i], pattern="annotation.txt", full.names=FALSE))==1)
			pheno="annotation.txt"
		flowset<-read.flowSet(path=folders[i], pattern=".fcs", phenodata=pheno)
		if (clean==TRUE) {
			if (verbose) cat("Cleaning... ")
			flowset <-clean.flowSet(flowset, mapping, fluo, scale="Log")
			filter <- NULL
			if (init.gate == "ellipse") {
				if (verbose) cat("Recapitulate ellipsoidal gating... ")
				filter  <-ellipseGateFilter(flowset)
			}
			else if (init.gate == "rectangle") {
				if (verbose) cat("Recapitulate rectangular gating... ")
				filter  <-rectangularGateFilter(flowset)
			}
			flowset <-Subset(flowset, filter)
			second.peak<-NULL
			if (clusterize)
				if (ismapped!=FALSE | fluo!=FALSE) {
					if (verbose) cat("Clustered Gating...")
					if (pattern!="") plotout<-file.path(path,paste("Plots",pattern,sep="_"))
					else plotout<-file.path(path,"Plots")
					restrict<-FALSE
					if (is.list(cluster)) restrict<-cluster[[i]]
					clusters    <- clustGating(flowset, mapping=mapping, fluo=fluo, scale="Log", cluster_rule=restrict, output=c(out_path, basename(folders[i])), levels=clust_levels)
					flowset     <- clusters[[1]]
					second.peak <- clusters[[2]]
				}
			if (verbose) cat("Saving fcs files... ")
			write.flowSet(flowset, file.path(path,paste("Cleaned_data",pattern,sep="_"),"Cluster1",basename(folders[i])),filename=sampleNames(flowset))
			if (class(second.peak) == "flowSet")
				write.flowSet(second.peak, file.path(path, paste("Cleaned_data",pattern,sep="_"),"Cluster2",basename(folders[i])),filename=sampleNames(second.peak))
		}
		else {
			cat("NB: Data processed as is... ")
			flowset <-nameByWell(flowset)
			second.peak<-NULL
		}
		if (verbose) cat("Processing data... ")
		processed.data <- extractData(flowset, mapping, fluo)
		data[[basename(folders)[i]]] <- processed.data[[1]]
		if (verbose) cat("Writing xlsx... ")
		overwrite=FALSE
		if (i==1) overwrite=TRUE
		print(data[basename(folders)[i]])
		write2xls(file.path(path,paste("Summary_",pattern,".xlsx",sep="")),data[basename(folders)[i]], overwrite=overwrite, verbose=verbose)
		if (!is.null(processed.data[[2]]))
			multi.ecdf(processed.data[[2]])
		if (class(second.peak) == "flowSet") {
			processed.data <- extractData(second.peak, mapping, fluo)
			mixed[[basename(folders)[i]]] <- processed.data[[1]]
		}
		if (verbose) cat("Done.\n")
	}
	# clean lists
	if (mode=="replicate") {
		combined <- combine.replicates(data)
		data <- append(data, data.frame(Summary=0), 0)
		data$Summary <- combined }
	if (!length(mixed))
		mixed<-NULL
	## export to xlsx
	write2xls(file.path(out_path,paste("Summary_",pattern,".xlsx",sep="")),data,verbose=verbose)
	write2xls(file.path(out_path,paste("Cluster2_",pattern,".xlsx",sep="")),mixed,verbose=verbose)
	if (verbose) cat("All done!\n")
	return(data)
}

norm2length<-function(flowset,t=0)
{
	names<-c("well","mean.log10(RED2.log)","sd.log10(RED2.log)","mean.corrected","sd.corrected", "mean.corrected","sd.corrected")
	data<-matrix(nrow=length(flowset), ncol=length(names))
	colnames(data)<-names
	for (i in 1:length(flowset))
	{
		lin<-lm(`RED2.HLin`~`FSC.HLin`, data.frame(flowset[[i]]@exprs))
		r2 <-summary(lin)$r.squared
		if (r2>t)
		{
			corrected1<-((flowset[[i]]@exprs[,"RED2-HLin"]-lin$"coefficients"[[1]])
						 /(lin$"coefficients"[[2]]*flowset[[i]]@exprs[,"FSC-HLin"])
						 *mean(flowset[[i]]@exprs[,"RED2-HLin"]))
			plot(flowset[[i]]@exprs[,"FSC-HLin"],flowset[[i]]@exprs[,"RED2-HLin"], cex=0.5, main=flowset[[i]]@description$`$WELLID`)
			points(flowset[[i]]@exprs[,"FSC-HLin"],corrected1, col="red",cex=0.5)
			plot(density(flowset[[i]]@exprs[,"RED2-HLog"]))
			lines(density(log10(corrected1), na.rm="T"),col="red")
			corrected2<-corrected1
			corrected2[which(corrected2<=0)]<- 1e-10
		data[i,]<-c(flowset[[i]]@description$`$WELLID`,
					mean(flowset[[i]]@exprs[,"RED2-HLog"]),
					sd(flowset[[i]]@exprs[,"RED2-HLog"]),
					mean(log10(corrected1),na.rm=T),
					sd(log10(corrected1),na.rm=T),
					mean(log10(corrected2),na.rm=T),
					sd(log10(corrected2),na.rm=T))
		}
		else data[i,]<-c(flowset[[i]]@description$`$WELLID`,
					mean(flowset[[i]]@exprs[,"RED2-HLog"]),
					sd(flowset[[i]]@exprs[,"RED2-HLog"]),
					NA,
					NA,
					NA,
					NA)
	}
	return(data.frame(data))
	
}

get.fluo <- function(fluo, scale="")
# TODO: make this better!
{
	if (is.na(fluo)) return(c())
	fluo<-unlist(strsplit(fluo, "/"))
	for (f in fluo)
		if (!(f %in% fluo.type)) fluo.type<<-append(fluo.type, f)
	if (scale %in% c("Lin", "Log"))
		for (i in 1:length(fluo)) {
			if (fluo[i] == "GRN") fluo[i]<-paste(fluo[i],"-H",scale,sep="")
			else if	(fluo[i] == "RED") fluo[i]<-paste(fluo[i],"2-H",scale,sep="")
			else return(-1) }
	return(fluo)
}

### CLEANING AND GATING

## WRAPPER

clean<-function(flowset, mapping=FALSE, fluo=FALSE, cluster=TRUE, scale="Log", verbose=TRUE)
{
	#out.message<-file("sink_out.txt", open="wt")
	#sink(out.message, type="message")
	if (verbose) cat("Fluorescence channels:", paste(fluo),"\n")
	if (verbose) cat("Cleaning... \n")
	flowset <-clean.flowSet(flowset, mapping, fluo, scale)
	if (verbose) cat("Gating... \n")
	filter  <-ellipseGateFilter(flowset)
	flowset <-Subset(flowset, filter)
	if (cluster & (is.list(mapping) | fluo!=FALSE))
	{
		clust <- clustGating(flowset,mapping,fluo)
		#sink(type="message")
		#close(out.message)
		return(clust[[1]])
	}
	#sink(type="message")
	#close(out.message)
	return(flowset)
}

## CLEANING

clean.flowSet<-function(flowset, mapping=FALSE, fluo=FALSE, scale="Log")
{	
	## Clean all the mess
	well<-vector("character", length(flowset))
	desc<-vector("character", length(flowset))
	keep<-rep(TRUE, length(flowset))
	for (i in 1:length(flowset))
	{
		channels <- c()
		# Check Mapping and fluo channels
		if (is.list(mapping)) {
      		if (flowset[[i]]@description$`$WELLID` %in% row.names(mapping)) {
				desc[i] <- mapping[flowset[[i]]@description$`$WELLID`,"description"]
				channels <- get.fluo(mapping[flowset[[i]]@description$`$WELLID`,"fluo"], scale) }
			else keep[i] <- FALSE 
		}
    	if (fluo!=FALSE) channels <-get.fluo(fluo, scale)
		well[i] <- flowset[[i]]@description$`$WELLID`
		# clean linear values
		if ("GRN-HLog" %in% channels & "RED2-HLog" %in% channels)
			flowset[[i]] <-flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0 & flowset[[i]]@exprs[,"GRN-HLin"]>0 & flowset[[i]]@exprs[,"RED2-HLin"]>0]
		else if ("GRN-HLog" %in% channels)
			flowset[[i]] <-flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0 & flowset[[i]]@exprs[,"GRN-HLin"]>0]
		else if ("RED2-HLog" %in% channels)
			flowset[[i]] <-flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0 & flowset[[i]]@exprs[,"RED2-HLin"]>0]
		else
			flowset[[i]] <-flowset[[i]][flowset[[i]]@exprs[,"FSC-HLin"]>0 & flowset[[i]]@exprs[,"SSC-HLin"]>0]
		# correct for log transform
		flowset[[i]]@exprs[,"GRN-HLin"]<-flowset[[i]]@exprs[,"GRN-HLin"]+1
		flowset[[i]]@exprs[,"RED2-HLin"]<-flowset[[i]]@exprs[,"RED2-HLin"]+1
		# recalculate logs
		flowset[[i]]@exprs[,"FSC-HLog"] <-log10(flowset[[i]]@exprs[,"FSC-HLin"])
		flowset[[i]]@exprs[,"SSC-HLog"] <-log10(flowset[[i]]@exprs[,"SSC-HLin"])
		#if ("GRN-HLog" %in% channels)
			flowset[[i]]@exprs[,"GRN-HLog"] <-log10(flowset[[i]]@exprs[,"GRN-HLin"])
		#if ("RED2-HLog" %in% channels)
			flowset[[i]]@exprs[,"RED2-HLog"] <-log10(flowset[[i]]@exprs[,"RED2-HLin"])
	}
	# Name samples by well
	sampleNames(flowset) <- well
	# Add new descriptions
	keyword(flowset) <- list(description=desc)
	keyword(flowset) <- list(status="Not set")
	keyword(flowset) <- list("GRN-HLog.sw.p.value"=NA)
	keyword(flowset) <- list("RED2-HLog.sw.p.value"=NA)
	keyword(flowset) <- list(cluster=NA)
	keyword(flowset) <- list(cluster.100=NA)
	keyword(flowset) <- list(cell.nbr=NA)
	# Change descriptions messing with I/O
	keyword(flowset) <- list("GTI$USERNAME"="GUAVAHTGTI")
	# Remove unmapped samples
	flowset <- flowset[keep]
	# Re-order
	flowset <- flowset[order(sampleNames(flowset)),]
	return(flowset)
}

nameByWell<-function(flowset)
{
	id <-c()
	for (i in 1:length(flowset))
	{
		
		id <- append(id, flowset[[i]]@description$`$WELLID`)
	}
	sampleNames(flowset) <- id
	flowset <-flowset[order(sampleNames(flowset)),]
	return(flowset)
}


getMapping<-function(mapping)
{
	mapping<-read.csv(mapping, row.names=1, na.string="",stringsAsFactors=FALSE)
	names(mapping) <- tolower(names(mapping))
	# Make sure well name and fluo are correctly formated
	wells<-row.names(mapping)
	empty<-rep(TRUE, nrow(mapping))
	for (i in 1:nrow(mapping))
	{
		if (nchar(wells[i]) < 3) wells[i]<-toString(paste(substr(wells[i],1,1), 0 ,substr(wells[i],2,2), sep=''))
		if (!is.na(mapping[i,"status"]) & (mapping[i,"status"]!="NA") & (mapping[i,"status"]!=0)) empty[i]<-FALSE
	}
	row.names(mapping)<-wells
	# remove empty wells
	if (length(empty)>0) mapping<-mapping[!empty,]
	# return modified mapping dataframe)
	return(mapping)
}


## GATING

ellipseGateFilter<-function(flowset)
# Return ellipse gate filter
{
	par = c('FSC-HLog','SSC-HLog')
	#cov = matrix(c(0.10, 0.06, 0.06, 0.12), nrow = 2, ncol=2, byrow=TRUE, dimnames = list(par,par))
	#Using values from the guava fcs metadata: for some reason need to be multiplied by 16!
	cov = matrix(16*cov.matrix(0.1920118678135238, 0.08082951003878829, 36.79291744969011), nrow = 2, ncol=2, byrow=TRUE, dimnames = list(par,par))
	center = c('FSC-HLog'=0.7045165131393946, 'SSC-HLog'= 2.442332442332441)
	cells<-ellipsoidGate(filterId="aquisition", .gate=cov, mean=center, distance=1)
	f<-filter(flowset, cells)
	return(f)
}

rectangularGateFilter<-function(flowset)
# Return rectangular gate filter
{
	# can't understand how to derive the numbers from the guava fcs metadata...
	cells<-rectangleGate(filterId="aquisition", "FSC-HLog"=c(log10(20), log10(200)), "SSC-HLog"=c(log10(20), log10(500)))
	f<-filter(flowset, cells)
	return(f)
}


cov.matrix <- function (a, b, angle)
{
   theta <- angle * (pi/180)
   c1 <- ((cos(theta)^2)/a^2) + ((sin(theta)^2)/b^2)
   c2 <- sin(theta) * cos(theta) * ((1/a^2) - (1/b^2))
   c3 <- ((sin(theta)^2)/a^2) + ((cos(theta)^2)/b^2)
   m1 <- matrix(c(c1, c2, c2, c3), byrow=TRUE, ncol=2)
   m2 <- solve(m1)
   m2
}

clustGating<-function(flowset, mapping=FALSE, fluo=FALSE, scale="Log", cluster_rule = FALSE, levels=c(0.95,0.95), output=FALSE)
# Return a list containing the filtered flowset and a vector containing length of minor pop
{
	if (fluo==FALSE & !is.list(mapping))
		return(list(flowset, NA))
	else if (fluo!=FALSE)
		fluos <- get.fluo(fluo, scale)
	mix<-vector("list", length(flowset))
	noclust<-vector("numeric", length(flowset))
	# graphical parameter
	x.lim <- c(0,4)
	for (i in 1:length(flowset))
	{
		# Refine forward and side scatter gating
		clust.cell   <- flowClust(flowset[[i]], varNames=c("FSC-HLog", "SSC-HLog"), K=1, level=levels[1])
		flowset[[i]] <- Subset(flowset[[i]], clust.cell)
		# Then on the channel, choosing the best of 1 or 2 cluster(s)
		# based on the Integrated Completed Likelihood measure
		# retain the most abundant pop as the good one and status the other
		if (fluo==FALSE)
			fluos <- get.fluo(mapping[i,"fluo"], scale)
		if (length(fluos)!=0 & nrow(flowset[[i]]@exprs)>10){
			clust.fluo <- flowClust(flowset[[i]], varNames=fluos, K=1:2, level=levels[2], criterion="ICL", nu=4, nu.est=0, trans=0, randomStart=25)
			clust.fluo <- refine.selection(clust.fluo)
			noclust[i] <- clust.fluo[[clust.fluo@index]]@K
			#print(flowset[[i]]@description$description)
			#for (j in 1:2)
			#{
			#	cat("##### ",j, "#####\n")
			#	print(summary(clust.fluo[[j]]))
			#}
			if (noclust[i] == 1)
			{
	# 			if (output!=FALSE)
	# 			{
	# 				png(file.path(output[1],paste(flowset[[i]]@description$`$WELLID`,"_",output[2],"_1_cluster.png",sep="")))
	# 				hist(clust.fluo[[clust.fluo@index]],flowset[[i]], main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n",output[2],sep=""),xlim=c(0,4))
	# 				dev.off()
	# 			}
				flowset[[i]]<-Subset(flowset[[i]], clust.fluo)
				if (nrow(flowset[[i]]>2))
					flowset[[i]]@description$"sw.p.value"<-shapiro.test(flowset[[i]]@exprs[,fluos[1]])$p.value
				if (output!=FALSE)
				{
					png(file.path(output[1],paste(flowset[[i]]@description$description, "_",flowset[[i]]@description$`$WELLID`,"_",output[2],"_2_processed.png",sep="")))
					# Draw histogram, density plot and normal fit
					breaks<-nrow(flowset[[i]])/5
					h<-hist(flowset[[i]]@exprs[,fluos[1]],breaks=breaks, plot=FALSE)
					mean<-mean(flowset[[i]]@exprs[,fluos[1]])
					sd<-sd(flowset[[i]]@exprs[,fluos[1]])
					xfit <- seq(x.lim[1],x.lim[2],length=100)
					yfit <- dnorm(xfit,mean=mean,sd=sd)
					yfit <- yfit*diff(h$mids[1:2])*length(flowset[[i]]@exprs[,fluos[1]]) 
					h<-hist(flowset[[i]]@exprs[,fluos[1]], breaks=breaks, border=FALSE, col="#FF000050", main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n ",output[2],sep=""),xlim=c(0,4), ylim=c(-0.5, max(c(yfit,h$counts))), xlab=fluos[1])
					d<-density(flowset[[i]]@exprs[,fluos[1]])
					d$y<-d$y*h$counts[1]/h$density[1]
					polygon(d$x,d$y, col="#FF000050", border="#FF0000", lty=3)
					lines(xfit, yfit, col="#FF0000", lwd=2, lty=1)
					# add gaussian info
					segments(mean,0,mean,max(yfit),col="#FF0000",lty=2)
					arrows(mean-sd,0,mean+sd,0,col="#FF0000",angle=10,length=0.1,lwd=1,code=3)
					text(mean, -0.5, paste(formatC(mean,format="f",digits=2), "±",formatC(sd,format="f",digits=2)), cex=0.75)
					# add legend with counts and shapiro-wilk test for normality
					legend("topright", c(paste("n=", nrow(flowset[[i]])), paste("p=",formatC(flowset[[i]]@description$"sw.p.value", format="e"))),
										 text.col=c("#000000"), bty="n")
					dev.off()
				}
			}
			else if (noclust[i] == 2)
			{
	# 			if (output!=FALSE)
	# 			{
	# 				png(file.path(output[1],paste(flowset[[i]]@description$description, "_",flowset[[i]]@description$`$WELLID`,"_",output[2],"_1_cluster.png",sep="")))
	# 				hist(clust.fluo[[clust.fluo@index]],flowset[[i]], main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n",output[2],sep=""),xlim=c(0,4))
	# 				dev.off()
	# 			}
				subpop<-split(flowset[[i]], clust.fluo)
				#sorted<-sort(matrix(c(nrow(subpop[[1]]),nrow(subpop[[2]]))), index.return=TRUE, decreasing=TRUE)
				sorted<-sort(matrix(c(mean(subpop[[1]]@exprs[,fluos[1]], na.rm=TRUE),mean(subpop[[2]]@exprs[,fluos[1]], na.rm=TRUE))), index.return=TRUE, decreasing=TRUE)
				if (output!=FALSE)
				{
					## Draw histogram, density plot and normal curve
					# for biggest cluster (red)
					nbreaks<-nrow(flowset[[i]])/5
					h<-hist(flowset[[i]]@exprs[,fluos[1]], breaks=nbreaks, plot=FALSE)
					disth<-h$breaks[2]-h$breaks[1]
					hmatrix=cbind(h$breaks,h$counts,h$density,h$mids)
					adjust <- mean(hmatrix[,2]/hmatrix[,3], na.rm=TRUE)
					d<-density(flowset[[i]]@exprs[,fluos[1]])
					distd<-d$x[2]-d$x[1]
					dmatrix<-cbind(d$x,d$y)
					ymax   <- 0
					colors <- c("#FF0000", "#56A5EC")
					subh   <- vector("list", length=2)
					subdmatrix <- vector("list", length=2)
					mean <- vector("list", length=2)
					sd <- vector("list", length=2)
					xfit <- vector("list", length=2)
					yfit <- vector("list", length=2)
					png(file.path(output[1],paste(flowset[[i]]@description$description, "_",flowset[[i]]@description$`$WELLID`,"_",output[2],"_2_processed.png",sep="")))
					for (rank in sorted$ix) {
						r <- range(subpop[[rank]]@exprs[,fluos[1]])
						subhmatrix  <- hmatrix[(hmatrix[,1]>(r[1]-disth) & hmatrix[,1]<r[2]+disth),]
						subh[[rank]] <- h
						subh[[rank]]$breaks <- subhmatrix[,1]
						subh[[rank]]$counts <- subhmatrix[,2][-nrow(subhmatrix)]
						subdmatrix[[rank]]  <- dmatrix[(dmatrix[,1]>(r[1]-distd) & dmatrix[,1]<r[2]+distd),]
						mean[[rank]] <- mean(subpop[[rank]]@exprs[,fluos[1]])
						sd[[rank]]   <- sd(subpop[[rank]]@exprs[,fluos[1]])
						xfit[[rank]] <- seq(x.lim[1],x.lim[2],length=100)
						yfit[[rank]] <- dnorm(xfit[[rank]],mean=mean[[rank]],sd=sd[[rank]])
						yfit[[rank]] <- yfit[[rank]]*diff(subhmatrix[,4][1:2])*length(subpop[[rank]]@exprs[,fluos[1]])
						ymax <- max(c(yfit[[rank]], subhmatrix[,2], ymax))
					}
					add    <- FALSE
					index  <- 1
					for (rank in sorted$ix) {
						plot(subh[[rank]], main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n ",output[2],sep=""), xlab=fluos[1], ylab="Counts", 						     border=FALSE, col=paste(colors[index],"50",sep=""), xlim=c(0,4), ylim=c(-0.5,ymax), add=add)
						polygon(c(subdmatrix[[rank]][1,1], subdmatrix[[rank]][,1], subdmatrix[[rank]][nrow(subdmatrix[[rank]]),1]),
						        c(0, (subdmatrix[[rank]][,2]*adjust), 0), col=paste(colors[index],"50",sep=""), border=colors[index], lty=3)
						lines(xfit[[rank]], yfit[[rank]], col=colors[index], lwd=3, lty=1)
						add   <- TRUE
						index <- index+1
					}
					# add gaussian info
					index <- 1
					for (rank in sorted$ix) {
						segments(mean[[rank]],0,mean[[rank]],max(yfit[[rank]]),col=colors[index],lty=2)
						arrows(mean[[rank]]-sd[[rank]],0,mean[[rank]]+sd[[rank]],0,col=colors[index],angle=10,length=0.1,lwd=1,code=3)
						text(mean[[rank]], -0.5, paste(formatC(mean[[rank]],format="f",digits=2), "±",formatC(sd[[rank]],format="f",digits=2)), cex=0.75)
						index  <- index+1
					}
					flowset[[i]]<-subpop[[sorted$ix[1]]] #max retained in analysis
					mix[[i]]    <-subpop[[sorted$ix[2]]]
					if (nrow(flowset[[i]])>2)
						flowset[[i]]@description$"sw.p.value"<-shapiro.test(flowset[[i]]@exprs[,fluos[1]])$p.value
					if (nrow(mix[[i]])>2)
						mix[[i]]@description$"sw.p.value"<-shapiro.test(mix[[i]]@exprs[,fluos[1]])$p.value
					# add legend with counts and shapiro-wilk test for normality
					width=max(length(toString(nrow(subpop[[1]]))),length(toString(nrow(subpop[[2]]))))
					legend("topright", c(paste("n=", formatC(nrow(flowset[[i]]),width=width), "; p=",formatC(flowset[[i]]@description$"sw.p.value", format="e"),"\nFSC1=", formatC(mean(flowset[[i]]@exprs[,"FSC-HLog"]),width=width),"\n"),
										 paste("n=", formatC(nrow(mix[[i]]),width=width), "; p=", formatC(mix[[i]]@description$"sw.p.value", format="e"), "\nFSC2=", formatC(mean(mix[[i]]@exprs[,"FSC-HLog"]),width=width))),
										 text.col=c("#FF0000","#000000"), bty="n")
					dev.off()
	# 				p1<-xyplot(`SSC-HLog`~`FSC-HLog`, flowset[[i]],
	# 					    	xlim=c(0,1.2),ylim=c(2,2.8),smooth=FALSE, cex=2,col="red", 
	# 							main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n",output[2],sep=""))
	# 				p2<-xyplot(`SSC-HLog`~`FSC-HLog`,mix[[i]],
	# 							xlim=c(0,1.2),ylim=c(2,2.8), smooth=FALSE, cex=2,col="gray",
	# 							main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n",output[2],sep=""))
	# 				png(file.path(output[1],paste(flowset[[i]]@description$description, "_",flowset[[i]]@description$`$WELLID`,"_",output[2],"_scatter.png",sep="")))
	# 				plot(p1)
	# 				plot(p2,newpage=FALSE)
	# 				dev.off()
				}
			}
		}
	}
	mix<-mix[lapply(mix, is.null)==FALSE]
	if (length(mix)!=0) {
		clust.data <- list(cluster1= nameByWell(flowset), cluster2=nameByWell(flowSet(mix[lapply(mix,class)=="flowFrame"])))
		nclust<-list(cluster1= noclust, cluster2=rep(2, length(mix))) }
	else {
		clust.data <- list(cluster1=flowset, cluster2=NULL)
		nclust<-list(cluster1= noclust, NULL) }
	# update descriptions
	for (i in 1:length(clust.data)) {
		if (!is.null(clust.data[[i]]))
			for (j in 1:length(clust.data[[i]])) {
				clust.data[[i]][[j]]@description$cell.nbr<-nrow(clust.data[[i]][[j]])
				clust.data[[i]][[j]]@description$cluster<-nclust[[i]][[j]]
				if (is.list(mapping)) fluos<-get.fluo(mapping[identifier(clust.data[[i]][[j]]),"fluo"], scale)
				print(identifier(clust.data[[i]][[j]]))
				print(mapping[identifier(clust.data[[i]][[j]]),"fluo"])
				print(fluos)
				for (fluo in fluos) {
					if (nrow(clust.data[[i]][[j]])>2) {
							clust.data[[i]][[j]]@description[paste(fluo,".sw.p.value",sep="")]<-shapiro.test(clust.data[[i]][[j]]@exprs[,fluo])$p.value
						if (clust.data[[i]][[j]]@description[paste(fluo,".sw.p.value",sep="")] <1e-10) {
        	    			if (clust.data[[i]][[j]]@description$status != "Not set")
								clust.data[[i]][[j]]@description$status<-paste(clust.data[[i]][[j]]@description$status, paste("Non-Normal",fluo,"distribution"), sep=" / ")
					   		else
              					clust.data[[i]][[j]]@description$status<-paste("Non-Normal",fluo,"distribution")
              			}
              		}
        		}
				if (clust.data[[i]][[j]]@description$cell.nbr <=1000) {
          			if (clust.data[[i]][[j]]@description$status != "Not set")
						clust.data[[i]][[j]]@description$status<-paste(clust.data[[i]][[j]]@description$status, "Low cell number", sep=" / ")
			    	else
            			clust.data[[i]][[j]]@description$status<-"Low cell number"
            	}
      }
	}
	return(clust.data)
}

# In-house ad-hoc selection criterion for clustering
refine.selection<-function(flowclustlist, verbose=FALSE)
{
	if (flowclustlist[[flowclustlist@index]]@ICL <= 0)
	{
		# ICL have preceedence
		if (flowclustlist[[2]]@ICL/flowclustlist[[1]]@ICL<1) {
			flowclustlist@index <- 2
			if (verbose) cat("Negative likelihood but favorable ICL", flowclustlist[[2]]@ICL/flowclustlist[[1]]@ICL," : keep 2 cluster\n")}
		# likelihood change sign: typical of very close clusters
		#else if (flowclustlist[[2]]@logLike/flowclustlist[[1]]@logLike <0) {
		#	flowclustlist@index <- 2
		#	cat("likelihood switch: keep 2 cluster\n")}
		# 2 or 3 work well
		else if (abs(flowclustlist[[2]]@ICL/flowclustlist[[2]]@BIC)>=2.5) {
			flowclustlist@index <- 1
			if (verbose) cat("Way High ICL/BIC ratio ", abs(flowclustlist[[2]]@ICL/flowclustlist[[2]]@BIC)," : keep 1 cluster\n") }
		else if (flowclustlist[[2]]@BIC/flowclustlist[[1]]@BIC<1) {
			flowclustlist@index <- 2
			if (verbose) cat("BIC based clustering", flowclustlist[[2]]@BIC,"\n")}
	}
	return(flowclustlist)
}


### DATA MANIPULATION

extractData<-function(flowset, mapping=FALSE, fluo=FALSE, scale="Lin", CV.treshold=1, low.rm=FALSE)
# Correct for background and reference as applicable (defined in mapping)
# Somewhat arbitrarily, eliminate measures which are below twice the background on the denominator channel, if applicable
{
	if (class(flowset) != "flowSet") return(NULL)
	
	# Initialization
	names<-c()
	is.bkgd = FALSE
	is.ref  = FALSE
	if (is.list(mapping)) {
		names <-c("description")
		fluo.type <- names(table(unlist(strsplit(mapping$fluo,"/"))))
		if ("background" %in% colnames(mapping)) is.bkgd = TRUE
		if ("reference"  %in% colnames(mapping)) is.ref  = TRUE
	}
	if (fluo)
		fluo.type<-fluo
	names <-c(names, "cluster.nbr", "cell.nbr")
	fluos <- get.fluo(fluo.type, scale)
	fluos.log <- get.fluo(fluo.type, scale="Log")
	for (i in 1:length(fluos)) {
		names <-c(names, paste("mean.",fluos[i],sep=""), paste("sd.",fluos[i],sep=""), paste("pval.",fluos.log[i],sep=""))
		if (is.bkgd) names<-c(names,paste("mean.bkgd.",fluos[i],sep=""))
	}
	TE<-NULL
	if (is.ref) {
		names<-c(names,"ratio.bulk","mean.ratio.cell","sd.ratio.cell", "TE.bulk", "TE.cell")
		TE   <- vector("list", length(flowset))
		names(TE)<-sampleNames(flowset)
	}
	names<-c(names,"status")
	data <- matrix(data=NA, ncol=length(names), nrow=length(flowset), dimnames=list(sampleNames(flowset), names))
	## Initial calculations for background, making sure all samples are in the dataset
	if (is.bkgd) {
		simple_names  <- names(table(unlist(strsplit(mapping$background,"/"))))
		# check wells are in dataset
		check<-simple_names %in% sampleNames(flowset)
		if (!all(check)) {
			cat("These background samples (", paste(simple_names[!check],sep=", "),") are not included in the dataset (",paste(sampleNames(flowset),sep=", "),")\n")
			simple_names<-simple_names[check] }
		formula_names <- c()
		for (name in names(table(mapping$background)))
			if ((!name %in% simple_names) & (all(unlist(strsplit(name,"/")) %in% simple_names)))
				 formula_names<-c(formula_names, name)
		bkgk.names <- c(simple_names, formula_names)
		# mean calculation
		bkgd <- matrix(data=NA, nrow=length(bkgk.names), ncol=length(fluo.type), dimnames=list(bkgk.names, fluos))
		for (sample in simple_names)
			for (f in fluos) 
				bkgd[sample, f]  <- mean(flowset[[sample]]@exprs[, f], na.rm=TRUE)
		for (sample in formula_names)
			for (f in fluos) 
				bkgd[sample, f]  <- mean(bkgd[unlist(strsplit(sample,"/")), f], na.rm=TRUE)
	}
	
	## Initial calculations for references, making sure all samples are in the dataset
	if (is.ref)
	{
		simple_names <-names(table(unlist(strsplit(mapping$reference,"/"))))
		# check reference are in dataset
		check<-simple_names %in% sampleNames(flowset)
		if (!all(check)) {
			cat("These reference samples (", paste(simple_names[!check],sep=", "),") are not included in the dataset (",paste(sampleNames(flowset),sep=", "),")\n")
			simple_names<-simple_names[check] }
		# further checks that corresponding backgrounds are in dataset
		check<- mapping[simple_names,"background"] %in% sampleNames(flowset)
		if (!all(check)) {
			cat("These reference samples (", paste(simple_names[!check],sep=", "),") have no corresponding background in the dataset (",paste(sampleNames(flowset),sep=", "),")\n")
			simple_names<-simple_names[check] }
		formula_names <- c()
		for (name in names(table(unlist(mapping$reference))))
			if ((!name %in% simple_names) & (all(unlist(strsplit(name,"/")) %in% simple_names)))
				formula_names<-c(formula_names, name)
		names <- c(simple_names, formula_names)
		# background-substracted mean calculation
		ref <- matrix(data=NA, nrow=length(names), ncol=2, dimnames=list(names, c("bulk","cell")))
		for (sample in simple_names)
		{
			#remove cells below twice the background on denominator
			if (low.rm)
				flowset[[sample]]<-flowset[[sample]][flowset[[sample]]@exprs[, fluos[2]] >= 2*bkgd[mapping[sample,"background"], fluos[2]]]
			fluos <- get.fluo(unlist(strsplit(mapping[sample,"fluo"], "/")), scale)
			ref[sample,"bulk"] <- ( (mean(flowset[[sample]]@exprs[, fluos[1]]) - bkgd[mapping[sample,"background"], fluos[1]]) 
		 						  / (mean(flowset[[sample]]@exprs[, fluos[2]]) - bkgd[mapping[sample,"background"], fluos[2]]) )
			ref[sample,"cell"] <- ( mean( (flowset[[sample]]@exprs[, fluos[1]] - bkgd[mapping[sample,"background"], fluos[1]]) 
							   	        / (flowset[[sample]]@exprs[, fluos[2]] - bkgd[mapping[sample,"background"], fluos[2]]), na.rm=TRUE) )
		}
		for (sample in formula_names)
			for (type in c("bulk","cell"))
				ref[sample, type] <- mean(ref[unlist(strsplit(sample,"/")), type], na.rm=TRUE)
	}
	
	# Calculations for all samples
	for (well in sampleNames(flowset))
	{
		if (fluo!=FALSE) fluos <- get.fluo(fluo, scale)
		else if (is.list(mapping)) fluos <- get.fluo(mapping[well,"fluo"], scale)
		#remove cells below twice the background on denominator channel
		if (low.rm & is.bkgd & is.ref)
			if ((!well %in% bkgk.names) & (mapping[well,"background"] %in% row.names(bkgd))) {
				flowset[[well]]<-flowset[[well]][flowset[[well]]@exprs[, fluos[2]] >= 2*bkgd[mapping[well,"background"],fluos[2]]]
				flowset[[well]]@description$cell.nbr <- nrow(flowset[[well]])
			}
		if (flowset[[well]]@description$cell.nbr<=0){
			if (flowset[[well]]@description$status!="Not set")
				flowset[[well]]@description$status<-paste(flowset[[well]]@description$status, "No cells", sep=" / ")
	  	    else
         		flowset[[well]]@description$status<-"No cells"
		}
		else {
			for (f in fluos) {
				data[well,paste("mean.", f, sep="")] <- mean(flowset[[well]]@exprs[, f], na.rm=TRUE)
				data[well,paste("sd."  , f, sep="")] <-   sd(flowset[[well]]@exprs[, f], na.rm=TRUE)
				if (data[well,paste("sd.", f, sep="")]/data[well,paste("mean.", f, sep="")]>=CV.treshold){
        			if (flowset[[well]]@description$status!="Not set")
						flowset[[well]]@description$status<-paste(flowset[[well]]@description$status, paste(f, " CV>", CV.treshold, sep=""), sep=" / ")
			  		else
          				flowset[[well]]@description$status<-paste(f, " CV>", CV.treshold, sep="")
          		}
      			if (is.bkgd)
					if (mapping[well,"background"] %in% row.names(bkgd)) {
						data[well,paste("mean.",f,sep="")]
						data[well,paste("mean.bkgd.",f,sep="")] <-data[well,paste("mean.",f,sep="")]-bkgd[mapping[well,"background"],f]
					}
			} 
			if (is.ref){
				if (!(well %in% row.names(bkgd)) & (mapping[well,"background"] %in% row.names(bkgd))){
					data[well,"ratio.bulk"] <- data[well, paste("mean.bkgd.", fluos[1],sep="")] / data[well, paste("mean.bkgd.", fluos[2],sep="")]
					r <- ( (flowset[[well]]@exprs[, fluos[1]] - bkgd[mapping[well,"background"], fluos[1]]) 
			    		 / (flowset[[well]]@exprs[, fluos[2]] - bkgd[mapping[well,"background"], fluos[2]]) )
					data[well, "mean.ratio.cell"] <- mean(r, na.rm=TRUE)
					data[well, "sd.ratio.cell"]   <-   sd(r, na.rm=TRUE)
					if (mapping[well,"reference"] %in% row.names(ref)) {
						data[well,"TE.bulk"] <- 100 * (1 - data[well,"ratio.bulk"] / ref[mapping[well,"reference"],"bulk"])
						data[well,"TE.cell"] <- 100 * (1 - data[well, "mean.ratio.cell"] / ref[mapping[well,"reference"],"cell"]) 
						TE[[well]]<-100 * (1 - r / ref[mapping[well,"reference"],"cell"])
					}
				}
			}
			if (fluo!=FALSE) fluos <- get.fluo(fluo, "Log")
			else if (is.list(mapping)) fluos <- get.fluo(mapping[well,"fluo"], "Log")
			for (f in fluos)
				data[well,paste("pval.",f,sep="")] <-as.numeric(flowset[[well]]@description[[paste(f,".sw.p.value",sep="")]])
		}
	}
	data[,"cell.nbr"]    <- as.numeric(unlist(keyword(flowset,"cell.nbr"), use.names=FALSE))
	data[,"cluster.nbr"] <- as.numeric(unlist(keyword(flowset,"cluster"), use.names=FALSE))
	data<-data.frame(data)
	# add text component last to avoid global coercion problem in matrix
	if ("description" %in% colnames(data))
		data[,"description"] <- unlist(keyword(flowset,"description"), use.names=FALSE)
	data[,"status"] <-unlist(keyword(flowset,"status"), use.names=FALSE)
  	data[,"status"][data[,"status"]=="Not set"]<-"OK"
  	data <- data[order(row.names(data)),]
  	if (!is.null(TE)) names(TE)<-paste(keyword(flowset,"description")," (",sampleNames(flowset),")",sep="")
	return(list(data,TE))
}


combine.replicates<-function(data)
{
	no.combined.stat <- c("cluster.nbr", "cell.nbr", "status")
	single.col       <- length(no.combined.stat)
	if ("description" %in% colnames(data[[1]])) single.col <- single.col +1
	nocoldata<-ncol(data[[1]])
  	nocol<-3*(nocoldata-single.col)+ single.col
	norow<-nrow(data[[1]])
	norep<-length(data)
	combi<-data.frame(matrix(data=0, ncol=nocol,nrow=norow))
	names<-colnames(data[[1]])[1:(single.col-1)]
  for (name in colnames(data[[1]])[-c(1:(single.col-1),nocoldata)])
  	names<-c(names,paste(c("mean.", "sd.", "cv."), name, sep=""))
  names<-c(names, colnames(data[[1]])[nocoldata])
  colnames(combi)<-names
  rownames(combi)<-rownames(data[[1]])
  for (i in 1:norow) {
		index<-1
		for (name in colnames(data[[1]])) {
			if (name == "description") {
			  combi[i, index] <- data[[1]][i,name]
        index<-index+1
      }
      else {
				nbr<-vector(length=norep)
				for (k in 1:(norep))
					nbr[k]<-data[[k]][i,name]
				if (name %in% no.combined.stat) {
					t<-table(nbr)
					if (length(t) == 1) combi[i, index] <- dimnames(t)[[1]]
					else combi[i, index] <- paste(nbr, collapse="/")
          index <- index+1
				}	
				else {
					combi[i,index]<-mean(nbr)
					combi[i,(index+1)]<-sd(nbr)
					combi[i,(index+2)]<-100*combi[i,index+1]/combi[i,(index)]
					index<-index+3
				}
			}
		}
	}
	return(combi)
}

### OUTPUT

write2xls<-function(workbook.path, data, overwrite=TRUE, verbose=FALSE)
{
	if (!length(data)) return(-1)
	# First write
	for (i in 1:length(data)) {
		append<-TRUE
		if (i == 1 & overwrite==TRUE) append<-FALSE
		write.xlsx(data[[i]], workbook.path, sheetName=names(data)[i], append=append) }
	# Then modify formatting
	wb <- loadWorkbook(workbook.path)
	#highlight<-createCellStyle(wb, fillPattern="LESS_DOTS1")
	ifont<-createCellStyle(wb, font=createFont(wb, isItalic=TRUE))
	bfont<-createCellStyle(wb, font=createFont(wb, isBold=TRUE))
	for (sheet in getSheets(wb))
		for (row in getRows(sheet)) {
			cells<- getCells(list(row), simplify=TRUE)

			if (getCellValue(cells[[length(cells)]])!="OK")
				for (cell in cells)
					setCellStyle(cell, ifont)
			else
				for (cell in cells)
					setCellStyle(cell, bfont)
		}
	saveWorkbook(wb, workbook.path)
	if (verbose) cat("Data saved to :", workbook.path,"\n")
	return(1)
}

multi.ecdf<-function(list,start=0,stop=100)
{
	list<-list[!unlist(lapply(list,is.null))]
	def.par <- par(no.readonly = TRUE)
	layout(matrix(c(2,1,1,1,1,1), nrow=6))
	par("mar" = c(5,5,0,1))
	add=FALSE
	colors=rainbow(length(list),end=0.9)
	for (i in 1:length(list)){
		plot(ecdf(list[[i]]), xlim=c(start,stop),xlab="Termination Efficiency (%)", ylab="Cumulative density", main="", add=add, col=colors[i], lwd=1, do.points=FALSE, verticals=TRUE)
		add= TRUE
	}
	par("mar" = c(1,5,0,0))
	plot.new()	
	legend("topleft", names(list), fill=colors, box.lty=line.type[1:length(list)], box.lwd=rep(5,length(list)), ncol=floor(length(list)/7),bty="n", text.width=0.15)
	par(def.par)
}