# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=7) {
  stop("Seven arguments expected.n", call.=FALSE)
} else {
  path = args[1]
  range_path = args[2]
  nugget_path = args[3]
  gls_outdir = args[4]
  form = args[5]
  form0 = args[6]
  fileX = args[7]
}

print(path)
print(fileX)
fileSub = paste0(path, fileX)
print(fileSub)

START_TIME = Sys.time()

# ____ Setup ____
#currentIt = as.numeric(gsub("\\D", "", fileSub))

partGLS_savepath = paste(gls_outdir, fileX, sep = "", collapse = NULL)

if(!dir.exists(gls_outdir)){dir.create(gls_outdir)}
print(partGLS_savepath)

#load range
rng_temp = read.csv(range_path, na.strings = "NA", header=FALSE, sep=',')
rng = median(as.numeric(unlist(rng_temp)))

#load nugget
ngt_temp = read.csv(nugget_path, na.strings = "NA", header=FALSE, sep=',')
ngt = median(as.numeric(unlist(ngt_temp)))

# define formulas
form = form
form0 = form0

partition_data = readRDS(fileSub)


#part_FUN = "part_data"
#part.f <- match.fun(part_FUN)

covar_FUN = "covar_exp"
covar.f <- match.fun(covar_FUN)

distm_FUN = "distm_scaled"
dist.f <- match.fun(distm_FUN)

partition_data$biomes <- as.factor(partition_data$biomes)
partition_data$ecoregions <- as.factor(partition_data$ecoregions)
partition_data$countries <- as.factor(partition_data$countries)
#print(partition_data)


partsize = nrow(partition_data)

icoordlong = as.double(partition_data[, c("long")])
icoordlat  = as.double(partition_data[, c("lat")])
icoords = cbind(icoordlong, icoordlat)

partGLS <- fitGLS(formula = form, data = partition_data, coords = icoords, covar_FUN = covar.f, covar.pars = list(range = rng), distm_FUN = dist.f, nugget = ngt, formula0 = form0, save.xx = TRUE, no.F = FALSE, save.invchol = TRUE)


glsObj <- list()
glsObj$coeff =partGLS$coefficients 
glsObj$SEs =partGLS$se 
glsObj$covar_coefs =partGLS$covar_coef 
glsObj$tstats =partGLS$tstat 
glsObj$tpvals =partGLS$pval_t 
glsObj$nuggets =partGLS$nugget 
glsObj$LLs =partGLS$logLik 
glsObj$SSEs =partGLS$SSE 
glsObj$MSEs =partGLS$MSE 
glsObj$MSRs =ifelse(is.null(partGLS$MSR) | length(partGLS$MSR) == 0, NA, partGLS$MSR)
glsObj$Fstats =partGLS$Fstat 
glsObj$Fpvals =partGLS$pval_F 
glsObj$xx =partGLS$xx 
glsObj$xx0 =partGLS$xx0 

print(Sys.time() - START_TIME)
	
saveRDS(glsObj, file = partGLS_savepath)
quit()