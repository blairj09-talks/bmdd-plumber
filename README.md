# Deploying ML models via Plumber

This repository provides a working example for deploying a Machine Learning
model via the [`plumber`](https://www.rplumber.io) package. This repository also
contains [slides](slides/) used for a talk given at [RStudio::conf
2019](https://www.rstudio.com/conference/).

There are two separate pieces to this example. The [model-api](R/model-api)
files provide scripts for both training a simple model and building a Plumber
API to serve that model. The [api-app](R/api-app) files build a
simple shiny application to interact with the deployed model API. The
[native-app](R/native-app) files create a separate shiny app that uses the R
model but *does not* use the API. These two files can be used to show how an
existing application ([native-app](R/native-app/app.R)) can be
[updated](R/api-app/app.R) to leverage an API.
