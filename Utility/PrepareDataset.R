## Utility Script to get the NOAA data from 1995 through 2014 (20 years)
##
## The script will download all the TAR files from the NOAA website,
## un-TAR the individual station files, 
## Unzip them
## Load the mean temp data from the Files into a dataframe
## That data frame will be used as the data source for the Shiny App.

## Code was adapted from the example at 
##  http://www.r-bloggers.com/accessing-cleaning-and-plotting-noaa-temperature-data/

setwd("~/Coursera/Data Scientist/9 - Developing Data Products/Course Project")
##setwd("C:/Users/rwokano/Desktop/Course Project")

## Variables
countryfile<-"country-list.txt"
stationfile<-"isd-history.csv"

## setup for multi-threading
library(doParallel)
cl <- makeCluster(as.integer(Sys.getenv('NUMBER_OF_PROCESSORS'))-1)  ##Make a cluster with all but one of the CPU cores available
registerDoParallel(cl)


## Create the data folder
dir.create(paste(getwd(),"/Data",sep=""))

## Get the Country List
download.file(paste("ftp://ftp.ncdc.noaa.gov/pub/data/gsod/",countryfile,sep=""), destfile=paste(getwd(),"/Data/",countryfile,sep=""),method="auto",mode="wb")
countrylist<-read.fwf(paste(getwd(),"/Data/",countryfile,sep=""),widths=c(12,80),skip=2,fill=TRUE,strip.white=TRUE,sep=";",col.names=c("FIPS_ID", "COUNTRY_NM"))

## Get the Location information
download.file(paste("ftp://ftp.ncdc.noaa.gov/pub/data/gsod/",stationfile,sep=""), destfile=paste(getwd(),"/Data/",stationfile,sep=""),method="auto",mode="wb")
stationlist<-read.csv(paste(getwd(),"/Data/",stationfile,sep=""),header=TRUE)

## Add the Country Name to the Station List and create an ID field
stations<-merge(stationlist,countrylist,by.y="FIPS_ID",by.x="CTRY",all.x=TRUE)
stations$ID<-paste(stations$USAF,stations$WBAN,sep="")

## Need to de-dup the stations list
## Only care about the CTRY, Station.Name, State and ID (USAF & WBAN)
stations<-unique(stations)

## define the cols for the raw data files
classes <- c(rep("factor",3),rep("numeric",14),rep("factor",3),rep("numeric",2))


## Download & Unpack the TAR files
for (i in 2010:2014)
{ 
  
  download.file(paste("ftp://ftp.ncdc.noaa.gov/pub/data/gsod/",i,"/gsod_",i,".tar",sep=""),destfile=paste(getwd(),"/Data/","gsod_",i,".tar",sep=""),method="auto",mode="wb")

  ##Extract Measurements
  dir.create(paste(getwd(),"/Data/Files",sep=""))
  untar(paste(getwd(),"/Data/","gsod_",i,".tar",sep=""),exdir=paste(getwd(),"/Data/Files",sep=""))

  ## Define the output data frame
  temperatureData <- data.frame(ID=character(), ObsDate=factor(), TempC=numeric(), Temp=numeric())
  
  ## Process the individual files into one data frame with Station ID's and Temps
  files <- list.files(paste(getwd(),"/Data/Files/",sep=""))
  for(j in 1:length(files))
  {
      ## read the file
      newdata <- read.table(gzfile(paste(getwd(),"/Data/Files/",files[j],sep="")),sep="",header=F,skip=1,colClasses=classes)
    
      ## Make sure there is at least 6 months worth of data and at least 12 hours of observations per day
      if(nrow(newdata)>(365/2))
      {
          ST1 <- data.frame(Temp=newdata$V4,TempC=(newdata$V4-32)/1.8,Tcount=newdata$V5,ObsDate=newdata$V3,ID=paste(newdata$V1,newdata$V2,sep=""))
          ST2 <- ST1[ST1$Tcount>12,]
          if(nrow(ST2)>0)
          {
              ST3 <- data.frame(ID=ST2$ID, ObsDate=ST2$ObsDate, TempC=ST2$TempC, Temp=ST2$Temp)
              temperatureData<-rbind(temperatureData,ST3)
          }
      }
  }
  ## Convert the Field to a Date datatype
  temperatureData$ObsDate<-as.Date(temperatureData$ObsDate, format = "%Y%m%d")
  ## Add in the Station Data
  temperatureData<-merge(stations,temperatureData,by="ID",all.y=TRUE)
  
  ## Add columns for Month and Year, allows server to run faster later
  temperatureData$ObsYear<-format.Date(temperatureData$ObsDate,"%Y")
  temperatureData$ObsMonth<-format.Date(temperatureData$ObsDate,"%m")
  
  ## Save the combined file
  save(temperatureData,file=paste(getwd(),"/temperatureData_",i,".rda",sep=""))
  ## remove the dataframe before the next iteration
  rm(temperatureData)
  
  ## Delete the unzipped files.
  unlink(paste(getwd(),"/Data/Files",sep=""),recursive = TRUE)    

}

## Combine all the files into 1 dataset for the server to use.
## For speed purposes, drop all columns server is not using as well
files <- list.files(paste(getwd(),"/",sep=""),pattern="temperatureData_")
for(j in 1:length(files))
{
  load(files[j])
  print(paste("Processing File # ",j,sep=""))
  ## Subset for just US and a State Code
  temperatureData <- subset(temperatureData, CTRY=="US" & STATE != "")
  if (j==1)
  {
    masterData<-temperatureData
  }else
  {
    masterData<-rbind(masterData,temperatureData)
  }
}
keeps <- c("ID","CTRY","STATE","COUNTRY_NM","ObsDate","Temp","TempC","ObsMonth","ObsYear")
masterData <- subset(masterData,select=keeps)
save(masterData,file=paste(getwd(),"/preparedData.rda",sep=""))

## Create a unique list of States from the data, for the server to
## populate a dropdown with.
## Load a list of states to use in the UI
states <- as.character(masterData$STATE)
stateList <- unique(states)
stateList<-sort(stateList)
save(stateList,file=paste(getwd(),"/stateList.rda",sep=""))

## Do the same with the years
yearList<-sort(unique(masterData$ObsYear))
save(yearList,file=paste(getwd(),"/yearList.rda",sep=""))