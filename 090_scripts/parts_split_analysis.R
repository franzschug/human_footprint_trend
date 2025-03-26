# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=5) {
  stop("Five arguments expected.n", call.=FALSE)
} else {
  gls_inDir = args[1]
  cross_inDir = args[2]
  outPath = args[3]
  subset_gls = as.numeric(args[4])
  subset_pairs = as.numeric(args[5])
}

START_TIME = Sys.time()

outPath = paste0(outPath, '_', subset_gls, '_', subset_pairs, '.rds')

## load all gls files or subset
gls_list = list.files(path = gls_inDir, pattern = "\\.rds$", full.names = TRUE)

if (subset_gls != 0) {
	gls_list = sample(gls_list, subset_gls)
}

## load cross pairs
cross_list = list.files(path = cross_inDir, pattern = "\\.rds$", full.names = TRUE)

if (subset_pairs != 0) {
	cross_list = sample(cross_list, subset_pairs)
}

npairs = length(cross_list)

## extract dimensions
dimGLS = readRDS(gls_list[1], refhook = NULL)
p   = ncol(dimGLS$xx)
p0  = ncol(dimGLS$xx0)

coefs = SEs = tstats = tpvals = matrix(NA, nrow = length(gls_list), ncol = p, dimnames = list(NULL, names(dimGLS$coeff)))
nuggets = LLs = SSEs = MSEs = MSRs = Fstats = Fpvals = rep(NA, times = length(gls_list))
covar_coefs = array(NA, dim = c(p, p, length(gls_list)), dimnames = list(names(dimGLS$coeff), names(dimGLS$coeff), NULL))


glsCounter = 0
for (gls in gls_list) {
	print(glsCounter)
	glsCounter = glsCounter + 1
	glsV = readRDS(gls, refhook = NULL)
	coefs[glsCounter,] = glsV$coeff
	Fstats[glsCounter] = glsV$Fstat
	covar_coefs[ , , glsCounter] = glsV$covar_coef
}  



## cross stats
rSSRs = rSSEs = rep(NA, npairs)
rcoefs = array(NA, dim = c(npairs, p, p), dimnames = list(NULL, names(dimGLS$coeff), names(dimGLS$coeff)))

crossCounter = 0
for (cross in cross_list) {
	print(crossCounter)
	crossCounter = crossCounter + 1
	crossV = readRDS(cross, refhook = NULL)
	rcoefs[crossCounter, ,] <- as.numeric(crossV$rcoef)
	#rcoefs <- append(as.numeric(rcoefs), crossV$rcoef)
	rSSRs <- append(as.numeric(rSSRs), crossV$rSSR)
	rSSEs <- append(as.numeric(rSSEs), crossV$rSSE)
}

print('a')
# todo if multiple cols
rcoefficients = apply(rcoefs, MARGIN=c(2,3), FUN = function(x){mean(x, na.rm = TRUE)})

print('b')
partsize = crossV$partsize

print('c')
df2 = remotePARTS:::calc_dfpart(partsize, p, p0)[2]

print('d')
# Call the part_ttest function
ttest <- remotePARTS:::part_ttest(colMeans(coefs, na.rm = TRUE), covar_coefs, rcoefficients, df2, npart = length(gls_list))

print('e')
outlist = list(coefficients = colMeans(coefs, na.rm = TRUE), rcoefficients = rcoefficients, rSSR = mean(rSSRs, na.rm = TRUE), rSSE = mean(rSSEs, na.rm = TRUE), Fstat = mean(Fstats, na.rm = TRUE), ttest = ttest$p.t, covar_coef = ttest$covar_coef)
print('f')
saveRDS(outlist, file = outPath)
print('g')
quit()