library(plumber)
library(tidyverse)

# Load model
cars_model <- read_rds(here::here("R", "model-api", "cars-model.rds"))

#* @apiTitle mtcars model API
#* @apiDescription Endpoints for working with mtcars dataset model

#* Log some information about the incoming request
#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-", 
      req$REQUEST_METHOD, req$PATH_INFO, "-", 
      req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
  
  # Forward the request
  forward()
}

#* Parse and predict on model data for future endpoints
#* @filter predict
function(req) {
  # browser()
  # Only parse responseBody if final endpoint is /predict/...
  if (str_detect(req$PATH_INFO, "predict")) {
    # Parse postBody into data.frame and store in req
    req$predict_data <- jsonlite:::fromJSON(req$postBody)
    # Predict based on values in postBody and store in req
    req$predicted_values <- predict(cars_model, req$predict_data)
  }
  
  # Forward the request
  forward()
}

#* Predict the MPG of a given car(s)
#* @post /predict/values
function(req) {
  req$predicted_values
}

#* Predicted values in nice HTML table
#* @param col Column name to be highlighted
#* @html
#* @post /predict/table/<column>
function(column, req) {
  format_list <- list(
    predicted_mpg = formattable::color_tile("red", "white")
  )
  
  format_list[[column]] <- formattable::color_tile("white", "red")
  
  bind_cols(req$predict_data, predicted_mpg = req$predicted_values) %>% 
    arrange(predicted_mpg) %>% 
    formattable::format_table(format_list)
}

#* Plot submitted data
#* @param x X axis variable
#* @param y Y axis variable
#* @png
#* @post /predict/plot
function(req, x, y){
  plot_data <- bind_cols(req$predict_data, predicted_mpg = req$predicted_values)
  p <- ggplot(plot_data, aes_string(x = x, y = y)) +
    geom_point() +
    theme_minimal()
  
  print(p)
}
