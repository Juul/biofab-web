

batch = function(out.dir,
                 fcs.paths, # the paths for the input fcs files
                 fluo.channel="", # RED or GRN
                 clean=TRUE, 
                 cluster=TRUE,
                 init.gate="ellipse",
                 clust.levels=c(0.95,0.95), 
                 scale.gating="Lin", 
                 scale.analysis="Log",
                 verbose=FALSE) {

  data.set = list()

  for(i in 1:length(fcs.paths)) {
    cur.out.dir = file.path(out.dir, paste('fcs', i, sep='_'))


    dir.create(cur.out.dir, showWarnings=FALSE, recursive=TRUE)


    
    out.plot.path = file.path(cur.out.dir, 'plot.png')
    out.fcs.c1 = 'c1.fcs'
    out.fcs.c2 = 'c2.fcs'

    data = run(cur.out.dir,
               out.plot.path,
               fcs.paths[i],
               fluo.channel=fluo.channel,
               clean=clean,
               cluster=cluster,
               init.gate=init.gate,
               output.filename=out.fcs.c1,
               output.filename.cluster2=out.fcs.c2,
               clust.levels=clust.levels,
               scale.gating=scale.gating,
               scale.analysis=scale.analysis,
               verbose=verbose)

    if(is.null(data)) {
      unlink(cur.out.dir)
      next
    }

    if(!is.null(data['error'])) {
      unlink(cur.out.dir)
    }

    data.set[[fcs.paths[i]]] = data

  }

  
  return(data.set)
}