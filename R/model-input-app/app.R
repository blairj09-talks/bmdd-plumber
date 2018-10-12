# Shiny App for providing data input to cars plumber API
library(shiny)
library(httr)

base_url <- config::get("base_url", config = "rsconnect")

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
            hr(),
            selectInput("highlight_column",
                        "Highlighted column",
                        choices = c("hp", "cyl"),
                        selected = "hp"),
            fluidRow(
              actionButton("submit",
                           "Submit"),
              actionButton("clear",
                           "Clear")
            )
        ),

        # Show a plot of the generated distribution
        mainPanel(
           htmlOutput("results_table"),
           wellPanel(
             textOutput("raw_results")
           )
        )
    )
)

server <- function(input, output) {
  observeEvent(input$clear, {
    httr::GET(url = paste0(base_url, "/clear"))
  })
  
  observeEvent(input$submit, {
    # Post data
    httr::POST(url = paste0(base_url, "/data"),
               body = data.frame(hp = as.numeric(input$hp), cyl = as.numeric(input$cyl)),
               encode = "json")
  })
  
  api_results <- eventReactive(list(input$submit, input$clear, input$highlight_column), {
    # Retrieve html table
    res <- httr::GET(url = paste0(base_url, "/predict/table/", input$highlight_column))
    
    # Extract html_table
    html_table <- httr::content(res, as = "text")
    
    # Get raw results
    res <- httr::GET(url = paste0(base_url, "/predict/values"))
    json_predictions <- httr::content(res, as = "text")
    
    if (grepl("No data provided", html_table)) {
      html_table <- ""
      json_predictions <- ""
    }
    
    list(
      html_table = html_table,
      json_predictions = json_predictions
    )
  })
  
  output$results_table <- renderText(api_results()$html_table)
  
  output$raw_results <- renderPrint(api_results()$json_predictions)
}

shinyApp(ui = ui, server = server)
