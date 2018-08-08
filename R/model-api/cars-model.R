# Build simple model from mtcars dataset

# Packages ----
library(tidyverse)

# Data ---
model_data <- as_tibble(mtcars, rownames = "car_name")

# Model ----
cars_model <- lm(mpg ~ cyl + disp + hp + drat + wt + qsec + vs + am + gear + carb,
                 data = model_data)

# Save model ----
write_rds(cars_model, here::here("R", "model-api", "cars-model.rds"))
