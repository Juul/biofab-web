norm2length = function(flowset,t=0) {
  names=c("well","mean.log10(RED2.log)","sd.log10(RED2.log)","mean.corrected","sd.corrected", "mean.corrected","sd.corrected")
  data=matrix(nrow=length(flowset), ncol=length(names))
  colnames(data)=names
  for (i in 1:length(flowset))
  {
    lin=lm(`RED2.HLin`~`FSC.HLin`, data.frame(flowset[[i]]@exprs))
    r2 =summary(lin)$r.squared
    if (r2>t)
    {
      corrected1=((flowset[[i]]@exprs[,"RED2-HLin"]-lin$"coefficients"[[1]])
             /(lin$"coefficients"[[2]]*flowset[[i]]@exprs[,"FSC-HLin"])
             *mean(flowset[[i]]@exprs[,"RED2-HLin"]))
      plot(flowset[[i]]@exprs[,"FSC-HLin"],flowset[[i]]@exprs[,"RED2-HLin"], cex=0.5, main=flowset[[i]]@description$`$WELLID`)
      points(flowset[[i]]@exprs[,"FSC-HLin"],corrected1, col="red",cex=0.5)
      plot(density(flowset[[i]]@exprs[,"RED2-HLog"]))
      lines(density(log10(corrected1), na.rm="T"),col="red")
      corrected2=corrected1
      corrected2[which(corrected2<=0)]= 1e-10
    data[i,]=c(flowset[[i]]@description$`$WELLID`,
          mean(flowset[[i]]@exprs[,"RED2-HLog"]),
          sd(flowset[[i]]@exprs[,"RED2-HLog"]),
          mean(log10(corrected1),na.rm=T),
          sd(log10(corrected1),na.rm=T),
          mean(log10(corrected2),na.rm=T),
          sd(log10(corrected2),na.rm=T))
    }
    else data[i,]=c(flowset[[i]]@description$`$WELLID`,
          mean(flowset[[i]]@exprs[,"RED2-HLog"]),
          sd(flowset[[i]]@exprs[,"RED2-HLog"]),
          NA,
          NA,
          NA,
          NA)
  }
  return(data.frame(data))
  
}
