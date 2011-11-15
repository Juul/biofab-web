
# Get the real name of the fluorescence channels
# based on channel (GRN, RED) and scale(""

# TODO rename this
#   should be called get.channel.name(channel, scale)

get.fluo = function(fluo, scale="") {

  if(is.na(fluo)) {
    return(NULL)
  }

  if(scale %in% c("Lin", "Log")) {
    if(fluo == "GRN") {

      fluo = paste(fluo, "-H", scale, sep="")

    } else if(fluo == "RED") {

      fluo = paste(fluo, "2-H", scale, sep="")

    }  else {

      return(NULL) 

    }
  } else {
    return(NULL)
  }

  return(fluo)
}
