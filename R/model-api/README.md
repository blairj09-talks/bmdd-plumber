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
be built around the model. These endpoints are defined in
[`plumber.R`](plumber.R) and explained in detail here.

## API Setup

``` r
library(plumber)

# Load model
# Depending on model size, this can be a fairly expensive operation
cars_model <- readRDS("cars-model.rds")

#* @apiTitle mtcars model API
#* @apiDescription Endpoints for working with mtcars dataset model
```

This initial setup loads the `plumber` package, loads the saved model,
and provides some additional API details (Title and Description). Note
that the `cars_model` object is loaded into the global environment here,
and is then made available to any filters and endpoints that are
subsequently defined. We could also load the model inside the actual
`/predict` endpoint function that utilizes the model. However, this
would mean that every time the `/predict` endpoint was called, the model
would first be loaded before it could be used, rather than being
immediately available.

## Filters

[Filters](https://www.rplumber.io/docs/routing-and-input.html#filters)
are used by Plumber to perform some action on an incoming request and
then forward the request along to the next stop on the router. This API
uses a filter to log information about incoming requests, as described
in the [Plumber
docs](https://www.rplumber.io/docs/routing-and-input.html#forward-to-another-handler).

``` r
#* Log some information about the incoming request
#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-",
      req$REQUEST_METHOD, req$PATH_INFO, "-",
      req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
  forward()
}
```

## Endpoints

This API anticipates that users submit JSON data via a POST request. In
Plumber, data submitted with a POST request can be accessed via
`req$postBody`. In this endpoint, submitted data is first checked to see
if it is valid JSON. If valid JSON is found, the data is converted into
a `data.frame` and then the [model](cars-model.R) is used to form
predictions based on that data. These predicted values are returned to
the client as a JSON object.

``` r
#* Submit data and get a prediction in return
#* @post /predict
function(req, res) {
  data <- tryCatch(jsonlite::parse_json(req$postBody, simplifyVector = TRUE),
                   error = function(e) NULL)
  if (is.null(data)) {
    res$status <- 400
    list(error = "No data submitted")
  }

  predict(cars_model, data)
}
```
