

draw.plot = function(flowframe, fluo, out.path.plot) {

  # graphical parameter
  x.lim = c(0,4)

  png(file.path(out.path.plot))

  # Draw histogram, density plot and normal fit

#  cat("Fluo is: ", fluo, "\n")
#  cat("Exprs: ", flowframe@exprs[,fluo], "\n")

  breaks = nrow(flowframe)/5
  cat("breaks: ", breaks, "\n")
  h = hist(flowframe@exprs[,fluo],breaks=breaks, plot=FALSE)
  
  mean = mean(flowframe@exprs[,fluo])
  cat("mean: ", mean, "\n")
  sd = sd(flowframe@exprs[,fluo])
  cat("sd: ", sd, "\n")

  xfit = seq(x.lim[1],x.lim[2],length=100)
  yfit = dnorm(xfit,mean=mean,sd=sd)
  yfit = yfit*diff(h$mids[1:2])*length(flowframe@exprs[,fluo]) 

  h = hist(flowframe@exprs[,fluo], breaks=breaks, border=FALSE, col="#FF000050", main=paste(flowframe@description$description," (",flowframe@description$`$WELLID`,")\n ", sep=""),xlim=c(0,4), ylim=c(-0.5, max(c(yfit,h$counts))), xlab=fluo)

  d = density(flowframe@exprs[,fluo])
  d$y = d$y*h$counts[1]/h$density[1]

  polygon(d$x,d$y, col="#FF000050", border="#FF0000", lty=3)
  lines(xfit, yfit, col="#FF0000", lwd=2, lty=1)

  # add gaussian info

#  segments(mean,0,mean,max(yfit),col="#FF0000",lty=2)
#  arrows(mean-sd,0,mean+sd,0,col="#FF0000",angle=10,length=0.1,lwd=1,code=3)
#  text(mean, -0.5, paste(formatC(mean,format="f",digits=2), "±",formatC(sd,format="f",digits=2)), cex=0.75)

  # add legend with counts and shapiro-wilk test for normality

#  legend("topright", c(paste("n=", nrow(flowframe)), paste("p=",formatC(flowframe@description$"sw.p.value", format="e"))),text.col=c("#000000"), bty="n")

  # save plot

  dev.off()

}