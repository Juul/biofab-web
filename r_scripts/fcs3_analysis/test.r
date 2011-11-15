
script.path = file.path(getwd(), 'r_scripts')
data.path = file.path(getwd(), 'example_data', 'well.fcs')
out.path = file.path(getwd(), 'output')
setwd(script.path)

source('fcs3_analysis.r')

cat("Running analysis.\n")

run(out.path, data.path, fluo="GRN", init.gate="ellipse")



