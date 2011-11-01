
cov.matrix = function (a, b, angle) {
   theta = angle * (pi/180)
   c1 = ((cos(theta)^2)/a^2) + ((sin(theta)^2)/b^2)
   c2 = sin(theta) * cos(theta) * ((1/a^2) - (1/b^2))
   c3 = ((sin(theta)^2)/a^2) + ((cos(theta)^2)/b^2)
   m1 = matrix(c(c1, c2, c2, c3), byrow=TRUE, ncol=2)
   m2 = solve(m1)
   m2
}