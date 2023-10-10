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
  dir = args[1]
  file = args[2]
  iter = args[3]
}

print(dir)
print(file)
print(iter)
START_TIME = Sys.time()

# ____ Setup ____
coord_cols = 1:2  # column numbers containing annual residuals
resid_cols = 5:24  # column numbers containing annual residuals
cor_fit_n = 3000
save_dir = "/data/FS_human_footprint/011_data/parts/cor/"
if(!dir.exists(save_dir)){dir.create(save_dir)}

for (i in 1:iter) {
	batch_name = paste("global_300_", file, sep="")
	Cor_save_file = file.path(save_dir, paste0("fitted_spatialcor_", batch_name, i, ".rds"))
	# ____ End Setup ____

	# ---- load csv ----
	ar_data = read.csv(paste0(dir,file), na.strings = "NA", header=TRUE, sep=',') # read all rows

	# assign important values to variables
		# dim(AR_results)
	#AR_coefficients = ar_data[, "coef"]
	#AR_pvalues = ar_data[, "pval"]
	temporal_residuals = as.matrix(ar_data[, -c(1,2)])

	# ---- Spatial correlation among AR residuals ----
	# estimate the spatial covariance parameters
	fitted_spatialcor <- fitCor(resids = temporal_residuals, coords = as.matrix(ar_data[, coord_cols]),
								  start = list(r = 0.01), fit.n = cor_fit_n, save_mod = FALSE)
	#print(fitted_spatialcor$spcor)				  
	write(fitted_spatialcor$spcor,file="/data/FS_human_footprint/011_data/parts/alls_spcors.txt",append=TRUE)
	saveRDS(fitted_spatialcor, file = Cor_save_file)
}

DATA_TIME = Sys.time()

print(paste('fitCor time:', DATA_TIME - START_TIME))