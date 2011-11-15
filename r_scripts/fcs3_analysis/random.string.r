

random.string = function(n=1, length=12) {
  str = paste(sample(c(0:9, letters, LETTERS), length, replace=TRUE), collapse='')
  return(str)
}