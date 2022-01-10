library(tidyverse)
library(rvest)
library(RSelenium)
library(stringr)
library(openxlsx)
library(readxl)
library(magrittr)

# Helper Functions ---------------------------------------------------------------

# Function to specify the time in seconds to wait before executing the next line of code

wait <- function(sec){
  
  for (i in 1:sec){
    
    date_time<-Sys.time()
    
    while((as.numeric(Sys.time()) - as.numeric(date_time))<2.5){} #dummy while loop
  }
  
}

# Function to Extract Table 

extract_table <- function(tbl){
  
  raw_data <- tbl %>% 
    
    html_nodes(".jss291.jss287") %>% 
    
    html_table() 
  
  return(raw_data[[1]])
  
}

# Function to Extract Project Links

extract_links <- function(html){
  
  html %>%
    
    html_nodes(xpath = "//td/a") %>% 
    
    html_attr("href") %>% 
    
    as.data.frame() %>% 
    
    magrittr::set_colnames("Link") %>% 
    
    mutate(Link = paste0("https://registry.goldstandard.org", Link)) %>% 
    
    distinct(Link)
  
}


# Starting a remote selenium server and remote driver(browser) ----------------------------------

# We are using chrome, but other browsers like firefox are supported

# Go to https://chromedriver.chromium.org/downloads to determine the chromedriver version to use

rD <- rsDriver(browser = "chrome",
               port = as.integer(10),  # You can use any number here
               chromever = "92.0.4515.107")  # This is the chromedriver version, which is dependent on your chrome browser version

remDr <- rD$client

# Navigating the remote driver to the website of interest ------------------

base_url_gs <- "https://registry.goldstandard.org/projects"

remDr$navigate(base_url_gs)

wait(10)

# Selecting the Page Source -----------------------------------------------

nodes <- read_html(remDr$getPageSource()[[1]])

# Extracting The Number of Pages ----------------------------------------------------

raw_pages <- nodes %>% 
  
  html_nodes(".jss374") %>% 
  
  html_text()

last_page <- as.numeric(str_extract(raw_pages, "[0-9]*$"))

# Looping through all Pages, appending the table after each iteration -----------------------------------------

# Initial values
i <-  1

data_gs <- data.frame()

while (i <= last_page) {
  
  # Navigating the remote driver to the next page 
  url <- paste0(base_url_gs, "?q=&page=",i)
  remDr$navigate(url)
  
  # Selecting the Page Source
  nodes <- read_html(remDr$getPageSource()[[1]])
  
  # Extracting the table
  data_inter <- extract_table(nodes)
  
  # Iterating until page is fully loaded
  fully_loaded <- apply(data_inter[1], 2, function(x) sum(str_detect(x, "Loading"), na.rm = TRUE))
  
  repeat{
    
    if(fully_loaded){
      
      nodes <- read_html(remDr$getPageSource()[[1]])
      
      links <- extract_links(nodes)
      
      data_inter <- extract_table(nodes)
      
      fully_loaded <- apply(data_inter[1], 2, function(x) sum(str_detect(x, "Loading"), na.rm = TRUE))
      
    }else{
      
      break
      
    }
    
    
  }
  
  #Extracting Links
  links <- extract_links(nodes)
  
  # Replacing empty values with NA and removing empty rows and columns and adding Project Links (html format)
  data_inter <- data_inter %>% 
    
    mutate_all(~na_if(., "")) %>% 
    
    janitor::remove_empty(c("cols", "rows")) %>% 
    
    bind_cols(links) %>% 
    
    mutate(Link_html = paste0("<a href=",Link,">VIEW</a>")) 
  
  # Binding with previous page 
  data_gs <- bind_rows(data_gs, data_inter)
  
  cat(paste("Successfully extracted table in page", i, "\n"))
  
  #Next Loop
  i = i+1
  
}

# Closing the server and remote driver ------------------------------------------------------

remDr$close()
rD$server$stop()

# Exporting File ----------------------------------------------------------

save_loc_gs <- "R exports/Gold Standard Projects.xlsx"

write.xlsx(list("Data" = data_gs), save_loc_gs, zoom = 85)
