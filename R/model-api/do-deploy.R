# Deploy plumber API to digital ocean droplet

# Packages ----
library(plumber)
library(analogsea)

# Provision DO droplet
plumber_do <- do_provision(name = "plumber", region = "sfo2")

# Install R packages on droplet
install_r_package(plumber_do, "ggplot2")
install_r_package(plumber_do, "formattable")

# Publish API to droplet
do_deploy_api(droplet = plumber_do, 
              path = "cars-api", 
              localPath = here::here("R", "model-api"),
              port = 8028,
              forward = TRUE,
              swagger = TRUE)
