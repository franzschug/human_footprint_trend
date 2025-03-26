
#+
# :AUTHOR: Franz Schug [fschug@wisc.edu], support and advice Clay. J. Morrow (https://github.com/morrowcj)
# :DATE: 16 Sep. 2024
#
# :Description: Fit pixel-wise autoregressive trend based on the remotePARTS package.

# :Parameters:  working_dir - working directory
#               counterx - x-tile
#               countery - y-tile
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

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)
library(raster)
library(doParallel)
library(foreach)

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=3) {
  stop("Three arguments expected.n", call.=FALSE)
} else {
  working_dir = args[1]
  counterx = args[2]
  countery = args[3]
}

print(paste(counterx, '_', countery))
source(paste0(working_dir, "/090_scripts/code/helper-functions.R"))  # loads helper functions including the iterator iblkrow()

# ____ Setup ____
batch_name = paste("global_300", counterx, "_", countery, sep="")
img_path = paste(working_dir, "/011_data/hii/v1/00_stack/hii_", counterx, "_", countery,".vrt", sep="")
out_dir = paste(working_dir, "/011_data/parts/ar/", sep="")
if(!dir.exists(out_dir)){dir.create(out_dir)}
AR_save_file = file.path(out_dir, paste0("fitted_AR_", batch_name, ".rds"))

coord_cols = c(1, 2)  # column numbers for coordinates
data_cols = 3:22  # column numbers containing time series data
core_num = 40 # number of cores to use
registerDoParallel(core_num)
# ____ End Setup ____

START_WRITE_TIME = Sys.time()

img_rst = stack(img_path)
xres = xres(img_rst)
yres = yres(img_rst)
xmin = xmin(img_rst)
xmax = xmax(img_rst)
ymin = ymin(img_rst)
ymax = ymax(img_rst)

df = raster::as.data.frame(img_rst,xy=TRUE)

# ---- prep data ----
cleaned_df = na.omit(df)
if(nrow(cleaned_df) == 0){quit()}

t_start = Sys.time() - START_WRITE_TIME

# ----------- fitAR_map MULTICORE-------------
# loop through blocks of the data (using helper function)
AR_results = foreach(y = iblkrow(as.matrix(cleaned_df[, data_cols]), core_num),
	crds = iblkrow(as.matrix(cleaned_df[, coord_cols]), core_num),
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

t_ar = Sys.time() - START_WRITE_TIME

ars_csv_all = cbind(cleaned_df[, coord_cols], AR_results)
ars_csv_cpv = cbind(cleaned_df[, coord_cols], AR_results[, 1:2])
saveRDS(AR_results, file = AR_save_file)

rast_all = rasterize(ars_csv_all[, 1:2], img_rst, ars_csv_all[, 3:24], fun=mean)
rast_cpv = rasterize(ars_csv_cpv[, 1:2], img_rst, ars_csv_cpv[, 3:4], fun=mean)

rasterpath_all = paste(working_dir, "/011_data/hii/v1/ar_all/hii_", counterx, "_", countery,".tif", sep="")    # path to data #### residuals
rasterpath_cpv = paste(working_dir, "/011_data/hii/v1/ar_coeff_pv/hii_", counterx, "_", countery,".tif", sep="")    # path to data

writeRaster(rast_cpv,rasterpath_cpv,options=c('TFW=YES', 'COMPRESS=LZW'), overwrite=TRUE)
writeRaster(rast_all,rasterpath_all,options=c('TFW=YES', 'COMPRESS=LZW'), overwrite=TRUE)

t_write = Sys.time() - START_WRITE_TIME

# Save Processing time
rw <- data.frame('Start', t_start, 'AR', t_ar, 'Write', t_write) 
p_time_path = paste(working_dir, "/014_results/t_ar_processing.csv", sep="")
write.table(rw, file = p_time_path, sep = ",", append = TRUE, quote = FALSE, col.names = FALSE, row.names = FALSE) 

# ---------- END MULTICORE VERSION ----------