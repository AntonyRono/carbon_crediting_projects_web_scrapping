library(tidyverse)
library(rvest)
library(RSelenium)
library(stringr)
library(openxlsx)
library(magrittr)


# Helper Functions --------------------------------------------------------

# Function to specify the time in seconds to wait before executing the next line of code

wait <- function(sec){
  
  for (i in 1:sec){
    
    date_time<-Sys.time()
    
    while((as.numeric(Sys.time()) - as.numeric(date_time))<2.5){} #dummy while loop
  }
  
}

# Setting Download Options and Directory ----------------------------------

chrome_options <- list(
  chromeOptions = 
    list(prefs = list(
      "profile.default_content_settings.popups" = 0L,
      "download.prompt_for_download" = FALSE,
      "download.default_directory" = str_replace_all(paste0(getwd(),"/R exports"),"/","\\\\"))
    )
    )


# Starting a remote selenium server and remote driver(browser) ----------------------------------

# We are using chrome, but other browsers like firefox are supported

# Go to https://chromedriver.chromium.org/downloads to determine the chromedriver version to use

rD <- rsDriver(browser = "chrome",
               port = as.integer(15),  # You can use any number here
               chromever = "92.0.4515.107",  # This is the chromedriver version, which is dependent on your chrome browser version
               extraCapabilities = chrome_options)

remDr <- rD$client

# Navigating the remote driver to the website of interest ------------------

base_url_verra <- "https://registry.verra.org/app/search/VCS/All%20Projects"

remDr$navigate(base_url_verra)

wait(5)

# Click on search ---------------------------------------------------------

# find button
button <- remDr$findElement(using = 'css selector', "button.btn.btn-primary")

# click button
button$clickElement()

# wait

wait(7)


# Scrolling up ------------------------------------------------------------

webElem <- remDr$findElement("css", "body")

webElem$sendKeysToElement(list(key = "home"))

wait(1)

# Click on Download -------------------------------------------------------

# Multiple attempts to download since it fails at times

repeat{
  
  if(file.exists("R exports/allprojects.xlsx")){
    
    break
    
  }else{
    
    # find button
    button1 <- remDr$findElement(using = 'css selector', "i.fas.fa-file-excel.fa-lg.pr-2")
    
    # click button
    button1$clickElement()
    
    # wait
    wait(5)
    
    
  }

  
  
}

# Closing the server and remote driver ------------------------------------------------------

remDr$close()
rD$server$stop()

# Renaming File -----------------------------------------------------------

path <- "R exports/"

file.rename(from = list.files(path, pattern = "allprojects", full.names = TRUE), 
            to = paste0(path,"VERRA Projects.xlsx"))
