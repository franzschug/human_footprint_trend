
#+
# :AUTHOR: Franz Schug [fschug@wisc.edu], support and advice Clay. J. Morrow (https://github.com/morrowcj)
# :DATE: 17 Sep. 2024
#
# :Description: Estimate spatial autocorrelation parameter - nugget.

# :Parameters:  dir_ar - directory to image files, autoregressive coefficients
#               dir_raw - directory to image files, autoregressive coefficients and residuals
#               nr - samples for each tile used to estimate nugget
#               range_path - path to .txt, read spatial autocorrelation parameter - range
#               outFileNUGG - path to .txt, write spatial autocorrelation parameter - nugget
#               save_dir - path to save GLS files
#               img_tile - current tile
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
library(raster)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=7) {
  stop("Seven arguments expected.n", call.=FALSE)
} else {
  dir_ar = args[1]
  dir_stack = args[2]
  nr = args[3]
  range_path = args[4]
  outFileNUGG = args[5]
  save_dir = args[6]
  img_tile = args[7]
}

print(dir_ar)
print(dir_stack)
print(img_tile)

# ____ Setup ____
coord_cols = 1:2  # column numbers containing coordinates, 1 is FID
data_cols = 3:22  # column numbers containing annual residuals
if(!dir.exists(save_dir)){dir.create(save_dir)}
GLS_save_file = file.path(save_dir, paste0("fitted_GLS_nugget_", img_tile, "_", ".rds"))
# ____ End Setup ____

START_TIME = Sys.time()

# ---- load ar coefficients ----
img_path = paste0(dir_ar, img_tile, sep="")
img_rst = stack(img_path)
ar_data = raster::as.data.frame(img_rst,xy=TRUE)

# ---- Load full stack ----
img_stack_path = paste0(dir_stack, gsub(".tif", ".vrt", img_tile), sep="")
img_stack_rst = stack(img_stack_path)
data_stack = raster::as.data.frame(img_stack_rst,xy=TRUE)
	
# ---- Load range ----
rng_temp = read.csv(range_path, na.strings = "NA", header=FALSE, sep=',')
rng = median(as.numeric(unlist(rng_temp)))


AR_coefficients = ar_data[, 3]
scaled_coefficients = AR_coefficients / rowMeans(data_stack[, data_cols]) # scaled to pixel means


# ---- GLS ----
GLS_data = cbind(ar_data[, coord_cols], AR_coefficients, scaled_coefficients)
GLS_data = GLS_data[sample(nrow(GLS_data), size=nr), ]
GLS_data = na.omit(GLS_data)
rm(data_stack)

fitted_GLS = fitGLS(formula = "AR_coefficients ~ 1", data = GLS_data, coords = as.matrix(GLS_data[, 1:2]), covar_FUN = "covar_exp", covar.pars = list(range = rng), distm_FUN = "distm_scaled", nugget = NA, no.F = FALSE, ncores = 1)

write(fitted_GLS$nugget,file=outFileNUGG,append=TRUE)

saveRDS(fitted_GLS, file = GLS_save_file)

print(paste('Time:', Sys.time() - START_TIME))