# Deploying ML models via Plumber

This repository provides a working example for deploying a Machine Learning
model via the [`plumber`](https://www.rplumber.io) package. It is loosely based
on [a talk](https://github.com/blairj09/bmdd-plumber) given at [Big Mountain
Data & Dev](https://www.utahgeekevents.com/events/big-mountain-data-dev/), but
this example is drastically simplified.

There are two separate pieces to this example. The [model-api](R/model-api)
files provide scripts for both training a simple model and building a Plumber
API to serve that model. The [api-app](R/api-app) files build a
simple shiny application to interact with the deployed model API. The
[native-app](R/native-app) files create a separate shiny app that uses the R
model but *does not* use the API. These two files can be used to show how an
existing application ([native-app](R/native-app/app.R)) can be
[updated](R/api-app/app.R) to leverage an API.

---

[![](R/model-input-app/images/app-demo.gif)](http://colorado.rstudio.com/rsc/car-model-app/)
