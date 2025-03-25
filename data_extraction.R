###############################################################################
# Script Name: data_extraction.R
# Description: This script automates the extraction of contact information 
#              (name, INE code, email, phone number) for municipalities 
#              listed on the Spanish Ministry of Finance website.
#
#              It uses PhantomJS via the webdriver package to simulate user
#              interaction and navigate through the hierarchical structure of
#              provinces and municipalities on the website.
#
# Output: - info_ayuntamientos.rds: RDS file with the collected data
#         - info_ayuntamientos.csv: CSV file with the same content
#
# Requirements:
#   - R packages: tidyverse, rvest, janitor, webdriver
#   - PhantomJS installed and accessible in your system path
#
# Author: Gabriel C. Caseiro (gabrielcaseiro99@gmail.com)
# Date: 25-03-2025
###############################################################################

# Load necessary libraries
library(tidyverse)    # For data manipulation
library(rvest)        # For web scraping and HTML parsing
library(janitor)      # For data cleaning (not used explicitly here)
library(webdriver)    # For controlling PhantomJS browser automation

# Initialize an empty object to store the results
dt <- NULL

# Start PhantomJS process
pjs <- run_phantomjs()

# Create a new browser session using PhantomJS
ses <- Session$new(port = pjs$port)

# Navigate to the main page of the website
ses$go("https://serviciostelematicosext.hacienda.gob.es/sgcief/BDGEL/aspx/default.aspx") 

# Find and click the "Enter" button to access the next page
element <- ses$findElement(css = "#_ctl0_PlaceHolderContenido_BTN_Entrar")
element$click()

# Get the page source and extract the list of provinces
prov_list <- ses$getSource()

prov_list <- prov_list %>% 
  read_html() %>% 
  html_nodes('a') %>% 
  html_attr('id')

# Keep only the IDs related to provinces
prov_list <- prov_list[grepl('Contenido_ListaDelegaciones', prov_list)]

##### Loop over provinces

for (j in 1:length(prov_list)) {
  
  # Go back to the initial page
  ses$go("https://serviciostelematicosext.hacienda.gob.es/sgcief/BDGEL/aspx/default.aspx") 
  
  # Click the "Enter" button again
  element <- ses$findElement(css = "#_ctl0_PlaceHolderContenido_BTN_Entrar")
  element$click()
  
  # Click on the current province in the list
  element <- ses$findElement(css = paste0('#', prov_list[j]))
  element$click()
  
  # Get the list of municipalities within the selected province
  mun_list <- ses$getSource()
  
  mun_list <- mun_list %>% 
    read_html() %>% 
    html_nodes('a') %>% 
    html_attr('id')
  
  # Keep only the IDs related to municipalities
  mun_list <- mun_list[grepl('ListadoEntes', mun_list)]
  
  # Loop over municipalities
  for (i in 1:length(mun_list)) {
    
    # Print progress info
    print(paste('prov', j, 'mun', i, 'of', length(mun_list)))
    
    # Click on the current municipality
    element <- ses$findElement(css = paste0('#', mun_list[i]))
    element$click()
    
    Sys.sleep(1)  # Wait a second for the page to load
    
    # Click on the "Consult" link to get more detailed info
    element <- ses$findElement(css = "#_ctl0_PlaceHolderContenido_lnkConsultar")
    element$click()
    
    Sys.sleep(1)  # Wait a second for the page to load
    
    # Get the page source with detailed information
    info <- ses$getSource()
    info <- read_html(info)
    
    # Extract name, INE code, email, and phone number
    info_n <- info %>% 
      html_node('#_ctl0_PlaceHolderContenido_nomcorpN') %>% 
      html_attr('value')
    
    info_ine <- info %>% 
      html_node('#_ctl0_PlaceHolderContenido_codigoINE') %>% 
      html_attr('value')
    
    info_e <- info %>% 
      html_node('#_ctl0_PlaceHolderContenido_emailN') %>% 
      html_attr('value')
    
    info_tel <- info %>% 
      html_node('#_ctl0_PlaceHolderContenido_tfnoN') %>% 
      html_attr('value')
    
    # Store the extracted information in a data frame
    info <- data.frame(
      name = info_n,
      ine = info_ine,
      email = info_e,
      tel = info_tel
    )
    
    # Append the current municipality's info to the main dataset
    dt <- bind_rows(dt, info)
    
    # Clean up temporary objects related to 'info'
    rm(list = ls(pattern = 'info'))
    
    # Click the "Back" buttons to return to the list of municipalities
    element <- ses$findElement(css = "#_ctl0_PlaceHolderContenido_volver")
    element$click()
    
    Sys.sleep(1)
    
    element <- ses$findElement(css = "#_ctl0_PlaceHolderContenido_cmdVolver")
    element$click()
    
    Sys.sleep(1)
  }
  
  # Remove the list of municipalities before moving to the next province
  rm(mun_list)
}

# End the browser session and kill the PhantomJS process
ses$delete()
pjs$process$kill()

# Save the final dataset to RDS and CSV formats
saveRDS(dt, 'info_ayuntamientos.rds')
write.csv2(dt, 'info_ayuntamientos.csv', row.names = F)

rm(list = ls())

