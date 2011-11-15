

multi.ecdf=function(list, start=0, stop=100) {
  list=list[!unlist(lapply(list,is.null))]
  def.par = par(no.readonly = TRUE)
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