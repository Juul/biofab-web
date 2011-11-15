

# Clean the data

clean.flowSet = function(flowset, fluo.channel=FALSE, scale="Log") {  

  flowframe = flowset[[1]]

  well = ""
  desc = ""

#  channels = c()

#  cat("wellID: ", flowframe@description$`$WELLID`, "\n")
#  cat("description attributes: ", cat.list(flowframe@description), "\n")

  # Check Mapping and fluo channels

  channel = get.fluo(fluo.channel, scale=scale)
  if(class(channel) != 'character') {
    stop(paste("Unknown channel: ", fluo.channel, "\n", sep=''))
  }

  well = flowframe@description$`$WELLID`

  # clean linear values

  # TODO fix all
  if (channel == 'ALL') {

    flowframe = flowframe[flowframe@exprs[,"FSC-HLin"]>0 & flowframe@exprs[,"SSC-HLin"]>0 & flowframe@exprs[,"GRN-HLin"]>0 & flowframe@exprs[,"RED2-HLin"]>0]

  } else if (channel == 'GRN-HLin') {

    flowframe = flowframe[flowframe@exprs[,"FSC-HLin"]>0 & flowframe@exprs[,"SSC-HLin"]>0 & flowframe@exprs[,"GRN-HLin"]>0]

  } else if (channel == 'RED2-HLin') {

    flowframe = flowframe[flowframe@exprs[,"FSC-HLin"]>0 & flowframe@exprs[,"SSC-HLin"]>0 & flowframe@exprs[,"RED2-HLin"]>0]

  } else {

    flowframe = flowframe[flowframe@exprs[,"FSC-HLin"]>0 & flowframe@exprs[,"SSC-HLin"]>0]

  }

  # TODO why is 1 being added to each exprs here?
  # correct for log transform
  flowframe@exprs[,"GRN-HLin"] = flowframe@exprs[,"GRN-HLin"]+1
  flowframe@exprs[,"RED2-HLin"] = flowframe@exprs[,"RED2-HLin"]+1

  # recalculate logs
  flowframe@exprs[,"FSC-HLog"] = log10(flowframe@exprs[,"FSC-HLin"])
  flowframe@exprs[,"SSC-HLog"] = log10(flowframe@exprs[,"SSC-HLin"])
  flowframe@exprs[,"GRN-HLog"] = log10(flowframe@exprs[,"GRN-HLin"])
  flowframe@exprs[,"RED2-HLog"] = log10(flowframe@exprs[,"RED2-HLin"])

  # Add new descriptions
  keyword(flowset) = list(status="Not set")
  keyword(flowset) = list("GRN-HLog.sw.p.value"=NA)
  keyword(flowset) = list("RED2-HLog.sw.p.value"=NA)
  keyword(flowset) = list(cluster=NA)
  keyword(flowset) = list(cluster.100=NA)
  keyword(flowset) = list(cell.nbr=NA)

  # TODO why is this necessary?
  # Change descriptions messing with I/O
  keyword(flowset) = list("GTI$USERNAME" = "GUAVAHTGTI")

  flowset[[1]] = flowframe

  return(flowset)
}

