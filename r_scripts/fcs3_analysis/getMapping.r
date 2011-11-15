
getMapping = function(mapping) {

  mapping=read.csv(mapping, row.names=1, na.string="",stringsAsFactors=FALSE)
  names(mapping) = tolower(names(mapping))

  # Make sure well name and fluo are correctly formated
  wells=row.names(mapping)
  empty=rep(TRUE, nrow(mapping))

  for (i in 1:nrow(mapping)){
    if(nchar(wells[i]) < 3) {
      wells[i] = toString(paste(substr(wells[i],1,1), 0 ,substr(wells[i],2,2), sep=''))
    }

    if(!is.na(mapping[i,"status"]) & (mapping[i,"status"]!="NA") & (mapping[i,"status"]!=0)) {
      empty[i] = FALSE
    }
  }

  row.names(mapping) = wells

  # remove empty wells
  if(length(empty)>0) {
    mapping = mapping[!empty,]
  }

  # return modified mapping dataframe)
  return(mapping)
}
