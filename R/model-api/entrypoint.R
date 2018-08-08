library(plumber)

p <- plumb(here::here("R", "model-api", "plumber.R"))
p$run(port = 5762)