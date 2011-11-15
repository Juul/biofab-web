
# Debug output of object attributes

cat.attr = function(obj) {

  for(key in names(attributes(obj))) {
    val = attributes(obj)[[key]]

    cat('$', key, "\n", sep='')

    if((class(val) == 'numeric') | (class(val) == 'character')) {
      cat('  ', paste(val, collapse=', '), "\n")
      cat("\n")
    } else {
      cat("<unprintable>\n\n")
    }
  }
}

cat.list = function(obj) {

  for(key in names(obj)) {
    val = obj[[key]]

    cat('$', key, "\n", sep='')

    if((class(val) == 'numeric') | (class(val) == 'character')) {
      cat('  ', paste(val, collapse=', '), "\n")
      cat("\n")
    } else {
      cat("<unprintable>\n\n")
    }
  }
}