library(plumber)

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

#* Clean up cookie
#* @filter clean-cookie
function(req, res) {
  if (!is.null(req$cookies$data)) {
    print(paste("Data cookie:", req$cookies$data))
    print(paste("Clean cookie:", stringr::str_extract(req$cookies$data, "\\[.*\\]")))
    if (req$cookies$data != 0) {
      # Clean up cookie (issue with leading and trailing " when deployed to RSC)
      req$cookies$data <- stringr::str_extract(req$cookies$data, "\\[.*\\]|^0$")
    }
  }
  
  print(paste("Cleaned Data cookie:", req$cookies$data))
  
  forward()
}

#* Parse and predict on model data for future endpoints
#* @filter predict
function(req, res) {
  # Only parse data if final endpoint is /predict/...
  if (grepl("predict", req$PATH_INFO)) {
    # Parse postBody into data.frame and store in req
    if (is.null(req$cookies$data)) {
      res$status <- 400
      return(list(error = "No data provided."))
    }
    
    if (req$cookies$data == 0) {
      res$status <- 400
      return(list(error = "No data provided."))
    }
    
    # Store predict data and predicted values in request
    req$predict_data <- jsonlite::fromJSON(req$cookies$data)
    
    # Predict based on values in postBody and store in req
    req$predicted_values <- predict(cars_model, req$predict_data)
  }
  
  # Forward the request
  forward()
}

#* Add data
#* @post /data
function(req, res) {
  data <- tryCatch(jsonlite::fromJSON(req$postBody),
                   error = function(e) NULL)
  if (is.null(data)) {
    res$status <- 400
    return(list(error = "No data provided"))
  }
  
  if (!is.null(req$cookies$data)) {
    if (req$cookies$data != 0) {
      data <- rbind(data, jsonlite::fromJSON(req$cookies$data))
    }
  }
  
  res$setCookie("data", jsonlite::toJSON(data))
  list(message = "Data received and stored in cookie")
}

#* Clear cookie
#* @param cookie_name Cookie to clear
#* @get /clear
function(req, res) {
  res$setCookie("data", 0)
  list(
    message = "data cookie cleared."
  )
}

#* Predict the MPG of a given car(s)
#* @get /predict/values
function(req) {
  req$predicted_values
}

#* Predicted values in nice HTML table
#* @param column:character Column name to be highlighted
#* @response 400 Invalid column specified
#* @html
#* @get /predict/table/<column>
function(req, res, column) {
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
  formattable::format_table(table_data, format_list, row.names = TRUE)
}
