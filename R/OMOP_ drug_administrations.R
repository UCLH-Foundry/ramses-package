library(dplyr)
library(DBI)
library(AMR)

# Set data file names
drug_exposure_file <- "data/OMOP/table_drug_exposure_10000.csv"
concept_file <- "data/OMOP/table_concept_filter_drug_route_unit.csv"


# Load the data
durg_exposure_data <- read.csv(drug_exposure_file)
concept_data <- read.csv(concept_file)
