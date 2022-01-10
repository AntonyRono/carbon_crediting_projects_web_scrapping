library(tidyverse)
library(R.utils)
library(readxl)
library(lubridate)
library(magrittr)

# Helper Functions ---------------------------------------------------------------

# Function To Convert Date Containing Both EPOCH and Normal Date 

convert_to_date <- function(dt){
  
  if(is.na(dt)){
    
    lubridate::NA_Date_
    
  }else if(str_detect(dt, "-")){
    
    as.Date(dt)
    
  }else{
    
    as.Date(as.numeric(dt), origin = "1899-12-30")
    
  }
  
}


# Inputs ------------------------------------------------------------------

# Url of the PAs and PoAs Database

base_url_cdm <- "https://cdm.unfccc.int/Statistics/Public/files/Database%20for%20PAs%20and%20PoAs.xlsx"


# Getting the data --------------------------------------------------------

# We can either import the data into R and then save it as an excel file afterwards, or download it directly from the website

# Advantage of the second approach is that we will be able to access all the information which have been saved in different sheets, as opposed to the first approach where we will only get info on the first sheet


# Approach 1: Importing the data directly into R --------------------------------------------------

## Reading the data from the website

cdm_latest <- openxlsx::read.xlsx(base_url_cdm, sep.names = " ", sheet = "CDM activities", detectDates = FALSE)

## Converting Date Columns to Dates

cdm_latest %<>% 
  
  rowwise() %>% 
  
  mutate_at(vars(matches("(Start)|(End)|(date)|(issuance$)")), convert_to_date) 

## Adding the Project Links

cdm_projects <- cdm_latest %>%
  
  mutate(`Project Link` = paste0("https://cdm.unfccc.int/Projects/Validation/DB/", `Unique project identifier (traceable with Google)`,
                                 "/view.html"),
         
         `Project Link` = paste0("<a href=",`Project Link`,">Link</a>")
  )

## Saving it as an xlsx file

save_loc <- "R exports/CDM Projects Approach 1.xlsx"

openxlsx::write.xlsx(list("Database" = cdm_projects), save_loc, zoom = 85)


# Approach 2: Downloading the data directly ------------------------------------------------------

## We are downloading it directly from the website, rather than saving the one in R, so as to get all the tabs for any reference

download_path <- "R exports"

# Downloading the Database of PAs and PoAs 
downloadFile(url = base_url_cdm, filename = "CDM Projects Approach 2.xlsx",  path = download_path, skip = FALSE, overwrite = TRUE)
