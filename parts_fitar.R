# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)
#library("dplyr")
library(raster)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=2) {
  stop("Two arguments expected.n", call.=FALSE)
} else {
  counterx = args[1]
  countery = args[2]
}

# ____ Setup ____
# change these for different functionality
batch_name = paste("global_300_", counterx, "_", countery, sep="")
data_path = paste("/data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/csv/hii_", counterx, "_", countery,".csv", sep="")    # path to data

save_dir = "/data/FS_human_footprint/011_data/parts/ar/"

id_cols = c(1) # column number of ID columns
coord_cols = c(2, 3)  # column numbers for coordinates
data_cols = 4:23  # column numbers containing time series data
core_num = 10 # number of cores to use
# ____ End Setup ____

# ---- output setup ----
# create output directory, if it doesn't already exist
if(!dir.exists(save_dir)){dir.create(save_dir)}
# create file names for saving the models
AR_save_file = file.path(save_dir, paste0("fitted_AR_FS_", batch_name, ".rds"))
# ____ End Setup ____


START_TIME = Sys.time()

# ---- load data ----
data_raw = read.csv(data_path, na.strings = "-9999", header=TRUE, sep=',') # read all rows

DATA_TIME = Sys.time()

print(paste('Load time:', DATA_TIME - START_TIME))


# ---- AR model ----

# ----------- fitAR_map MULTICORE-------------
library(doParallel)
library(foreach)
source("/data/FS_human_footprint/090_scripts/code/helper-functions.R")  # loads helper functions including the iterator iblkrow()
registerDoParallel(core_num)

# loop through blocks of the data (using helper function)
AR_results = foreach(y = iblkrow(as.matrix(data_raw[, data_cols]), core_num),
	crds = iblkrow(as.matrix(data_raw[, coord_cols]), core_num),
	.packages = c("remotePARTS", "foreach"), .inorder = TRUE, .combine = rbind) %dopar% {
	 # loop through each row of the chunks
	 out = foreach(i=seq_len(nrow(y)), .combine = rbind, .inorder = TRUE) %do% {
	   t = seq_len(ncol(y))  # time
	   AR = fitAR(as.formula(as.vector(y[i, ]) ~ t))  # AR fit
	   # return a collection of AR variables of interest
	   c(coef = unname(AR$coefficients["t"]),
		 pval = unname(AR$pval["t"]),
		 resids = AR$residuals)
	 }
	 rownames(out) = NULL # remove rownames "t"
	 out # return the combined results
	}

DATA_TIME = Sys.time()
	
print(paste('AR time:', DATA_TIME - START_TIME))
	
ars_csv_all = cbind(data_raw[, coord_cols], AR_results)
ars_csv_cpv = cbind(data_raw[, coord_cols], AR_results[, 1:2])
saveRDS(AR_results, file = AR_save_file)

# write ar results as raster
x = raster(xmn=(strtoi(counterx)), xmx=(strtoi(counterx)+5), ymn=(strtoi(countery)-5), ymx=(strtoi(countery)), res=0.002694945852358564611, crs="+proj=longlat +elips=WGS84")

rast_all = rasterize(ars_csv_all[, c('Long', 'Lat')], x, ars_csv_all[, 3:24], fun=mean)
rast_cpv = rasterize(ars_csv_cpv[, c('Long', 'Lat')], x, ars_csv_cpv[, 3:4], fun=mean)
raterpath_all = paste("/data/FS_human_footprint/011_data/hii/v1/ar_all/tif/hii_arr_", counterx, "_", countery,".tif", sep="")    # path to data
raterpath_cpv = paste("/data/FS_human_footprint/011_data/hii/v1/ar_coeff_pv/tif/hii_arr_", counterx, "_", countery,".tif", sep="")    # path to data
writeRaster(rast_all,raterpath_all,options=c('TFW=YES'), overwrite=TRUE)
writeRaster(rast_cpv,raterpath_cpv,options=c('TFW=YES'), overwrite=TRUE)

# write ar results as csv
csvpath_all = paste("/data/FS_human_footprint/011_data/hii/v1/ar_all/csv/hii_arr_", counterx, "_", countery,".csv", sep="")    # path to data
write.csv(ars_csv_all, csvpath_all, row.names=FALSE)

DATA_TIME = Sys.time()

print(paste('Complete time:', DATA_TIME - START_TIME))
	
# ---------- END MULTICORE VERSION ----------