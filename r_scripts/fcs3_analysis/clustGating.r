
# Return a list containing the filtered flowset and a vector containing length of minor pop

clustGating = function(flowset, 
                       mapping=FALSE,
                       fluo="", 
                       scale="Log", 
                       cluster_rule = FALSE, 
                       levels=c(0.95,0.95), 
                       output=FALSE) {

	if (fluo=="" & !is.list(mapping)) {
		return(list(flowset, NA))
	} else if (fluo!="") {
		fluos = get.fluo(fluo, scale)
  }

	mix=vector("list", length(flowset))
	noclust=vector("numeric", length(flowset))
	# graphical parameter
	x.lim = c(0,4)
	for (i in 1:length(flowset))
	{

		# Refine forward and side scatter gating
		clust.cell   = flowClust(flowset[[i]], varNames=c("FSC-HLog", "SSC-HLog"), K=1, level=levels[1])


    # TODO check if _any_ clusters were found, 
    #      and somewhere before this function, make sure 
    #      ensure that the flowset actually has measurements 
    #     (length(flowset) >0) and (flowset[[i]$exprs > 10) for each.

		flowset[[i]] = Subset(flowset[[i]], clust.cell)

		# Then on the channel, choosing the best of 1 or 2 cluster(s)
		# based on the Integrated Completed Likelihood measure
		# retain the most abundant pop as the good one and status the other

		if (fluo=="") {
			fluos = get.fluo(mapping[i,"fluo"], scale)
    }

    # Check if there are more than 10 measurements left after gating for forward and side scatter
		if(length(fluos)!=0 & nrow(flowset[[i]]@exprs)>10) {

			clust.fluo = flowClust(flowset[[i]], varNames=fluos, K=1:2, level=levels[2], criterion="ICL", nu=4, nu.est=0, trans=0, randomStart=25)
			clust.fluo = refine.selection(clust.fluo)
			noclust[i] = clust.fluo[[clust.fluo@index]]@K


      cat("Length of exprs: ", length(flowset[[i]]@exprs), "\n")

			if (noclust[i] == 1)
			{

				flowset[[i]]=Subset(flowset[[i]], clust.fluo)
				if (nrow(flowset[[i]]>2))
					flowset[[i]]@description$"sw.p.value"=shapiro.test(flowset[[i]]@exprs[,fluos[1]])$p.value
				if (output!=FALSE)
				{
					png(file.path(output[1],paste(flowset[[i]]@description$description, "_",flowset[[i]]@description$`$WELLID`,"_",output[2],"_2_processed.png",sep="")))

					# Draw histogram, density plot and normal fit
					breaks=nrow(flowset[[i]])/5
					h=hist(flowset[[i]]@exprs[,fluos[1]],breaks=breaks, plot=FALSE)
					mean=mean(flowset[[i]]@exprs[,fluos[1]])
					sd=sd(flowset[[i]]@exprs[,fluos[1]])
					xfit = seq(x.lim[1],x.lim[2],length=100)
					yfit = dnorm(xfit,mean=mean,sd=sd)
					yfit = yfit*diff(h$mids[1:2])*length(flowset[[i]]@exprs[,fluos[1]]) 
          cat("=== ylim: ", max(c(yfit,h$counts)), "\n")
          cat("=== h$counts: ", h$counts, "\n")
          cat("=== yfit: ", yfit, "\n")

					h=hist(flowset[[i]]@exprs[,fluos[1]], breaks=breaks, border=FALSE, col="#FF000050", main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n ",output[2],sep=""),xlim=c(0,4), ylim=c(-0.5, max(c(yfit,h$counts))), xlab=fluos[1])
					d=density(flowset[[i]]@exprs[,fluos[1]])
					d$y=d$y*h$counts[1]/h$density[1]
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
				subpop=split(flowset[[i]], clust.fluo)
				#sorted=sort(matrix(c(nrow(subpop[[1]]),nrow(subpop[[2]]))), index.return=TRUE, decreasing=TRUE)
				sorted=sort(matrix(c(mean(subpop[[1]]@exprs[,fluos[1]], na.rm=TRUE),mean(subpop[[2]]@exprs[,fluos[1]], na.rm=TRUE))), index.return=TRUE, decreasing=TRUE)
				if (output!=FALSE)
				{
					## Draw histogram, density plot and normal curve
					# for biggest cluster (red)
					nbreaks=nrow(flowset[[i]])/5
					h=hist(flowset[[i]]@exprs[,fluos[1]], breaks=nbreaks, plot=FALSE)
					disth=h$breaks[2]-h$breaks[1]
					hmatrix=cbind(h$breaks,h$counts,h$density,h$mids)
					adjust = mean(hmatrix[,2]/hmatrix[,3], na.rm=TRUE)
					d=density(flowset[[i]]@exprs[,fluos[1]])
					distd=d$x[2]-d$x[1]
					dmatrix=cbind(d$x,d$y)
					ymax   = 0
					colors = c("#FF0000", "#56A5EC")
					subh   = vector("list", length=2)
					subdmatrix = vector("list", length=2)
					mean = vector("list", length=2)
					sd = vector("list", length=2)
					xfit = vector("list", length=2)
					yfit = vector("list", length=2)
					png(file.path(output[1],paste(flowset[[i]]@description$description, "_",flowset[[i]]@description$`$WELLID`,"_",output[2],"_2_processed.png",sep="")))

					for (rank in sorted$ix) {
						r = range(subpop[[rank]]@exprs[,fluos[1]])
						subhmatrix  = hmatrix[(hmatrix[,1]>(r[1]-disth) & hmatrix[,1]<r[2]+disth),]
						subh[[rank]] = h
						subh[[rank]]$breaks = subhmatrix[,1]
						subh[[rank]]$counts = subhmatrix[,2][-nrow(subhmatrix)]
						subdmatrix[[rank]]  = dmatrix[(dmatrix[,1]>(r[1]-distd) & dmatrix[,1]<r[2]+distd),]
						mean[[rank]] = mean(subpop[[rank]]@exprs[,fluos[1]])
						sd[[rank]]   = sd(subpop[[rank]]@exprs[,fluos[1]])
						xfit[[rank]] = seq(x.lim[1],x.lim[2],length=100)
						yfit[[rank]] = dnorm(xfit[[rank]],mean=mean[[rank]],sd=sd[[rank]])
            cat("yfit[[rank]] dnorm: ", yfit[[rank]], "\n")
						yfit[[rank]] = yfit[[rank]]*diff(subhmatrix[,4][1:2])*length(subpop[[rank]]@exprs[,fluos[1]])
            cat("yfit[[rank]] diff: ", yfit[[rank]], "\n")
						ymax = max(c(yfit[[rank]], subhmatrix[,2], ymax))
            cat("yfit[[rank]]: ", yfit[[rank]], "\n")
            cat("subhmatrix[,2]: ", subhmatrix[,2], "\n")
            cat("ymax: ", ymax, "\n")
            cat("---------Running for rank--------\n")
					}

					add    = FALSE
					index  = 1
					for (rank in sorted$ix) {

            cat("==== ymax: ", ymax, "\n")

						plot(subh[[rank]], main=paste(flowset[[i]]@description$description," (",flowset[[i]]@description$`$WELLID`,")\n ",output[2],sep=""), xlab=fluos[1], ylab="Counts", 						     border=FALSE, col=paste(colors[index],"50",sep=""), xlim=c(0,4), ylim=c(-0.5,ymax), add=add)
						polygon(c(subdmatrix[[rank]][1,1], subdmatrix[[rank]][,1], subdmatrix[[rank]][nrow(subdmatrix[[rank]]),1]),
						        c(0, (subdmatrix[[rank]][,2]*adjust), 0), col=paste(colors[index],"50",sep=""), border=colors[index], lty=3)
						lines(xfit[[rank]], yfit[[rank]], col=colors[index], lwd=3, lty=1)
						add   = TRUE
						index = index+1
					}
					# add gaussian info
					index = 1
					for (rank in sorted$ix) {
						segments(mean[[rank]],0,mean[[rank]],max(yfit[[rank]]),col=colors[index],lty=2)
						arrows(mean[[rank]]-sd[[rank]],0,mean[[rank]]+sd[[rank]],0,col=colors[index],angle=10,length=0.1,lwd=1,code=3)
						text(mean[[rank]], -0.5, paste(formatC(mean[[rank]],format="f",digits=2), "±",formatC(sd[[rank]],format="f",digits=2)), cex=0.75)
						index  = index+1
					}
					flowset[[i]]=subpop[[sorted$ix[1]]] #max retained in analysis
					mix[[i]]    =subpop[[sorted$ix[2]]]
					if (nrow(flowset[[i]])>2)
						flowset[[i]]@description$"sw.p.value"=shapiro.test(flowset[[i]]@exprs[,fluos[1]])$p.value
					if (nrow(mix[[i]])>2)
						mix[[i]]@description$"sw.p.value"=shapiro.test(mix[[i]]@exprs[,fluos[1]])$p.value
					# add legend with counts and shapiro-wilk test for normality
					width=max(length(toString(nrow(subpop[[1]]))),length(toString(nrow(subpop[[2]]))))
					legend("topright", c(paste("n=", formatC(nrow(flowset[[i]]),width=width), "; p=",formatC(flowset[[i]]@description$"sw.p.value", format="e"),"\nFSC1=", formatC(mean(flowset[[i]]@exprs[,"FSC-HLog"]),width=width),"\n"),
										 paste("n=", formatC(nrow(mix[[i]]),width=width), "; p=", formatC(mix[[i]]@description$"sw.p.value", format="e"), "\nFSC2=", formatC(mean(mix[[i]]@exprs[,"FSC-HLog"]),width=width))),
										 text.col=c("#FF0000","#000000"), bty="n")
					dev.off()

				}
			}
		}
	}
	mix=mix[lapply(mix, is.null)==FALSE]
	if (length(mix)!=0) {
		clust.data = list(cluster1= nameByWell(flowset), cluster2=nameByWell(flowSet(mix[lapply(mix,class)=="flowFrame"])))
		nclust=list(cluster1= noclust, cluster2=rep(2, length(mix))) }
	else {
		clust.data = list(cluster1=flowset, cluster2=NULL)
		nclust=list(cluster1= noclust, NULL) }
	# update descriptions
	for (i in 1:length(clust.data)) {
		if (!is.null(clust.data[[i]]))
			for (j in 1:length(clust.data[[i]])) {
				clust.data[[i]][[j]]@description$cell.nbr=nrow(clust.data[[i]][[j]])
				clust.data[[i]][[j]]@description$cluster=nclust[[i]][[j]]
				if (is.list(mapping)) fluos=get.fluo(mapping[identifier(clust.data[[i]][[j]]),"fluo"], scale)
			  print(identifier(clust.data[[i]][[j]]))
#       print(mapping[identifier(clust.data[[i]][[j]]),"fluo"])
				print(fluos)
				for (fluo in fluos) {
					if (nrow(clust.data[[i]][[j]])>2) {
							clust.data[[i]][[j]]@description[paste(fluo,".sw.p.value",sep="")]=shapiro.test(clust.data[[i]][[j]]@exprs[,fluo])$p.value
						if (clust.data[[i]][[j]]@description[paste(fluo,".sw.p.value",sep="")] <1e-10) {
        	    			if (clust.data[[i]][[j]]@description$status != "Not set")
								clust.data[[i]][[j]]@description$status=paste(clust.data[[i]][[j]]@description$status, paste("Non-Normal",fluo,"distribution"), sep=" / ")
					   		else
              					clust.data[[i]][[j]]@description$status=paste("Non-Normal",fluo,"distribution")
              			}
              		}
        		}
				if (clust.data[[i]][[j]]@description$cell.nbr <=1000) {
          			if (clust.data[[i]][[j]]@description$status != "Not set")
						clust.data[[i]][[j]]@description$status=paste(clust.data[[i]][[j]]@description$status, "Low cell number", sep=" / ")
			    	else
            			clust.data[[i]][[j]]@description$status="Low cell number"
            	}
      }
	}
	return(clust.data)
}
