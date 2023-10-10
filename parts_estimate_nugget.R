# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=4) {
  stop("Four arguments expected.n", call.=FALSE)
} else {
  dir_ar = args[1]
  dir_raw = args[2]
  range_path = args[3]
  file = args[4]
}

print(dir_ar)
print(dir_raw)
print(file)

# ____ Setup ____
partition_size = 200 # pixels per partition for GLS
coord_cols = 2:3  # column numbers containing coordinates, 1 is FID
data_cols = 4:23  # column numbers containing annual residuals
core_num = 10 # number of cores to use
nr = 3000

save_dir = "/data/FS_human_footprint/011_data/parts/gls/"
if(!dir.exists(save_dir)){dir.create(save_dir)}

batch_name = paste("global_300_", file, sep="")
GLS_save_file = file.path(save_dir, paste0("fitted_GLS_", batch_name, ".rds"))
# ____ End Setup ____


START_TIME = Sys.time()

#load ar results
ar_data = read.csv(paste0(dir_ar,file), na.strings = "NA", header=TRUE, sep=',')

#load data_raw
data_raw = read.csv(paste0(dir_raw,file), na.strings = "NA", header=TRUE, sep=',')

#load range
rng_temp = read.csv(range_path, na.strings = "NA", header=FALSE, sep=',')
rng = median(as.numeric(unlist(rng_temp)))
AR_coefficients = ar_data[, "coef"]
AR_pvalues = ar_data[, "pval"]
scaled_coefficients = AR_coefficients / rowMeans(data_raw[, data_cols]) # scaled to pixel means


# ---- GLS ----
# create new data to run GLS on, with two possible response variables

GLS_data = cbind(data_raw[, coord_cols], AR_coefficients, scaled_coefficients)
#nrow(GLS_data) == nrow(data_raw)
GLS_data <- GLS_data[sample(nrow(GLS_data), size=nr), ]

# randomly partition the pixels
#partition_matrix = sample_partitions(npix = nrow(data_raw), partsize = partition_size, npart = 2)
rm(data_raw)

# remove the original large data set from memory (recommended)

DATA_TIME = Sys.time()
print(paste('Prep. data:', DATA_TIME - START_TIME))

#fitted_GLS = fitGLS_partition(formula = "AR_coefficients ~ 1", data = GLS_data, coord.names = c("Long", "Lat"), partmat = partition_matrix, part_FUN = 'part_data', covar_FUN = "covar_exp", covar.pars = list(range = rng), distm_FUN = "distm_scaled", nugget = NA, ncross = 6, save.GLS = FALSE, do.t.test = FALSE, do.chisqr.test = FALSE, ncores = core_num, parallel = TRUE)
fitted_GLS = fitGLS(formula = "AR_coefficients ~ 1", data = GLS_data, coords = as.matrix(GLS_data[, 1:2]), covar_FUN = "covar_exp", covar.pars = list(range = rng), distm_FUN = "distm_scaled", nugget = NA, no.F = FALSE, ncores = core_num)
#GLS.opt <- fitGLS(formula = AR_coef ~ 0 + land, data = ndvi_AK3000, V = V.opt, nugget = NA, no.F = FALSE)

DATA_TIME = Sys.time()
print(paste('GLS fitted:', DATA_TIME - START_TIME))

print("fitted_GLS")
print(fitted_GLS)
print(fitted_GLS$nugget)
## [1] 0.1342314
print(coefficients(fitted_GLS))

write(fitted_GLS$nugget,file="/data/FS_human_footprint/011_data/parts/alls_nuggets.txt",append=TRUE)
saveRDS(fitted_GLS, file = GLS_save_file)

quit()