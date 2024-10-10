# Load necessary libraries
library(dplyr)
library(readr)

# 1. Reading the data from the CSV file
concept <- read_delim("../data/OMOP/uncleaned_concept.csv", delim = " ", quote = '"', col_names = TRUE, trim_ws = TRUE)


# 2. The `mutate()` function from the `dplyr` package is used to modify the `invalid_reason` column. It first removes quotes using `gsub()`, 
# then extracts the date (before the first space) and the code (after the first space), 
# creating new columns `invalid_reason_before` and `invalid_reason_after`. Finally, the original `invalid_reason` column is removed using `select(-invalid_reason)`.

concept <- concept %>%
    mutate(
        invalid_reason = gsub("\"", "", invalid_reason),  # Remove quotes from invalid_reason
        invalid_reason_date = sub(" .*", "", invalid_reason),  # Extract date before space
        invalid_reason_code = sub(".* ", "", invalid_reason)  # Extract code after space
        ) %>%
        select(-invalid_reason)  # Drop the original invalid_reason column


# 3.The `concept_id` column is removed from the dataset using `select()`. This column holds index values and not the correct concept ids. That's why it has been removed.
concept <- concept %>% select(-concept_id)


# 4. The `colnames()` function is used to rename the columns. This part reassigns the same names in the correct order after removal of index column in step 3.
colnames(concept) <- c("concept_id", "concept_name", "domain_id", "vocabulary_id", 
                       "concept_class_id", "standard_concept", "concept_code", 
                       "valid_start_date", "valid_end_date", "invalid_reason")


# 5. Converting valid_end_date to Date type
concept$valid_end_date <- as.Date(concept$valid_end_date, format = "%Y-%m-%d")


# 6. Writing the cleaned data back to a new CSV file
write_csv(concept, "../data/OMOP/cleaned_concept.csv")

   