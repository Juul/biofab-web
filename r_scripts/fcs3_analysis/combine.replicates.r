
combine.replicates = function(data) {
  no.combined.stat = c("cluster.nbr", "cell.nbr", "status")

  single.col       = length(no.combined.stat)

  if ("description" %in% colnames(data[[1]])) {
    single.col = single.col + 1
  }

  nocoldata = ncol(data[[1]])
  nocol = 3 * (nocoldata - single.col) + single.col
  norow = nrow(data[[1]])
  norep = length(data)
  combi = data.frame(matrix(data=0, ncol=nocol, nrow=norow))

	names = colnames(data[[1]])[1:(single.col - 1)]

  for(name in colnames(data[[1]])[-c(1:(single.col-1),nocoldata)]) {
    names = c(names,paste(c("mean.", "sd.", "cv."), name, sep=""))
  }

  names = c(names, colnames(data[[1]])[nocoldata])

  colnames(combi) = names
  rownames(combi) = rownames(data[[1]])

  for(i in 1:norow) {
		index = 1
		for(name in colnames(data[[1]])) {
      if(name == "description") {

        combi[i, index] = data[[1]][i,name]
        index=index+1

      } else {

        nbr = vector(length=norep)

        for (k in 1:(norep)) {
          write(k, file="/tmp/file_k")
          write(i, file="/tmp/file_i")
          write(name, file="/tmp/file_name")
          write(data, file="/tmp/file_data")
          nbr[k] = data[[k]][i, name]
        }

        if(name %in% no.combined.stat) {

          t = table(nbr)
          if(length(t) == 1) {
            combi[i, index] = dimnames(t)[[1]]
          } else {
            combi[i, index] = paste(nbr, collapse="/")
          }
          index = index + 1

        } else {

					combi[i, index] = mean(nbr)
					combi[i, (index + 1)] = sd(nbr)
					combi[i, (index + 2)] = 100 * combi[i, index + 1] / combi[i, (index)]
					index=index+3

        }
			}
		}
	}
	return(combi)
}
