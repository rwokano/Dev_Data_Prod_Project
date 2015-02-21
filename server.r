library(shiny)
library(ggplot2)

## Load the preprocessed datasets (Prepared by the UTILTY program)
load("preparedData.rda")

## Load a list of states to use in the UI 
load("stateList.rda")

## Load the list of the Years in the data
load("yearList.rda")

shinyServer
(
    function(input, output) 
    {
      ## Dynamically Populate the State List in the UI
      output$states <- renderUI({
            selectInput("statelist","Select a State",choices=c(stateList))
      })
      
      ## Dynamically Populate the Year List in the UI
      output$years <- renderUI({
        selectInput("yearlist","Select a Year",choices=c(yearList))
      })
        
      monthInput<-reactive(
      {
        switch(input$month,
               "January" = "01",
               "Feburary" = "02",
               "March" = "03",
               "April" = "04",
               "May" = "05",
               "June" = "06",
               "July" = "07",
               "August" = "08",
               "September" = "09",
               "October" = "10",
               "November" = "11",
               "December" = "12")
      })

               
      datasetSelect<-reactive(
      {
        ## Get the filters the user selected and subset the data
        switch(input$timeChoice,
            "1" = subset(masterData, ObsMonth==monthInput() & 
                           ObsYear==input$yearlist   &
                           STATE==input$statelist),
            "2" = subset(masterData, ObsMonth==monthInput() & 
                           STATE==input$statelist))
      })
      
  
      
      ## For Testing
      output$test<-renderText(input$timeChoice)
      
      
      output$tempPlot <- renderPlot({
        plotdata<-datasetSelect()
        if (is.data.frame(plotdata) & nrow(plotdata)>0){
          agg<-switch(input$degrees,
                      "1" = aggregate(TempC~ObsDate,data=plotdata,mean),
                      "2" = aggregate(Temp~ObsDate,data=plotdata,mean))
          xaxis<-switch(input$timeChoice,
                        "1" = "Observation Date",
                        "2" = "Observation Year")
          ## Create the plot that the user will see
          
          qplot(ObsDate,
                switch(input$degrees,
                  "1" = TempC,
                  "2" = Temp),
                data=agg,
                geom=c("point","smooth"),
                main="Mean Daily Temperatures",
                xlab=xaxis,
                ylab="Mean Temperature")          
        }
      })
      
      output$sampleStats<-renderTable({
        plotdata<-datasetSelect()
        statsData <- data.frame(Desc=character(), Value=numeric())        
        if (is.data.frame(plotdata) & nrow(plotdata)>0){
          if(input$degrees=="1"){
            ## Celsius
            statsData<-rbind(statsData,data.frame(Desc="Lowest Temp", Value=min(plotdata$TempC)))
            statsData<-rbind(statsData,data.frame(Desc="Highest Temp", Value=max(plotdata$TempC)))
            statsData<-rbind(statsData,data.frame(Desc="Average Temp", Value=mean(plotdata$TempC)))
            statsData<-rbind(statsData,data.frame(Desc="Number of observations", Value=nrow(plotdata)))
          }else
          {
            statsData<-rbind(statsData,data.frame(Desc="Lowest Temp", Value=min(plotdata$Temp)))
            statsData<-rbind(statsData,data.frame(Desc="Highest Temp", Value=max(plotdata$Temp)))
            statsData<-rbind(statsData,data.frame(Desc="Average Temp", Value=mean(plotdata$Temp)))
            statsData<-rbind(statsData,data.frame(Desc="Number of observations", Value=nrow(plotdata)))            
          }
          
        }
        statsData
      })
    }
)