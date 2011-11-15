
# Return rectangular gate filter

rectangularGateFilter = function(flowset) {

  # TODO (guillaume) how do we derive the numbers from the guava fcs metadata?
  cells = rectangleGate(filterId="aquisition", "FSC-HLog"=c(log10(20), log10(200)), "SSC-HLog"=c(log10(20), log10(500)))

  f=filter(flowset, cells)

  return(f)
}
