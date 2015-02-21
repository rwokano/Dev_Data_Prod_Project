setwd("C:/Users/rwokano/Desktop/Course Project")
countryfile<-"country-list.txt"
stationfile<-"isd-history.csv"

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

load("temperatureData_1995.rda")
test<-merge(stations,temperatureData,by="ID",all.y=TRUE)
