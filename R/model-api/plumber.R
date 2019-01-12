## ---- api-setup
library(plumber)

# Load model
# Depending on model size, this can be a fairly expensive operation
cars_model <- readRDS("cars-model.rds")

#* @apiTitle mtcars model API
#* @apiDescription Endpoints for working with mtcars dataset model

## ---- filter-logger
#* Log some information about the incoming request
#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-",
      req$REQUEST_METHOD, req$PATH_INFO, "-",
      req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
  forward()
}

## ---- post-data
#* Submit data and get a prediction in return
#* @post /predict
function(req, res) {
  data <- tryCatch(jsonlite::fromJSON(req$postBody),
                   error = function(e) NULL)
  if (is.null(data)) {
    res$status <- 400
    list(error = "No data submitted")
  }

  predict(cars_model, data)
}
