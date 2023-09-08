# install.packages(c("httr", "jsonlite", "tidyverse", "sqldf"))
# install.packages("vscDebugger")

# The httr library provides the web programming interface we will use to access 
# the web API.
library(httr)

# The jsonlite library provides tools to manipulate the JSON data that is
# returned by the web API.
library(jsonlite)

# Universally useful library
library(tidyverse)

# The sqldf library will be use to join data frames because it handles any
# type conversions without additional code. You could also use dplyr from 
# the tidyverse or other methods, if you prefer.
library(sqldf)

# The DT library provides nice table formatting for viewing data frames
library(DT)

# Make a web GET() request to the API
# Request 1 (n=1) record from the master file (1 also happens to be the default)
# Note that the API we are calling limits us to a maximum of 1000 records
# Status 200 is good. Anything else is an error.
response <- GET("http://161.35.113.24:8999/master?n=1")
print(response)

# View the raw data which was returned
print(response$content)

# View the JSON data without any display formatting
print(rawToChar(response$content))

# View the JSON data as a list
registration_data <- data.frame(fromJSON(rawToChar(response$content)))
print(registration_data)

# Make another request to the API, this time for 10 records
response <- GET("http://161.35.113.24:8999/master?n=1000")
print(response)

# View the JSON data as a list
registration_data <- data.frame(fromJSON(rawToChar(response$content)))
print(registration_data)


# In the registration file, the following fields are most interesting to us:
# The N.NUMBER column is the registration number for each aircraft.
# The MFR.MDL.CODE is the aircraft manufacturer's aircraft model code.
# The ENG.MDL.CODE is the aircraft engine manufacturer's engine model code.
# The NAME is the name of the aircraft's registered owner.
# The address information is the registered owner's permanent address.
# The EXPIRATION.DATE is the aircraft's registration expiration date.

# We would like have one dataframe that combines the aircraft registration information,
# and the corresponding aircraft and engine information as well. This will allow us to
# answer basic questions about registered aircraft.


# Get the aircraft model information from the api
response <- GET("http://161.35.113.24:8999/aircraft")
print(response)

# View the JSON data as a list
aircraft_data <- data.frame(fromJSON(rawToChar(response$content)))
print(head(aircraft_data))

# In the aircraft reference file, the following fields are most interesting to us:
# The CODE is the aircraft manufacturer's aircraft model code.
# The MFR is the aircraft manufacturer's name.
# The MODEL is the aircraft model.


# Get the engine model information from the api
response <- GET("http://161.35.113.24:8999/engine")
print(response)

# View the JSON data as a list
engine_data <- data.frame(fromJSON(rawToChar(response$content)))
print(head(engine_data))

# In the engine reference file, the following fields are most interesting to us:
# The CODE is the engine manufacturer's engine model code.
# The MFR is the engine manufacturer's name.
# The MODEL is the engine's model number.


# We will use the sqldf libary  to join the three datasets into one combined set.
# We will join the registration_data$MFR.MDL.CODE to the aircraft_data$CODE.
# We will join the registration_data$ENG.MDL.CODE to the engine_data$CODE.

# Rename the MFR.MDL.CODE column to avoid issues with periods in the column name
names(registration_data)[names(registration_data) == 'MFR.MDL.CODE'] <- 'ManufacturerCode'

print(colnames(registration_data))

# Use the sqldf library to use SQL to join the registration and aircraft data frames.
# This is easier because it handles any column type issues that can
# be caused by R's dynamic typing. 
registration_data <- sqldf(
  "SELECT * 
     FROM registration_data
    LEFT JOIN aircraft_data ON registration_data.ManufacturerCode = aircraft_data.Code;")

# Look at the first few records to make sure the aircraft model information has
# successfully been added to the end of the data frame.
print(head(registration_data))


# Rename the ENG.MDL.MDL column to avoid issues with periods in the column name
names(registration_data)[names(registration_data) == 'ENG.MFR.MDL'] <- "EngineCode"

# Use the sqldf libary to use SQL to join the registration and engine data frames.
registration_data <- sqldf(
  "SELECT * 
     FROM registration_data
    LEFT JOIN engine_data ON registration_data.EngineCode = engine_data.Code;")

# Look at the records to make sure the engine information has
# successfully been added to the end of the data frame.
datatable(registration_data, options = list(pageLength = 100))
