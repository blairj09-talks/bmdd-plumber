library(plumber)

p <- plumb(here::here("R", "hello-world-api", "plumber.R"))
p$run(port = 5762)
