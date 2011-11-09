
options(keep.source=TRUE)

with.error.handling = function(pAGbyeZxOMh3Py1, ...) {
  withCallingHandlers(pAGbyeZxOMh3Py1(...), error=function(e) {
    dump.frames()
    n <- length(last.dump)
    calls <- names(last.dump)
    msgs = paste("  ", 1L:n, ": ", calls, sep="")
    msg = ''
    for(i in 1:length(msgs)) {
      msg = paste(msg, msgs[i], sep="\n")
    }
    very_random_string = "9pAGbyeZxOMh3Py1tO5YrsrYj7pHyWP5bNRrI5p6Z0MKAPVAoH3pjpUFvy0ewG98"
    stop(paste(conditionMessage(e), very_random_string, msg, sep=''))
  })
}

