# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)

args = commandArgs(trailingOnly=TRUE)
print(args)

# test for arguments
if (length(args)!=5) {
  stop("Five arguments expected.n", call.=FALSE)
} else {
  gls_inDir = args[1]
  files = args[2]
  data_inDir = args[3]
  cross_outdir = args[4]
  range_path = args[5]
}
splitfiles <- strsplit(files, " ")[[1]]

file1 <- splitfiles[1]
file2 <- splitfiles[2]
print(file1)
print(file2)
START_TIME = Sys.time()

# ____ Setup ____
f1_it = as.numeric(gsub("\\D", "", file1))
f2_it = as.numeric(gsub("\\D", "", file2))

cross_savepath = paste(cross_outdir, 'cross_', f1_it, '_', f2_it, '.rds', sep = "", collapse = NULL)
if(!dir.exists(cross_outdir)){dir.create(cross_outdir)
}

# load gls results
gls_1 = readRDS(paste0(gls_inDir, file1), refhook = NULL)
gls_2 = readRDS(paste0(gls_inDir, file2), refhook = NULL)

## If not all columns/variables are represented in all partitions, reduce to common feat

#common_columns <- intersect(names(gls_1$coeff), names(gls_2$coeff))
#print(common_columns)
#print(length(common_columns))
#print((gls_1$coeff['countries15']))
#
#print(("gls_1$coeff"))
#print(length(gls_1$coeff))
#print(length(gls_1$SEs))
#print(length(gls_1$covar_coefs))
#print(length(gls_1$tstats))
#print(length(gls_1$tpvals))
#print(length(gls_1$nuggets))
#print(length(gls_1$LLs))
#print(length(gls_1$SSEs))
#print(length(gls_1$MSEs))
#print(length(gls_1$nuggets))
#print(length(gls_1$Fstats))
#print(length(gls_1$Fpvals))
#print(ncol(gls_1$xx))
#print(nrow(gls_1$xx))
#print(length(gls_1$xx0))
#
#
#
## Remove columns at the same positions in the other data frames
#gls_1$tstats <- gls_1$tstats[names(gls_1$coeff) %in% names(gls_2$coeff)]
#gls_2$tstats <- gls_2$tstats[names(gls_2$coeff) %in% names(gls_1$coeff)]
#
#gls_1$tpvals <- gls_1$tpvals[names(gls_1$coeff) %in% names(gls_2$coeff)]
#gls_2$tpvals <- gls_2$tpvals[names(gls_2$coeff) %in% names(gls_1$coeff)]
#
#gls_1$xx <- gls_1$xx[, names(gls_1$coeff) %in% names(gls_2$coeff)]
#gls_2$xx <- gls_2$xx[, names(gls_2$coeff) %in% names(gls_1$coeff)]
#
## Remove columns not in common in df1
#gls_1$coeff <- gls_1$coeff[names(gls_1$coeff) %in% common_columns]
#
## Remove columns not in common in df2
#gls_2$coeff <- gls_2$coeff[names(gls_2$coeff) %in% common_columns]
#
#print(("gls_1$coeff"))
#print(length(gls_1$coeff))
#print(length(gls_1$SEs))
#print(length(gls_1$covar_coefs))
#print(length(gls_1$tstats))
#print(length(gls_1$tpvals))
#print(length(gls_1$nuggets))
#print(length(gls_1$LLs))
#print(length(gls_1$SSEs))
#print(length(gls_1$MSEs))
#print(length(gls_1$nuggets))
#print(length(gls_1$Fstats))
#print(length(gls_1$Fpvals))
#print(ncol(gls_1$xx))
#print(nrow(gls_1$xx))
#print(length(gls_1$xx0))
#
#print("end@@")

# load corresponding partition
part1 = readRDS(paste0(data_inDir, 'data_part.', f1_it, '.rds'), refhook = NULL)
part2 = readRDS(paste0(data_inDir, 'data_part.', f2_it, '.rds'), refhook = NULL)
covar_FUN = "covar_exp"
covar.f <- match.fun(covar_FUN)

distm_FUN = "distm_scaled"
dist.f <- match.fun(distm_FUN)

#cross.pairs = t(combn(seq_len(ncross), 2))
#npairs = nrow(cross.pairs)

partsize = nrow(part1)

icoordlong = as.double(part1[, c("long")])
icoordlat  = as.double(part1[, c("lat")])
icoords = cbind(icoordlong, icoordlat)

jcoordlong = as.double(part2[, c("long")])
jcoordlat  = as.double(part2[, c("lat")])
jcoords = cbind(jcoordlong, jcoordlat)

#load range
rng_temp = read.csv(range_path, na.strings = "NA", header=FALSE, sep=',')
rng = median(as.numeric(unlist(rng_temp)))

Vij = do.call(covar.f, args = append(list(d = dist.f(icoords, jcoords)), list(range = rng)))
dfs = remotePARTS:::calc_dfpart(partsize = partsize, p = ncol(gls_2$xx), p0 = ncol(gls_2$xx0))
print(length(gls_1$xx0))
covar.pars = c(range = rng)
if (is.null(gls_1$invcholV)){
  Vi = do.call(covar.f, args = append(list(d = dist.f(icoords)), as.list(covar.pars)))
  gls_1$invcholV <- invert_chol(Vi)
}

if (is.null(gls_2$invcholV)){
  Vj = do.call(covar.f, args = append(list(d = dist.f(jcoords)), as.list(covar.pars)))
  gls_2$invcholV <- invert_chol(Vj)
}	  

#print((gls_1$xx))
print(ncol(gls_1$xx))
print(ncol(gls_1$xx0))
print(ncol(gls_2$xx))
print(ncol(gls_2$xx0))
rGLS = remotePARTS:::crosspart_GLS(xxi = gls_1$xx, xxj = gls_2$xx, xxi0 = gls_1$xx0, xxj0 = gls_2$xx0, invChol_i = gls_1$invcholV, invChol_j = gls_2$invcholV, Vsub = Vij, nug_i = gls_1$nugget, nug_j = gls_2$nugget, df1 = dfs[1], df2 = dfs[2], small = FALSE)

rcoef = rGLS$rcoefij
rSSR = ifelse(is.na(rGLS$rSSRij) | is.infinite(rGLS$rSSRij), NA, rGLS$rSSRij)
rSSE = rGLS$rSSEij

outCross = list(rcoef = rcoef, rSSR = rSSR, rSSE = rSSE, partsize = partsize, dfs = dfs)
#print(outCross)

saveRDS(outCross, file = cross_savepath)
quit()