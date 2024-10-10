# Please refer to '[Accessing_BigQuery_DB.R](https://github.com/SAFEHR-data/ramses-package/blob/Zsenousy/32-access-and-clean-data-tables-extracted-from-BigQuery-DB/R/Accessing_BigQuery_DB.R) to learn how to generate extract of drug_exposure and concept tables. The resulted data tables will be uncleaned and will require further cleaning as shown here in this script
# Load necessary library
library(readr)


# Step 1: Read the drug exposure data
drug_exposure <- read_delim("../data/OMOP/uncleaned_drug_exposure.csv", delim = " ")


# Step 2: Check the structure of the data
str(drug_exposure)

# Step 3: Remove the first column (index values)
drug_exposure <- drug_exposure[, -1]

# Step 4: Rename columns due to the removal of the first column in the previous step. This process is done due to the shift occurred in column values.
colnames(drug_exposure) <- c(
  "drug_type_concept_id", "stop_reason", "refills", "quantity", 
  "days_supply", "sig", "route_concept_id", "lot_number", 
  "provider_id", "visit_occurrence_id", "visit_detail_id", 
  "drug_source_value", "drug_source_concept_id", "route_source_value", 
  "dose_unit_source_value", "drug_exposure_id", "person_id", 
  "drug_concept_id", "drug_exposure_start_date", 
  "drug_exposure_start_datetime", "drug_exposure_end_date", 
  "drug_exposure_end_datetime", "verbatim_end_date"
)

# Step 5: Add a new column with NA for 'verbatim_end_date'
drug_exposure$verbatim_end_date <- NA

# Step 6: Replace "NA NA" in 'drug_exposure_end_datetime' with actual NA
drug_exposure$drug_exposure_end_datetime[drug_exposure$drug_exposure_end_datetime == "NA NA"] <- NA

# Step 7: Save the cleaned data to a CSV file
write_csv(drug_exposure, "../data/OMOP/cleaned_drug_exposure.csv")
