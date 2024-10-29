#This Script is used to Generate Synthetic Data for Drug_exposure and Concept tables:
#Author: Zakaria Senousy (ARC - UCL)
library(dplyr) 

#check current working directory
if (basename(getwd()) == "ramses-package") {
  wd_is_ramses <- TRUE
} else {
  wd_is_ramses <- FALSE
}

# Function to generate synthetic concept table
generate_concept_table <- function() {
  # Generate synthetic concept table with full drug names and different routes
  concept <- data.frame(
    concept_id = 1:20,
    #Randomly generated drug_names
    concept_name = c(
      "Amoxicillin 250 MG Oral Capsule",            
      "Clavulanic Acid 125 MG Oral Tablet",        
      "Piperacillin 1000 MG Injection",             
      "Sulfamethoxazole 400 MG Oral Tablet",        
      "Trimethoprim 80 MG Oral Tablet",             
      "Ibuprofen 200 MG Oral Tablet",               
      "Paracetamol 500 MG Oral Tablet",             
      "Aspirin 81 MG Oral Tablet",                  
      "Metformin 500 MG Oral Tablet",               
      "Lisinopril 10 MG Oral Tablet",               
      "Fluticasone 50 MCG Inhalation Aerosol",      
      "Albuterol 90 MCG Inhalation Aerosol",        
      "Hydrocortisone 1% Topical Cream",           
      "Lidocaine 5% Topical Patch",                 
      "Epinephrine 0.3 MG Subcutaneous Injection",  
      "Insulin Glargine 100 Units/ML Subcutaneous Solution", 
      "Gentamicin 0.3% Ophthalmic Drops",           
      "Methylprednisolone 125 MG Intramuscular Injection",  
      "Ondansetron 4 MG Oral Disintegrating Tablet",  
      "Ketorolac 30 MG Intravenous Injection"
    ),
    domain_id = rep("Drug", 20),
    vocabulary_id = rep("RxNorm", 20),
    concept_class_id = c("Clinical Drug", "Clinical Drug", "Clinical Drug", "Clinical Drug", "Clinical Drug",
                         "Clinical Drug", "Clinical Drug", "Clinical Drug", "Clinical Drug", "Clinical Drug",
                         "Dose Form", "Dose Form", "Dose Form", "Dose Form", "Dose Form", 
                         "Dose Form", "Dose Form", "Dose Form", "Clinical Drug", "Clinical Drug"),
    standard_concept = rep("S", 20),
    concept_code = c("AMC250", "CLA125", "PIP1000", "SMX400", "TMP80", 
                     "IBU200", "PAR500", "ASP81", "MET500", "LIS10",
                     "FLU50", "ALB90", "HC1TOP", "LIDO5", "EPI03", 
                     "INS100", "GEN03", "MPRED125", "OND4ODT", "KETO30IV"),
    valid_start_date = rep(as.Date("2023-01-01"), 20), 
    valid_end_date = rep(as.Date("2023-12-31"), 20),   
    invalid_reason = rep("None", 20)                      
  )

  # Load drug names from file if available
  if (wd_is_ramses & file.exists("data/OMOP/Drug_Names.csv")) {
      drug_names_sheet <- read.csv("data/OMOP/Drug_Names.csv")
      concept_name = drug_names_sheet$Drug_Name
      concept$concept_name = concept_name
      print("Drug names loaded from file.")
    } else {
    print("Drug names loaded from hard coded randomly generated names.")
    }
  
  return(concept)
}


# Define a function to extract the route from concept_name and assign route_concept_id
assign_route_id <- function(concept_name) {
  # Define mapping for routes and their corresponding numeric IDs
  route_mapping <- list(
    ORAL = 1,
    IV = 2,
    IM = 3,
    SC = 4,
    TOPICAL = 5,
    INHAL = 6,
    OTHER = 7  # Fill for unrecognized routes
  )
  
  # Determine the route based on keywords in concept_name
  if (grepl("Oral", concept_name, ignore.case = TRUE)) {
    return(route_mapping$ORAL)
  } else if (grepl("Intravenous|IV", concept_name, ignore.case = TRUE)) {
    return(route_mapping$IV)
  } else if (grepl("Intramuscular|IM", concept_name, ignore.case = TRUE)) {
    return(route_mapping$IM)
  } else if (grepl("Subcutaneous|SC", concept_name, ignore.case = TRUE)) {
    return(route_mapping$SC)
  } else if (grepl("Topical", concept_name, ignore.case = TRUE)) {
    return(route_mapping$TOPICAL)
  } else if (grepl("Inhalation|Inhal", concept_name, ignore.case = TRUE)) {
    return(route_mapping$INHAL)
  } else {
    return(route_mapping$OTHER)
  }
}


# Function to generate synthetic drug_exposure table
generate_drug_exposure <- function(num_records = 100) {
  # Set seed for reproducibility
  set.seed(123)
  
  # Mapping drug_concept_id to the corresponding dose unit
  dose_units <- c(
    "mg", "mg", "mg", "mg", "mg", 
    "mg", "mg", "mg", "mg", "mg",  # First 10 concepts (mostly oral)
    "mcg", "mcg", "g", "g", "mg", 
    "units/mL", "mg", "mg", "mg", "mg"  # Next 10 concepts (includes topical, injection)
  )  # Aligned with 20 drug concepts
  
  
  # Generate the concept table
  concept_table <- generate_concept_table()
  
  # Generate synthetic drug_exposure table with increased records
  drug_exposure <- data.frame(
    drug_exposure_id = 1:num_records,
    person_id = sample(1:20, num_records, replace = TRUE),  # 20 unique persons
    drug_concept_id = sample(1:20, num_records, replace = TRUE),  # Randomly choose from 20 concepts
    drug_exposure_start_date = sample(seq(as.Date("2023-01-01"), as.Date("2023-10-01"), by="day"), num_records, replace = TRUE),
    quantity = sample(1:5, num_records, replace = TRUE),  # Random quantity between 1 and 5
    dose_unit_source_value = dose_units[sample(1:20, num_records, replace = TRUE)],  # Assign directly from dose_units based on concept
    sig = sample(c("Take one tablet daily", "Take two tablets twice a day", 
                   "Take three tablets every six hours", "As needed"), num_records, replace = TRUE)  
  )
  
  # Merge to include concept names
  drug_exposure <- merge(drug_exposure, concept_table, by.x = "drug_concept_id", by.y = "concept_id", all.x = TRUE)
  
  # Assign route_concept_id using the assign_route_id function
  drug_exposure$route_concept_id <- sapply(drug_exposure$concept_name, assign_route_id)
  
  # Patterns to standardize the "sig" field
  patterns <- c(
    "daily" = "once a day|daily|1 time a day",
    "twice daily" = "twice a day|2 times a day|two tablets twice a day",
    "three times daily" = "three times a day|3 times a day|three tablets every six hours",
    "four times daily" = "four times a day|4 times a day",
    "every other day" = "every other day|every second day",
    "weekly" = "weekly|once a week",
    "as needed" = "as needed|prn|if necessary"
  )
  
  # Function to apply pattern matching and replace sig values
  standardize_sig <- function(sig, patterns) {
    for (standardized in names(patterns)) {
      # Apply pattern replacement based on regex matches
      sig <- gsub(patterns[standardized], standardized, sig, ignore.case = TRUE)
    }
    return(sig)
  }
  
  # Apply the function to the 'sig' column in drug_exposure
  drug_exposure <- drug_exposure %>%
    mutate(sig = standardize_sig(sig, patterns))
  
  # Ensure end dates are always after start dates
  drug_exposure <- drug_exposure %>%
    mutate(drug_exposure_end_date = drug_exposure_start_date + sample(1:30, num_records, replace = TRUE))  # Add random days between 1 to 30 to the start date
  
  # Rearrange columns to ensure drug_exposure_end_date comes after drug_exposure_start_date
  drug_exposure <- drug_exposure %>%
    select(drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, 
           quantity, dose_unit_source_value, route_concept_id, sig)
  
  return(drug_exposure)
}

#Generate concept data
concept_table <- generate_concept_table()

# Check the resulting concept data
print(concept_table)

# Write the concept data to a CSV file
if (wd_is_ramses) {
  write.csv(concept_table, "data/OMOP/generated_concept.csv", row.names = FALSE)
} else {
  print("Please run this script from the ramses-package directory.")
}

# Generate drug exposure data
drug_exposure_data <- generate_drug_exposure(100)

# Check the resulting drug exposure data
print(drug_exposure_data)


# Write the drug exposure data to a CSV file
if (wd_is_ramses) {
  write.csv(drug_exposure_data, "data/OMOP/generated_drug_exposure.csv", row.names = FALSE)
} else {
  print("Please run this script from the ramses-package directory.")
}
