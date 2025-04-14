# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=2) {
  stop("Two arguments expected.n", call.=FALSE)
} else {
  directory = args[1]
  output_directory = args[2]
}
print(directory)
print(output_directory)
# Create the output directory if it doesn't exist
if (!dir.exists(output_directory)) {
  dir.create(output_directory, recursive = TRUE)
}

# List all .rds files in the directory
rds_files <- list.files(path = directory, pattern = "\\.rds$", full.names = TRUE)
print(length(rds_files))
# Initialize a list to store the countries from each file
var_list <- vector("list", length(rds_files))

# Loop through each .rds file and extract the countries
for (i in seq_along(rds_files)) {
  print(i)
  #print(rds_files[i])
  # Read the .rds file
  data <- readRDS(rds_files[i])
  
  # Extract the countries from the 'coefficient' variable
  countries <- names(data$coeff)

  # Store the countries in the list
  var_list[[i]] <- countries
}

# Find the union of countries across all files
all_countries <- Reduce(union, var_list)

# Find the intersection of countries across all files
shared_vars <- Reduce(intersect, var_list)

# Determine countries not shared by all files
not_shared_countries <- setdiff(all_countries, shared_vars)




# Loop through each .rds file again and save the reduced data in the output directory
for (i in seq_along(rds_files)) {
  print(i)
  
  # Read the .rds file
  data <- readRDS(rds_files[i])

  shared_positions <- match(shared_vars, names(data$coeff))
  
  data$coeff <- data$coeff[shared_positions]
  
  # Reduce the 'coefficient' variable to only include the shared countries
  #data$coeff <- data$coeff[names(data$coeff) %in% shared_vars]
  data$tstats <- data$tstats[shared_positions]
  data$tpvals <- data$tpvals[shared_positions]

  data$xx <- data$xx[, shared_positions]
  data$covar_coefs <- data$covar_coefs[shared_positions, shared_positions]
   
  # Get the original file name
  original_file_name <- basename(rds_files[i])

  # Save the reduced data to a new .rds file in the output directory
  saveRDS(data, file = file.path(output_directory, original_file_name))
}

# Print the countries not shared by all files
print("Countries not shared by all files:")
print(length(not_shared_countries))

# Print the shared countries
print("Variables shared by all files:")
print(length(shared_vars))

# Print a message indicating the process is complete
print("Reduced .rds files have been saved in the output directory.")

quit()