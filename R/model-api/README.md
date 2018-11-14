Cars Model API
================

This API demonstrates how to take a machine learning model trained in R
and expose it via REST API endpoints using the `plumber` package. In
this example, a simple linear model is built on top of the `mtcars`
dataset.

``` r
# Model ---- (insert fancy model here)
cars_model <- lm(mpg ~ cyl + hp,
                 data = mtcars)

# Save model ----
saveRDS(cars_model, here::here("R", "model-api", "cars-model.rds"))
```

This code creates the cars model and saves it as an `.rds` file. The
[`here`](https://github.com/r-lib/here) package is used to provide help
with file paths.

Once the model has been trained and saved, a series of API endpoints can
be built around the model. For this example, new data is submitted by
the user and stored in a cookie attached to the user session. This
pattern allows the user to submit additional data while using cookies to
maintain user state.

These endpoints are defined in [`plumber.R`](plumber.R) and explained in
detail here.

## API Setup

``` r
library(plumber)

# Load model
# Depending on model size, this can be a farily expensive operation
cars_model <- readRDS("cars-model.rds")

#* @apiTitle mtcars model API
#* @apiDescription Endpoints for working with mtcars dataset model
```

This initial setup loads the `plumber` package, loads the saved model,
and provides some additional API details (Title and Description)

## Filters

[Filters](https://www.rplumber.io/docs/routing-and-input.html#filters)
are used by Plumber to peform some action on an incoming request and
then forward the request along to the next stop on the router. This API
uses a few different filters.

### Log

``` r
#* Log some information about the incoming request
#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-", 
      req$REQUEST_METHOD, req$PATH_INFO, "-", 
      req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
  
  # Forward the request
  forward()
}
```

This filter is pulled directly from the [Plumber
docs](https://www.rplumber.io/docs/routing-and-input.html#forward-to-another-handler)
and logs information about incoming requests and then forwards the
request on to subsequent endpoints.

### Clean Cookies

The `clean-cookie` filter makes sure that the JSON stored in the “data”
cookie of the incoming request is appropriately formatted for `jsonlite`
to parse by removing leading and trailing `"` that are sometimes added
to the JSON.

``` r
#* Clean up cookie
#* @filter clean-cookie
function(req, res) {
  if (!is.null(req$cookies$data)) {
    if (req$cookies$data != 0) {
      # Clean up cookie (issue with leading and trailing " when deployed to RSC)
      req$cookies$data <- stringr::str_extract(req$cookies$data, "\\[.*\\]|^0$")
    }
  }
  forward()
}
```

### Predict

Finally, we use a filter to parse incoming data and use the model to
calculate predictions on the new data. Both the parsed data and the
predicted values are stored in the request object so they can easily be
used by downstream endpoints. This filter uses the data stored in the
cookies of the request to calculate new predictions. Data is stored in
the “data” cookie via the `/data` endpoint, which is defined next.

``` r
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
```

## Endpoints

Each endpoint defined in the API serves a different purpose.

### POST data

This API anticipates that users submit JSON data via a POST request. In
Plumber, data submitted with a POST request can be accessed via
`req$postBody`. In this endpoint, submitted data is first checked to see
if it is valid JSON. If valid JSON is found, the data is converted into
a `data.frame`, appended to any existing data stored in the “data”
cookie, then serialized back into JSON and stored in the “data” cookie
on the user session. This data is processed and used by the model in the
`predict` filter described previously.

``` r
#* Add data
#* @post /data
function(req, res) {
  data <- tryCatch(jsonlite::fromJSON(req$postBody),
                   error = function(e) NULL)
  if (is.null(data)) {
    res$status <- 400
    return(list(error = "No data provided"))
  }
  
  # Add new data to existing data stored in cookie
  if (!is.null(req$cookies$data)) {
    if (req$cookies$data != 0) {
      data <- rbind(data, jsonlite::fromJSON(req$cookies$data))
    }
  }
  
  # Store data in cookie
  res$setCookie("data", jsonlite::toJSON(data))
  list(message = "Data received and stored in cookie")
}
```

### DELETE cookie

``` r
#* Clear specified cookie
#* @param cookie_name:character Name of cookie to delete
#* @delete /<cookie_name>
function(req, res, cookie_name) {
  res$setCookie(cookie_name, NULL)
  list(
    message = glue::glue("{cookie_name} cookie cleared.")
  )
}
```

This endpoint provides a mechanism for resetting the data cookie for a
users session. It has been designed so that it can generalized to reset
any cookie.

### GET predict values

``` r
#* Retrieve predicted MPG values for given car data
#* @get /predict/values
function(req) {
  req$predicted_values
}
```

This endpoint returns the predicted values based on the data stored in
the users’ “data” cookie in a JSON response. The data that is returned
is calculated in the `predict` filter.

### GET predict table

``` r
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
```

This endpoint defines an HTML table based on the submitted data along
with the predicted values. The user can specify which `column` of the
table should be highlighted with the `column` [dynamic path
argument](https://www.rplumber.io/docs/routing-and-input.html#dynamic-routes).
