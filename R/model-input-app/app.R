# Shiny App for providing data input to cars plumber API
library(shiny)
library(httr)

base_url <- config::get("base_url")

ui <- fluidPage(

    # Application title
    titlePanel("Cars Plumber API"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("hp",
                        "Horsepower",
                        min = min(mtcars$hp),
                        max = max(mtcars$hp),
                        value = median(mtcars$hp)),
            selectInput("cyl",
                        "Cylinder",
                        choices = sort(unique(mtcars$cyl)),
                        selected = sort(unique(mtcars$cyl))[1]),
            fluidRow(
              actionButton("submit",
                           "Submit")
            )
        ),

        # Show a plot of the generated distribution
        mainPanel(
           wellPanel(
             textOutput("raw_results")
           )
        )
    )
)

server <- function(input, output) {
  predicted_values <- eventReactive(input$submit, {
    # Post data
    api_res <- httr::POST(url = paste0(base_url, "/predict"),
                           body = data.frame(hp = as.numeric(input$hp), cyl = as.numeric(input$cyl)),
                           encode = "json")
    
    httr::content(api_res, as = "text", encoding = "UTF-8")
  })
  
  output$raw_results <- renderPrint(predicted_values())
}

shinyApp(ui = ui, server = server)
