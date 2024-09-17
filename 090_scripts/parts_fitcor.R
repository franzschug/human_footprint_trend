
#+
# :AUTHOR: Franz Schug [fschug@wisc.edu], support and advice Clay. J. Morrow (https://github.com/morrowcj)
# :DATE: 16 Sep. 2024
#
# :Description: Estimate spatial autocorrelation parameter - range.

# :Parameters:  dir - data directory
#               n_per_tile - sample size, pixels within each tile
#               iter - iterations
#               outFileSPCORS - path to .txt, write spatial autocorrelation parameter - range
#               outDirSPCORS - path to save autocorrelation object
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

if (length(args)!=6) {
  stop("Six arguments expected.n", call.=FALSE)
} else {
  dir = args[1]
  n_per_tile = args[2]
  iter = args[3]
  outFileSPCORS = args[4]
  outDirSPCORS = args[5]
  img_tile = args[6]
}

img_path = paste(dir, img_tile, sep="")

# ____ Setup ____
coord_cols = 1:2
cor_fit_n = n_per_tile
save_dir = outDirSPCORS
if(!dir.exists(save_dir)){dir.create(save_dir)}
# ____ End Setup ____

START_TIME = Sys.time()

for (i in 1:iter) {
	cor_save_file = file.path(save_dir, paste0("fitted_spatialcor_", img_tile, "_", i, ".rds"))

	img_rst = stack(img_path)
	ar_data = raster::as.data.frame(img_rst,xy=TRUE)
	
	temporal_residuals = as.matrix(ar_data[, -c(1,2)])

	# ---- Spatial correlation among AR residuals ----
	# Estimate spatial covariance parameter, range
	fitted_spatialcor <- fitCor(resids = temporal_residuals, coords = as.matrix(ar_data[, coord_cols]),
								  start = list(r = 0.01), fit.n = cor_fit_n, save_mod = FALSE)
		  
	write(fitted_spatialcor$spcor,file=outFileSPCORS,append=TRUE)
	saveRDS(fitted_spatialcor, file = cor_save_file)
}

print(paste('fitCor time:', Sys.time() - START_TIME))