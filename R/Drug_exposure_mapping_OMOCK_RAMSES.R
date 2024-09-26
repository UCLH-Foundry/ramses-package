# Load the necessary libraries
library(Ramses)
library(omock)
library(dplyr)
library(AMR)  # For drug name mapping
library(DBI)

# Connect to local database for Ramses
ramses_db <- connect_local_database("ramses-db.duckdb")

# Generate mock OMOP CDM data ...further change to CSV files...
cdm <- mockCdmReference() |>
  mockPerson() |>
  mockObservationPeriod() |>
  mockConditionOccurrence(recordPerson = 10) |>
  mockDrugExposure(recordPerson = 40) |>
  mockMeasurement(recordPerson = 5) |>
  mockDeath(recordPerson = 1)

# Extract the drug_exposure table from mock OMOP CDM data
omop_drug_exposure <- cdm$drug_exposure

# Check structure of the drug_exposure table to identify necessary columns
str(omop_drug_exposure)

# If dose_value column is missing, use dose if available or mock random values
if (!"dose_value" %in% colnames(omop_drug_exposure)) {
  omop_drug_exposure$dose_value <- ifelse(
    "dose" %in% colnames(omop_drug_exposure), 
    omop_drug_exposure$dose, 
    runif(nrow(omop_drug_exposure), 1, 1000)  # Mock random dose values
  )
}

# If route_concept_id column is missing, mock some values for demonstration purposes
if (!"route_concept_id" %in% colnames(omop_drug_exposure)) {
  set.seed(123)
  route_options <- c(4132165, 4122237)  # Example: IV and ORAL concept IDs
  omop_drug_exposure$route_concept_id <- sample(route_options, nrow(omop_drug_exposure), replace = TRUE)
}

# If dose_unit_concept_id column is missing, mock some values or bypass this step
if (!"dose_unit_concept_id" %in% colnames(omop_drug_exposure)) {
  omop_drug_exposure$dose_unit_concept_id <- NA  # Set to NA if not available
}

# Map OMOP fields to RAMSES fields
omop_to_ramses <- omop_drug_exposure %>%
  transmute(
    # Mapping OMOP person_id to RAMSES patient_id
    patient_id = person_id,
    
    # Drug exposure ID in OMOP maps to prescription_id in RAMSES
    prescription_id = drug_exposure_id,
    
    # Drug exposure start and end date in OMOP maps to prescription_start and prescription_end in RAMSES
    prescription_start = drug_exposure_start_date,
    prescription_end = drug_exposure_end_date,
    
    # Use AMR package to map OMOP drug_concept_id to RAMSES tr_DESC (drug name)
    tr_DESC = ifelse(
      !is.na(AMR::ab_name(drug_concept_id)), 
      AMR::ab_name(drug_concept_id), 
      "Unknown drug"  # Fallback for unmapped drug_concept_id
    ),
    
    # Mapping route_concept_id to RAMSES route (IV or ORAL)
    route = case_when(
      route_concept_id == 4132165 ~ "IV",  # Intravenous route
      route_concept_id == 4122237 ~ "ORAL",  # Oral route
      TRUE ~ NA_character_  # If unknown, set to NA
    ),
    
    # Map dose_value from OMOP to RAMSES dose
    dose = dose_value,
    
    # Map dose_unit_concept_id to RAMSES units (g, mg) if available
    units = case_when(
      dose_unit_concept_id == 8576 ~ "g",  # Grams
      dose_unit_concept_id == 8577 ~ "mg",  # Milligrams
      TRUE ~ NA_character_
    ),
    
    # Calculate duration between start and end dates
    duration_days = as.numeric(difftime(prescription_end, prescription_start, units = "days"))
  )

# View the final mapped data from OMOP to RAMSES
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

# Load the data into the Ramses database
dbWriteTable(ramses_db, "drug_prescriptions", omop_to_ramses, overwrite = TRUE)

# Verify the data was loaded correctly
loaded_data <- dbReadTable(ramses_db, "drug_prescriptions")
print(loaded_data)

# Close the database connection
dbDisconnect(ramses_db)
