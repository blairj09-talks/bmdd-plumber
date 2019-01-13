library(plumber)

pr <- plumb("plumber.R")

pr$run(port = 5762,
      swagger = function(pr, spec, ...){
        # Define request body for POST to /predict
        spec$paths$`/predict`$post$requestBody <- list(
          description = "New data to predict",
          required = TRUE,
          content = list(
            `application/json` = list(
              # Define JSON schema
              schema = list(
                title = "Car",
                required = c("cyl", "hp"),
                properties = list(
                  cyl = list(
                    type = "integer"
                  ),
                  hp = list(
                    type = "integer"
                  )
                )
              )
            )
          )
        )
        spec
      })
