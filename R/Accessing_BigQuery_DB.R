# Load required libraries
# bigrquery: Interface to Google BigQuery
# DBI: Database Interface (for general database connectivity)
# gargle: Auth utilities for Google APIs

library(bigrquery)
library(DBI)
library(gargle)

# Step 2: Authenticate connection to BigQuery
# Set the path to the service account key file
sa_key_path <- "path/to/your/key_file"

# Authenticate with BigQuery using the service account key
bq_auth(path = sa_key_path)

# Set your project ID
project_id <- "your_project_id"

# Establish connection to BigQuery using DBI's dbConnect function
# Connect to the public dataset in BigQuery (replace the dataset if needed)
con <- dbConnect(bigquery(), project = project_id, dataset = "bigquery-public-data")

# Step 3: SQL queries for retrieving data
# Query to retrieve data from the drug_exposure table, limiting to 10,000 rows
sql_string1 <- "SELECT * FROM bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure LIMIT 10000"

# Query to retrieve data from the concept table, filtering by specific domain_ids
sql_string2 <- "SELECT * FROM bigquery-public-data.cms_synthetic_patient_data_omop.concept WHERE domain_id IN ('Drug', 'Route', 'Unit')"

# Execute the queries and store the results in data frames
result1 <- dbGetQuery(con, sql_string1)
result2 <- dbGetQuery(con, sql_string2)

# Step 4: Save data to CSV files
# Save the drug_exposure query result to a CSV file
write.table(result1, file = "path/to/your/uncleaned_drug_exposure_file.csv", sep = ",", row.names = FALSE, quote = TRUE)

# Save the concept query result to a CSV file
write.table(result2, file = "../data/OMOP/uncleaned_concept_file.csv", sep = ",", row.names = FALSE, quote = TRUE)


# Close the connection to BigQuery
dbDisconnect(con)