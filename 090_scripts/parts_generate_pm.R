
#+
# :AUTHOR: Franz Schug [fschug@wisc.edu], support and advice Clay. J. Morrow (https://github.com/morrowcj)
# :DATE: 16 Sep. 2024
#
# :Description: Generates a partition matrix for parallel GLS processing based.

# :Parameters:  global_vrt_path - path to full global dataset
#               pm_save_path - path to save partition matrix
#               partition_size - size of each partition
#
## remotePARTS documentation
# (1) https://github.com/morrowcj/remotePARTS
#
## remotePARTS publication
# (1) A. ives, L. Zhu, F. Wang, J. Zhu, C. Morrow, V. Radeloff, 2021, Statistical inference for trends in spatiotemporal data, Remote Sensing of Environment, doi: 10.1016/j.rse.2021.112678
#
# Use at own risk.


# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

library(remotePARTS)
library(data.table)

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=4) {
  stop("Four arguments expected.n", call.=FALSE)
} else {
  num_lines = as.integer(args[1])
  pm_save_path = args[2]
  partition_size = as.numeric(args[3])  # rows
  max_npart = as.numeric(args[4])  # columns
}

START_TIME = Sys.time()

print('Number of lines in file')
print(num_lines)
## generate or load partition matrix of the complete dataset
partition_matrix = sample_partitions(npix = num_lines, partsize = partition_size, npart = NA)
print('Partition matrix completed')

#print(ncol(partition_matrix))
#print(max_npart)

i = (ncol(partition_matrix) / max_npart) + 1
#print(i)

outDir = paste0(pm_save_path)

# Create the directory if it doesn't exist
if (!dir.exists(paste0(pm_save_path, '/rds/'))) {
  dir.create(paste0(pm_save_path, '/rds/'), recursive = TRUE)
}

if (!dir.exists(paste0(pm_save_path, '/csv/'))) {
  dir.create(paste0(pm_save_path, '/csv/'), recursive = TRUE)
}

for (k in 1:i) {
	start_col = ((k - 1) * max_npart) + 1
	
	end_col = k * max_npart
	if(end_col > ncol(partition_matrix)) {
		end_col = ncol(partition_matrix)
	}
	
	#print(start_col)
	#print(end_col)
	saveRDS(partition_matrix[,start_col:end_col], file = paste0(pm_save_path, '/rds/', "global_partition_", k, ".rds"))
	write.csv(partition_matrix[,start_col:end_col], file = paste0(pm_save_path, '/csv/', "global_partition_", k, ".csv"))
}

print(paste('Time:', Sys.time() - START_TIME))