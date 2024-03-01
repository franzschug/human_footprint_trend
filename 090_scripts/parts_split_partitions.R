# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=3) {
  stop("Three arguments expected.n", call.=FALSE)
} else {
  pathToData = args[1]
  pm_save_file = args[2]
  sub_pm_outdir = args[3]
}

#print(file)
START_TIME = Sys.time()

# ____ Setup ____
coord_cols = 1:2  # column numbers containing annual residuals
resid_cols = 5:24  # column numbers containing annual residuals
core_num = 44
partition_size = 2000 # pixels per partition for GLS

path = pathToData
ddt <- read.csv(path, header = TRUE, sep = ",")

ar_data = read.csv(pathToData, na.strings = "NA", header=TRUE, sep=',')

print(head(ddt))


## generate or load partition matrix of the complete dataset
#partition_matrix = sample_partitions(npix = nrow(ar_data), partsize = partition_size, npart = NA)
#saveRDS(partition_matrix, file = pm_save_file)

## define maximum number of data in a file
max_per_part = 2000000 # multiple of row size 2000

## split data into files based on partition matrix indices
start_t = Sys.time()
partition_matrix = readRDS(pm_save_file)
#print(head(partition_matrix))
#print(length(partition_matrix))
#print(length(partition_matrix$part.3306))
#print(max(partition_matrix))
#print(dim(partition_matrix))
#print(dim(partition_matrix[1]))
#print(dim(partition_matrix[2]))

nbr_of_files = ceiling((dim(partition_matrix)[1] * dim(partition_matrix)[2]) / max_per_part)
#print((nbr_of_files))

for (i in 1:nbr_of_files) {
  firstCol = i+((i-1)*(max_per_part / nrow(partition_matrix)))

  if(i < nbr_of_files) {
  lastCol = firstCol + 	((max_per_part / nrow(partition_matrix))) - 1
  } else {
  lastCol = ncol(partition_matrix) - 1
  }

  tempPM = partition_matrix[,firstCol:lastCol]
  #print(head(tempPM))
  #print(dim(tempPM))
  #print(dim(ddt))
  #print(typeof(ddt))
  #print(ddt[:,1])

  #copy data for each partition incl. lon/lat and coeff
  
  # empty dataframe with ncol = partitions
  #tempData <- as.data.frame(matrix(ncol=ncol(tempPM), nrow=0))
  tempData = list()
 
  for (k in 1:ncol(tempPM)) {
	#print(k)
	#print(tempPM[,k])
	#print(length(tempPM[,k]))
	
	#print(c(tempPM[,k]))
	# select all rows at all indices in current partition
	#tempData[,k] = ddt[c(tempPM[k]),]
	
	#print(ddt[c(tempPM[k]),])
	#print(typeof(ddt[c(tempPM[k]),]))
	#print(length(ddt[c(s[k]),]))
	#print(list(ddt[c(tempPM[k]),]))
	#print(length(list(ddt[c(tempPM[k]),])))
	#tempData[k] = list()
	#tempData[k] <- c(tempData[k], ddt[c(tempPM[k]),])
	#print(ddt[c(tempPM[k]),])
	#print(length(ddt[c(tempPM[k]),]))
	

	tL = list()

	tL = ddt[c(tempPM[,k]),]


	#tL[2] = ddt[c(tempPM[,k]),2]
	#tL[3] = ddt[c(tempPM[,k]),3]
	#tempData <- c(tempData, tL)
	tempData[[length(tempData)+1]] <- tL

  }

  print("length")
  #print(length(tempData))
  # prints all coefficients (col 3) in partition 5
  #print((tempData[[5]][3]))


  outFile = paste(sub_pm_outdir, 'rds/sub_pmatrix_', i, '.rds', sep = "", collapse = NULL)
  outFile2 = paste(sub_pm_outdir, 'sub_pmatrix_', i, '.csv', sep = "", collapse = NULL)
  outFile3 = paste(sub_pm_outdir, 'rds/sub_partition_data_', i, '.rds', sep = "", collapse = NULL)
  outFile4 = paste(sub_pm_outdir, 'sub_partition_data_', i, '.csv', sep = "", collapse = NULL)
  saveRDS(tempPM, file = outFile)
  saveRDS(tempData, file = outFile3)
  write.csv(tempPM, outFile2, row.names=FALSE)
  write.csv(tempData, outFile4, row.names=FALSE)
} 

#print(Sys.time() - start_t)
