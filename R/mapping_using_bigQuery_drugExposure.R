# Load necessary libraries
library(dplyr) # For data manipulation.
library(DBI) # For establishing connection with Database
library(readr) #To read and write CSV files.
library(AMR)  # For drug name mapping
library(AMR)  # For drug name mapping

# Load data from CSV files
drug_exposure <- read_csv("../data/OMOP/cleaned_drug_exposure.csv")
concept <- read_csv("../data/OMOP/cleaned_concept.csv")



# Print the column names to check if they are correct
print(colnames(concept))
# Print the cleaned data to verify everything looks correct
print(head(concept))


# Ensure the relevant columns are available in drug_exposure
print(colnames(drug_exposure))
print(head(drug_exposure))  


#drug_exposure <- drug_exposure %>%
#  left_join(concept, by = c("drug_concept_id" = "concept_id")) %>%
#  rename(drug_name = concept_name) %>%
#  select(-domain_id, -vocabulary_id, -concept_class_id, -standard_concept, -concept_code, 
#         -valid_start_date, -valid_end_date, -invalid_reason)

#Mapping using left join
drug_exposure <- drug_exposure %>%
  left_join(concept, by = c("drug_concept_id" = "concept_id")) %>%
  rename(drug_name = concept_name) %>%  # Rename concept_name to drug_name
  mutate(route = NA)  # Since route_concept_id is NA.

# Remove unnecessary columns from concept table
drug_exposure <- drug_exposure %>%
  select(-domain_id, -vocabulary_id, -concept_class_id, -standard_concept, 
         -concept_code, -valid_start_date, -valid_end_date, -invalid_reason)


# Map 'dose_unit_source_value' directly as units (since 'dose_unit_concept_id' is missing)
if ("dose_unit_source_value" %in% colnames(drug_exposure)) {
  drug_exposure <- drug_exposure %>%
    mutate(units = dose_unit_source_value)  # Map 'dose_unit_source_value' to units
} else {
  drug_exposure$units <- NA  # If 'dose_unit_source_value' is missing, set units as NA
}

# Map drug_exposure fields to RAMSES fields
omop_to_ramses <- drug_exposure %>%
  transmute(
    # Mapping OMOP person_id to RAMSES patient_id
    patient_id = person_id,
    
    # Mapping OMOP drug_exposure_id to RAMSES prescription_id
    prescription_id = drug_exposure_id,
    
    # Start and end dates of drug exposure
    prescription_start = drug_exposure_start_date,
    prescription_end = drug_exposure_end_date,
    
    # Mapping drug_concept_id to RAMSES tr_DESC (drug description) using AMR package
    tr_DESC = ifelse(!is.na(AMR::ab_name(drug_name)), AMR::ab_name(drug_name), "Unknown drug"),
    
    # Route (e.g., IV, Oral) from concept table
    route = route,
    
    # Using 'quantity' as a proxy for dose if 'dose_value' is not available
    dose = quantity,
    
    # Units mapped from 'dose_unit_source_value'
    units = units,
    
    # Calculate duration between start and end dates in days
    duration_days = as.numeric(difftime(prescription_end, prescription_start, units = "days"))
  )

# Display the final mapped data from OMOP to RAMSES
print(omop_to_ramses)

# Validation function for checking mappings
validate_mapping <- function(df) {
  if (all(!is.na(df$tr_DESC))) {
    message("All drugs successfully mapped to RAMSES fields!")
  } else {
    message("Some drug mappings failed. Please check the following:")
    print(df %>% filter(is.na(tr_DESC)))
  }
}

# Run the validation function
validate_mapping(omop_to_ramses)

# Save the final mapped data to a CSV file
write_csv(omop_to_ramses, "../data/OMOP/mapped_drug_prescriptions.csv")


# Print completion message
message("Drug data has been processed and saved successfully.")



# Connect to local DuckDB database for Ramses
#ramses_db <- DBI::dbConnect(RSQLite::SQLite(), dbname = "ramses-db.duckdb")

# Load the data into the Ramses database
#DBI::dbWriteTable(ramses_db, "drug_prescriptions", omop_to_ramses, overwrite = TRUE)

# Verify the data was loaded correctly
#loaded_data <- DBI::dbReadTable(ramses_db, "drug_prescriptions")
#print(loaded_data)

# Close the database connection
#DBI::dbDisconnect(ramses_db)

