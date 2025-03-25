# Spain Municipality Contact Info Scraper

This project contains an R script that automates the extraction of contact information for Spanish municipalities from the Ministry of Finance's [BDGEL website](https://serviciostelematicosext.hacienda.gob.es/sgcief/BDGEL/aspx/default.aspx).

## Files

- `scrape_hacienda_data.R`: Main R script that performs the scraping using PhantomJS and the `webdriver` package.
- `info_ayuntamientos.rds`: Output data in RDS format containing municipality name, INE code, email, and phone number.
- `info_ayuntamientos.csv`: The same output saved as a CSV (semicolon-separated, compatible with Excel).

## Requirements

Make sure the following R packages are installed:
- `tidyverse`
- `rvest`
- `janitor`
- `webdriver`

Additionally, you must have **PhantomJS** installed and accessible via your system's PATH.

## Usage

Run the script in R:

```r
source("scrape_hacienda_data.R")
