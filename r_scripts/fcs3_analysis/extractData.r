
# Correct for background and reference as applicable (defined in mapping)
# Somewhat arbitrarily, eliminate measures which are below twice the background on the denominator channel, if applicable

extractData = function(flowframe,
                       flowframe2,
                       fluo.channel, 
                       scale="Lin") {

  fluo = get.fluo(fluo.channel, scale)

  data = list()

  if(class(flowframe2) == 'flowFrame') {
    data['num_clusters'] = 2
    two = TRUE
  } else {
    data['num_clusters'] = 1
    two = FALSE
  }

  data['fluo_channel'] = fluo.channel
  data['scale'] = scale

  data['num_events'] = nrow(flowframe@exprs[, fluo])
  data['mean'] = mean(flowframe@exprs[, fluo], na.rm=TRUE)
  data['variance'] = var(flowframe@exprs[, fluo], na.rm=TRUE)
  data['standard_deviation'] = sd(flowframe@exprs[, fluo], na.rm=TRUE)
  data['events'] = paste(flowframe@exprs[, fluo], collapse='|')

  # cluster 2
  if(two) {
    data['num_events_c2'] = nrow(flowframe2@exprs[, fluo])
    data['mean_c2'] = mean(flowframe2@exprs[, fluo], na.rm=TRUE)
    data['variance_c2'] = var(flowframe2@exprs[, fluo], na.rm=TRUE)
    data['standard_deviation_c2'] = sd(flowframe2@exprs[, fluo], na.rm=TRUE)
    data['events_c2'] = paste(flowframe2@exprs[, fluo], collapse='|')
  }
  


  return(data)
}
