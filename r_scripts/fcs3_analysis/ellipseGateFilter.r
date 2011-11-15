
# Return ellipse gate filter

ellipseGateFilter = function(flowset) {

  par = c('FSC-HLog','SSC-HLog')

  # Using values from the guava fcs metadata: for some reason need to be multiplied by 16!
  cov = matrix(16*cov.matrix(0.1920118678135238, 0.08082951003878829, 36.79291744969011), nrow = 2, ncol=2, byrow=TRUE, dimnames = list(par,par))

  center = c('FSC-HLog'=0.7045165131393946, 'SSC-HLog'= 2.442332442332441)

  cells = ellipsoidGate(filterId="aquisition", .gate=cov, mean=center, distance=1)

  f = filter(flowset, cells)

  return(f)
}
