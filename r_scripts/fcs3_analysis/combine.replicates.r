
combine.replicates = function(data) {

  # initialize names
  no.combined.stat = c("cluster.nbr", "cell.nbr", "status")
  single.col       = length(no.combined.stat)

  if ("description" %in% colnames(data[[1]])) {
    single.col = single.col + 1
  }

  # setup names
  names=colnames(data[[1]])[1:(single.col-1)]

  for (name in colnames(data[[1]]))
    if (grepl("mean", name)) names=c(names,sub("mean", "rep.mean", name),
                        sub("mean", "rep.var", name),
                        sub("mean", "inter.rep.var", name),
                        sub("mean", "intra.rep.var", name))
    names=c(names, colnames(data[[1]])[length(data[[1]])])

  # initialize dataframe
  nocol=length(names)
  norow=nrow(data[[1]])
  norep=length(data)
  combi=data.frame(matrix(data=0, ncol=nocol,nrow=norow))
  colnames(combi)=names
  rownames(combi)=rownames(data[[1]])


  for (i in 1:norow) {
    index=1
    for (name in colnames(data[[1]])) {
      # special case for descriptions
      if (name == "description") {
        combi[i, index] = data[[1]][i,name]
        index=index+1
      } else {  # treat replicates. assume that var follows mean data in input dataframes
        nbr=vector(length=norep)
        for (k in 1:(norep)) {
          nbr[k]=data[[k]][i,name]
        }

        # no.combined.stat list the fields that should be reported separated by slash
        if(name %in% no.combined.stat) {
          t=table(nbr)
          if(length(t) == 1) {
            combi[i, index] = dimnames(t)[[1]]
          } else {
            combi[i, index] = paste(nbr, collapse="/")
            index = index+1
          }
        }
        # calculate replicate means and the inter-replicates variances
        if(grepl("mean", name)) {
          combi[i,index]=mean(nbr)
          combi[i,(index+2)]=var(nbr)
        }
        # calculate intra- replicate mean variances and total replicate variances 
        if(grepl("var", name)) {
          combi[i,index+3]=mean(nbr)
          combi[i,(index+1)]=combi[i,(index+2)]+combi[i,(index+3)]
          index=index+4
        }
      }
    }
  }
  return(combi)
}
