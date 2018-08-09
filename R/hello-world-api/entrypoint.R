library(plumber)

p <- plumb("plumber.R")
p$run(port = 5762)
