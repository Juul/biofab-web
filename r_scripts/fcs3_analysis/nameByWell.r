
nameByWell = function(flowframe) {
  id = c()

  id = append(id, flowframe@description$`$WELLID`)

  sampleNames(flowset) = id
  flowset =flowset[order(sampleNames(flowset)),]

  return(flowset)
}
