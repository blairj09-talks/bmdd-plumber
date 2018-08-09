library(plumber)
library(ggplot2)

# Load model
cars_model <- readRDS("cars-model.rds")

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
function(req, res) {
  # browser()
  # Only parse responseBody if final endpoint is /predict/...
  if (grepl("predict", req$PATH_INFO)) {
    # Parse postBody into data.frame and store in req
    req$predict_data <- tryCatch(jsonlite::fromJSON(req$postBody),
                                 error = function(e) NULL)
    if (is.null(req$predict_data)) {
      res$status <- 400
      return(
        list(
          error = "No JSON data included in request body."
        )
      )
    }
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
#* @param column:character Column name to be highlighted
#* @response 400 Invalid column specified
#* @html
#* @post /predict/table/<column>
function(column, req, res) {
  table_data <- cbind(req$predict_data, predicted_mpg = req$predicted_values)
  
  # Error if column isn't in data
  if (!column %in% names(table_data)) {
    res$status <- 400
    return()
  }
  
  format_list <- list(
    predicted_mpg = formattable::color_tile("red", "white")
  )
  
  format_list[[column]] <- formattable::color_tile("white", "red")
  
  table_data <- table_data[order(table_data$predicted_mpg),]
  formattable::format_table(table_data, format_list, row.names = FALSE)
}

#* Plot submitted data
#* @param x X axis variable
#* @param y Y axis variable
#* @png
#* @post /predict/plot
function(req, x, y){
  plot_data <- cbind(req$predict_data, predicted_mpg = req$predicted_values)
  p <- ggplot(plot_data, aes_string(x = x, y = y)) +
    geom_point() +
    theme_minimal()
  
  print(p)
}
