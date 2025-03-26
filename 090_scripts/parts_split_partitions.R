
#+
# :AUTHOR: Franz Schug [fschug@wisc.edu], support and advice Clay. J. Morrow (https://github.com/morrowcj)
# :DATE: 16 Sep. 2024
#
# :Description: Splits full dataset into partitions as described in the partition matrix for more efficient processing.

# :Parameters:  data_path - working directory
#               pm_load_file - path to existing partition matrix
#               sub_pm_outdir - directory to save partitions
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

if (length(args)!=5) {
  stop("Five arguments expected.n", call.=FALSE)
} else {
  data_indir = args[1]
  vars = unlist(strsplit(args[2], ","))
  categ = args[3]
  sub_pm_outdir = args[4]
  pm_load_file = args[5]
}


START_TIME = Sys.time()

partition_matrix = readRDS(pm_load_file)

pm_df = as.data.frame(partition_matrix)
#print(is.data.frame(pmn))
#print(is.data.frame(partition_matrix))

#print(nrow(pmn))
#print(ncol(pmn))

list_of_partitions <- vector("list", length = ncol(pm_df))

for (j in 1:ncol(pm_df)) {
	partition_data <- vector("list", length = length(vars))
	list_of_partitions[[j]] <- partition_data
}	

for (f in 1:length(vars)) {
	inVarPath = paste0(data_indir,vars[f],'_',categ,'.csv')
	#print(inVarPath)
	extp = fread(inVarPath)
	#print("var loaded")
	
	for (i in 1:ncol(pm_df)) {
	#for (i in 1:1) {
		colindex = colnames(partition_matrix)[i]
		#print(colindex)

		#print(pm_df[[i]])
		values = extp[pm_df[[i]], ]  # extract all values from variable at indices provided in partition_matrix
		#print(values)
		list_of_partitions[[i]][[f]] = values
	}
}

outDir = paste0(sub_pm_outdir)
# Create the directory if it doesn't exist

if (!dir.exists(paste0(sub_pm_outdir, '/rds/'))) {
  dir.create(paste0(sub_pm_outdir, '/rds/'), recursive = TRUE)
}

if (!dir.exists(paste0(sub_pm_outdir, '/csv/'))) {
  dir.create(paste0(sub_pm_outdir, '/csv/'), recursive = TRUE)
}

for (i in 1:ncol(pm_df)) {
#for (i in 1:1) {
	colindex = colnames(partition_matrix)[i]

	df1 <- do.call(cbind, lapply(list_of_partitions[[i]], as.data.frame))
	colnames(df1) <- vars

	outPath = paste0(sub_pm_outdir, '/rds/', 'data_', colindex , '.rds')
	outPathCSV = paste0(sub_pm_outdir, '/csv/', 'data_', colindex , '.csv')

	saveRDS(df1, outPath)
	write.csv(df1, outPathCSV, row.names = FALSE)
}
