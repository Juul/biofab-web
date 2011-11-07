
# TODO: make this better!

get.fluo = function(fluo, scale="") {
	if (is.na(fluo)) return(c())
	fluo=unlist(strsplit(fluo, "/"))
	for(f in fluo)
		if (!(f %in% fluo.type)) fluo.type<<-append(fluo.type, f)
	if(scale %in% c("Lin", "Log")) {
		for(i in 1:length(fluo)) {
			if(fluo[i] == "GRN") {
        fluo[i]=paste(fluo[i],"-H",scale,sep="")
      } else if(fluo[i] == "RED") {
        fluo[i]=paste(fluo[i],"2-H",scale,sep="")
      }	else {
        return(-1) 
      }
    }
  }
	return(fluo)
}
