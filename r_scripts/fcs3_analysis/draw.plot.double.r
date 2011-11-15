

draw.plot.double = function(flowframe, subpop, fluo, out.path.plot) {

  # graphical parameter
  x.lim = c(0,4)

  png(file.path(out.path.plot))

  sorted = sort(matrix(c(mean(subpop[[1]]@exprs[,fluo], na.rm=TRUE),mean(subpop[[2]]@exprs[,fluo], na.rm=TRUE))), index.return=TRUE, decreasing=TRUE)

  # Draw histogram, density plot and normal curve
  # for biggest cluster (red)

  nbreaks = nrow(flowframe)/5
  h = hist(flowframe@exprs[,fluo], breaks=nbreaks, plot=FALSE)

  disth = h$breaks[2]-h$breaks[1]
  hmatrix = cbind(h$breaks,h$counts,h$density,h$mids)

  adjust = mean(hmatrix[,2]/hmatrix[,3], na.rm=TRUE)
  d = density(flowframe@exprs[,fluo])
  distd = d$x[2]-d$x[1]
  dmatrix = cbind(d$x,d$y)
  ymax = 0
  colors = c("#FF0000", "#56A5EC")
  subh = vector("list", length=2)

  subdmatrix = vector("list", length=2)
  mean = vector("list", length=2)
  sd = vector("list", length=2)
  xfit = vector("list", length=2)
  yfit = vector("list", length=2)

  for (rank in sorted$ix) {

    r = range(subpop[[rank]]@exprs[,fluo])
    subhmatrix  = hmatrix[(hmatrix[,1]>(r[1]-disth) & hmatrix[,1]<r[2]+disth),]
    subh[[rank]] = h
    subh[[rank]]$breaks = subhmatrix[,1]
    subh[[rank]]$counts = subhmatrix[,2][-nrow(subhmatrix)]
    subdmatrix[[rank]]  = dmatrix[(dmatrix[,1]>(r[1]-distd) & dmatrix[,1]<r[2]+distd),]
    mean[[rank]] = mean(subpop[[rank]]@exprs[,fluo])
    sd[[rank]]   = sd(subpop[[rank]]@exprs[,fluo])
    xfit[[rank]] = seq(x.lim[1],x.lim[2],length=100)
    yfit[[rank]] = dnorm(xfit[[rank]],mean=mean[[rank]],sd=sd[[rank]])
    yfit[[rank]] = yfit[[rank]]*diff(subhmatrix[,4][1:2])*length(subpop[[rank]]@exprs[,fluo])

    ymax = max(c(yfit[[rank]], subhmatrix[,2], ymax))

  }

  add = FALSE
  index = 1
  for (rank in sorted$ix) {

    plot(subh[[rank]], main=paste(flowframe@description$description," (",flowframe@description$`$WELLID`,")\n ",sep=""), xlab=fluo, ylab="Counts",                  border=FALSE, col=paste(colors[index],"50",sep=""), xlim=c(0,4), ylim=c(-0.5,ymax), add=add)
    polygon(c(subdmatrix[[rank]][1,1], subdmatrix[[rank]][,1], subdmatrix[[rank]][nrow(subdmatrix[[rank]]),1]), c(0, (subdmatrix[[rank]][,2]*adjust), 0), col=paste(colors[index],"50",sep=""), border=colors[index], lty=3)
    lines(xfit[[rank]], yfit[[rank]], col=colors[index], lwd=3, lty=1)
    add = TRUE
    index = index+1
  }


  # add gaussian info

  index = 1
  for (rank in sorted$ix) {

    segments(mean[[rank]],0,mean[[rank]],max(yfit[[rank]]),col=colors[index],lty=2)

    arrows(mean[[rank]]-sd[[rank]],0,mean[[rank]]+sd[[rank]],0,col=colors[index],angle=10,length=0.1,lwd=1,code=3)

    text(mean[[rank]], -0.5, paste(formatC(mean[[rank]],format="f",digits=2), "±",formatC(sd[[rank]],format="f",digits=2)), cex=0.75)

    index = index+1
  }

  # TODO possible fail here? check subpop size
  flowframe = subpop[[sorted$ix[1]]] #max retained in analysis
  mix = subpop[[sorted$ix[2]]]

  if (nrow(flowframe) > 2) {
    flowframe@description$"sw.p.value"=shapiro.test(flowframe@exprs[,fluo])$p.value
  }

  if (nrow(mix) > 2) {
    mix@description$"sw.p.value"=shapiro.test(mix@exprs[,fluo])$p.value
  }

  # add legend with counts and shapiro-wilk test for normality

  width = max(length(toString(nrow(subpop[[1]]))),length(toString(nrow(subpop[[2]]))))

  legend("topright", c(paste("n=", formatC(nrow(flowframe),width=width), "; p=",formatC(flowframe@description$"sw.p.value", format="e"),"\nFSC1=", formatC(mean(flowframe@exprs[,"FSC-HLog"]),width=width),"\n"), paste("n=", formatC(nrow(mix),width=width), "; p=", formatC(mix@description$"sw.p.value", format="e"), "\nFSC2=", formatC(mean(mix@exprs[,"FSC-HLog"]),width=width))), text.col=c("#FF0000","#000000"), bty="n")

  dev.off()

  return(mix)

}