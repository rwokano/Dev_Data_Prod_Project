library(shiny)
library(markdown)
shinyUI
(
  navbarPage("S.T.A.T.",
    tabPanel("Welcome",
      includeMarkdown("welcome.md")
      
    ),##tabPanel "Welcome" 
    tabPanel("App",
      sidebarLayout( 
        sidebarPanel(          
          p("Thinking of relocating?"),
          br(),
          p("Check out the daily average temperature for your desired state!  Make your selections below to insure you make the ",em("right"),"move!"),
          br(),
          br(),
          radioButtons("timeChoice", 
                       label = "Select the time measurement", 
                       choices = list("Days within a Month" = 1, 
                                      "Month Over Years" = 2)),
          radioButtons("degrees", 
                       label = "Select Celsius / Fahrenheit", 
                       choices = list("Celsius" = 1, 
                                      "Fahrenheit" = 2)),
          
          selectInput('month', "Select the Month you're interested in",
                      choices=c("January","Feburary","March","April","May",
                                "June","July","August","September","October",
                                "November","December")),
          uiOutput('years'),
          uiOutput("states"),
          br(),
          br(),
          img(src = "For_Sale.jpg", height = 125, width = 125)          
          
        ), ## sidebarPanel
        mainPanel( 
          plotOutput("tempPlot"),
          p("Below are some sample statistics from the range you've selected"),
          tableOutput("sampleStats")                  
        ) ## mainPanel 
      )## sidebarLayout               
    ) ## tabPanel "App"
  ) ##navbarPage
)  ## Shiny UI
   


                   