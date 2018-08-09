# Build simple model from mtcars dataset

# Model ----
cars_model <- lm(mpg ~ cyl + disp + hp + drat + wt + qsec + vs + am + gear + carb,
                 data = mtcars)

# Save model ----
saveRDS(cars_model, here::here("R", "model-api", "cars-model.rds"))
