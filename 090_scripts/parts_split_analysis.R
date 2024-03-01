# Add local R library to this project
.libPaths(unique("R_library", .libPaths()))

# ---- Load remotePARTS ----
# # Un-comment to update the package if needed
#remotes::install_github("morrowcj/remotePARTS", dependencies = TRUE, update = "always", force = TRUE)

library(remotePARTS)

args = commandArgs(trailingOnly=TRUE)

# test for arguments
if (length(args)!=1) {
  stop("One arguments expected.n", call.=FALSE)
} else {
  intermediate_res_indir = args[1]
}

START_TIME = Sys.time()

# ____ Setup ____
#currentIt = as.numeric(gsub("\\D", "", fileSub))

### TODO: for all files!
currentIt = 113001

# for t-test
coeffs = readRDS(paste(intermediate_res_indir, 'coefs_', currentIt, '.rds', sep = "", collapse = NULL))
covar_coeffs = readRDS(paste(intermediate_res_indir, 'covar_coefs_', currentIt, '.rds', sep = "", collapse = NULL))
rcoeffs = readRDS(paste(intermediate_res_indir, 'rcoefs_', currentIt, '.rds', sep = "", collapse = NULL))
dfs = readRDS(paste(intermediate_res_indir, 'dfs_', currentIt, '.rds', sep = "", collapse = NULL))
npart = readRDS(paste(intermediate_res_indir, 'npart_', currentIt, '.rds', sep = "", collapse = NULL))

# others
rssr  = readRDS(paste(intermediate_res_indir, 'rssr_', currentIt, '.rds', sep = "", collapse = NULL))
rsse  = readRDS(paste(intermediate_res_indir, 'rsse_', currentIt, '.rds', sep = "", collapse = NULL))
fstat = readRDS(paste(intermediate_res_indir, 'fstat_', currentIt, '.rds', sep = "", collapse = NULL))

### Error in rcoefficients[i, i] : subscript out of bounds
### Calls: <Anonymous>
tryCatch(
    expr = {
		tteststats = remotePARTS:::part_ttest(coefs = coeffs, part.covar_coef = covar_coeffs, rcoefficients = rcoeffs, df2 = dfs[2], npart = npart)
		print(tteststats)
    },
    error = function(e){ 
        print(e)
    }
)



cat("\nCoefficients:\n")
print(coeffs)
print(apply(coeffs, 2, mean, na.rm=TRUE))

cat("\nCross coefficients:\n")
print(rcoeffs)

cat("\nCross-partition statistics:\n")
print('rsse')
print(rsse)
print(rssr)
print(fstat)
cross_stats = c("rSSE" = apply(rsse, 2, mean, na.rm=TRUE))

if(!is.na(x$overall$rSSR) | !is.null(x$overall$rSSR)){
  cross_stats["rSSR"] = apply(rssr, 2, mean, na.rm=TRUE)
}
if(!is.na(x$overall$Fstat) | !is.null(x$overall$Fstat)){
  cross_stats["Fstat"] = apply(fstat, 2, mean, na.rm=TRUE)
}

print(cross_stats)
#print(c(rSSR = x$overall$rSSR, rSSE = x$overall$rSSE, Fstat = x$overall$Fstat), ...)

#if(!is.null(x$overall$t.test)){
#  cat("\nT-test results:\n")
#  print(x$overall$t.test)
#}


#print("Coefficients:")
#print(coeffs)
#Coefficients:
#(Intercept)
#   0.935902
#
#Cross coefficients:
#            (Intercept)
#(Intercept)   0.9406567
#
#Cross-partition statistics:
#      rSSR       rSSE      Fstat
#       NaN 0.09035662        NaN
#
#T-test results:
#                 Est       SE    t.stat    pval.t
#(Intercept) 0.935902 1.914965 0.4887305 0.6250326
#
#
quit()





npart = length(partition_data)
ncross = 6

#part_FUN = "part_data"
#part.f <- match.fun(part_FUN)

covar_FUN = "covar_exp"
covar.f <- match.fun(covar_FUN)

distm_FUN = "distm_scaled"
dist.f <- match.fun(distm_FUN)

cross.pairs = t(combn(seq_len(ncross), 2))
npairs = nrow(cross.pairs)

partGLS = vector("list", npart)
print(npart)

#partition_mtrix - indices!
for(i in 1:npart){	
	partsize = nrow(partition_data[[i]])
	
	if (is.null(partGLS[[i]])){
		icoordlong = as.double(partition_data[[i]][, c("Long")])
		icoordlat  = as.double(partition_data[[i]][, c("Lat")])
		icoords = cbind(icoordlong, icoordlat)

		partGLS[[i]] <- fitGLS(formula = form, data = partition_data[[i]], coords = icoords, covar_FUN = covar.f, covar.pars = list(range = rng), distm_FUN = dist.f, nugget = ngt, formula0 = form0, save.xx = TRUE, no.F = FALSE, save.invchol = TRUE)
		
		if (i == 1){
			p = ncol(partGLS[[1]]$xx)
			p0 = ncol(partGLS[[1]]$xx0)
			## part stats
			coefs = SEs = tstats = tpvals =
			matrix(NA, nrow = npart, ncol = p, dimnames = list(NULL, names(partGLS[[1]]$coefficients)))
			nuggets = LLs = SSEs = MSEs = MSRs = Fstats = Fpvals = rep(NA, times = npart)
			covar_coefs = array(NA, dim = c(p, p, npart), dimnames = list(names(partGLS[[1]]$coefficients), names(partGLS[[1]]$coefficients), NULL))
			## cross stats
			rSSRs = rSSEs = rep(NA, npairs)
			rcoefs = array(NA, dim = c(npairs, p, p), dimnames = list(NULL, names(partGLS[[1]]$coefficients), names(partGLS[[1]]$coefficients)))
        }
		
		print(partGLS[[i]]$coefficients)

		#save relevant results # do not save GLS object to reduce total file size
		coefs[i, ] = partGLS[[i]]$coefficients
        SEs[i, ] = partGLS[[i]]$SE
        covar_coefs[ , , i] = partGLS[[i]]$covar_coef
        tstats[i, ] = partGLS[[i]]$tstat
        tpvals[i, ] = partGLS[[i]]$pval_t
        nuggets[i] = partGLS[[i]]$nugget
        LLs[i] = partGLS[[i]]$logLik
        SSEs[i] = partGLS[[i]]$SSE
        MSEs[i] = partGLS[[i]]$MSE
        MSRs[i] = ifelse(is.null(partGLS[[i]]$MSR) | length(partGLS[[i]]$MSR) == 0, NA, partGLS[[i]]$MSR)
        Fstats[i] = partGLS[[i]]$Fstat
        Fpvals [i] = partGLS[[i]]$pval_F
		quit()
		print(paste('Npart ', i, 'File ', currentIt))
		print(Sys.time() - START_TIME)
		
		if (i < ncross){
			for (j in (i+1):ncross) { 
				if (is.null(partGLS[[j]])){
					jcoordlong = as.double(partition_data[[j]][, c("Long")])
					jcoordlat  = as.double(partition_data[[j]][, c("Lat")])
					jcoords = cbind(jcoordlong, jcoordlat)
					partGLS[[j]] <- fitGLS(formula = form, data = partition_data[[j]], coords = jcoords, covar_FUN = covar.f, covar.pars = list(range = rng), distm_FUN = dist.f, nugget = ngt, formula0 = form0, save.xx = TRUE, no.F = FALSE, save.invchol = TRUE)
					
					coefs[j, ] = partGLS[[j]]$coefficients
					SEs[j, ] = partGLS[[j]]$SE
					covar_coefs[ , , j] = partGLS[[j]]$covar_coef
					tstats[j, ] = partGLS[[j]]$tstat
					tpvals[j, ] = partGLS[[j]]$pval_t
					nuggets[j] = partGLS[[j]]$nugget
					LLs[j] = partGLS[[j]]$logLik
					SSEs[j] = partGLS[[j]]$SSE
					MSEs[j] = partGLS[[j]]$MSE
					MSRs[j] = partGLS[[j]]$MSR
					Fstats[j] = partGLS[[j]]$Fstat
					Fpvals[j] = partGLS[[j]]$pval_F
				}
				
				print(paste('Npart ', j, 'File ', currentIt))
				print(Sys.time() - START_TIME)
				Vij = do.call(covar.f, args = append(list(d = dist.f(icoords, jcoords)), list(range = rng)))
				dfs = remotePARTS:::calc_dfpart(partsize = partsize, p = ncol(partGLS[[j]]$xx), p0 = ncol(partGLS[[j]]$xx0))
				#print(dfs)
				
				print(paste('CovMatrix and df, parts ', i, 'and ', j))
				print(Sys.time() - START_TIME)
				
				rGLS = remotePARTS:::crosspart_GLS(xxi = partGLS[[i]]$xx, xxj = partGLS[[j]]$xx, xxi0 = partGLS[[i]]$xx0, xxj0 = partGLS[[j]]$xx0, invChol_i = partGLS[[i]]$invcholV, invChol_j = partGLS[[j]]$invcholV, Vsub = Vij, nug_i = partGLS[[i]]$nugget, nug_j = partGLS[[j]]$nugget, df1 = dfs[1], df2 = dfs[2], small = FALSE)
				print(paste('crosspart, parts ', i, 'and ', j))
				print(Sys.time() - START_TIME)
				
				
				quit()
			}
		}
	}
	quit()
	
t.test.partGLS <- function(x, ...){
  part_ttest(coefs = x$overall$coefficients,
                  part.covar_coef = x$part$covar_coef,
                  rcoefficients = x$overall$rcoefficients,
                  df2 = x$overall$dfs[2],
                  npart = x$overall$partdims["npart"])
}
								  
								  
			
			# save an outlist with all vars required for cross t test!
				## collect and format output
		#outlist = list(call = call,
		#               GLS = if(save.GLS){partGLS}else{NULL},
		#               part = list(coefficients = coefs, SEs = SEs,
		#                           covar_coefs = covar_coefs, tstats = tstats,
		#                           pvals_t = tpvals, nuggets = nuggets,
		#                           covar.pars = covar.pars,
		#                           modstats = cbind(LLs = LLs, SSEs = SSEs,
		#                                            MSEs = MSEs, MSRs = MSRs,
		#                                            Fstats = Fstats,
		#                                            pvals_F = Fpvals)),
		#               cross = list(rcoefs = rcoefs, rSSRs = rSSRs, rSSEs = rSSEs),
		#               overall = list(coefficients = colMeans(coefs, na.rm = TRUE),
		#                              # rcoefficients = colMeans(rcoefs, na.rm = TRUE),
		#                              rcoefficients =rcoefficients,
		#                              rSSR = mean(rSSRs, na.rm = TRUE),
		#                              rSSE = mean(rSSEs, na.rm = TRUE),
		#                              Fstat = mean(Fstats, na.rm = TRUE),
		#                              dfs = calc_dfpart(partsize, p, p0),
		#                              partdims = c(npart = npart, partsize = partsize)))
			
		  print(attributes(partGLS[[i]]))
		  print(partGLS[[i]]$coefficients)
		  print(partGLS[[i]]$covar_coef)
		  print(partGLS[[i]]$rcoefficients)
		  print(partGLS[[i]]$dfs[2])
		  print(partGLS[[i]]$partdims["npart"])
		  
		  saveRDS(partGLS, file = partGLS_savepath)
		  
		  #partgls partition returns  fitGLS_partition’ returns a list object of class "partGLS" which
		  #contains at least the following elements:
		  #tteststats = remotePARTS:::t.test.partGLS(partGLS[[i]])
		  #print(tteststats)
		  quit()

		
# save data only required for correlated ttest
		
		## correlated t-test
	#' @title Correlated t-test for paritioned GLS
	#' @param coefs vector average GLS coefficients
	#' @param part.covar_coef an array of covar_coef from each partition
	#' @param rcoefficients an rcoefficeints array, one for each partition
	#' @param df2 second degree of freedom from partitioned GLS
	#' @param npart number of partitions
	#'
	#' @return a list whose first element is a coefficient table with estimates,
	#' standard errors, t-statistics, and p-values and whose second element is a
	#' matrix of correlations among coefficients.
	#part_ttest <- function(coefs, part.covar_coef, rcoefficients, df2, npart){


	#original gls used
	#fitted_GLS = fitGLS_partition(formula = "coef ~ 1", file = path,
	#					coord.names = c("Long", "Lat"), partmat = partition_matrix, part_FUN = 'part_csv',
	#					covar_FUN = "covar_exp", covar.pars = list(range = rng), nugget = ngt, distm_FUN = "distm_scaled", ncross = 6,
	#					save.GLS = FALSE, do.t.test = FALSE, do.chisqr.test = FALSE, ncores = core_num, parallel = TRUE, progressbar = FALSE) # progressbar ignored if parallel = TRUE

						
			# save each!
}
quit()
saveRDS(partGLS, file = partGLS_savepath)



                   overall = list(coefficients = colMeans(coefs, na.rm = TRUE),
                                  # rcoefficients = colMeans(rcoefs, na.rm = TRUE),
                                  rcoefficients =rcoefficients,
                                  rSSR = mean(rSSRs, na.rm = TRUE),
                                  rSSE = mean(rSSEs, na.rm = TRUE),
                                  Fstat = mean(Fstats, na.rm = TRUE),
                                  dfs = calc_dfpart(partsize, p, p0),
                                  partdims = c(npart = npart, partsize = partsize)))
								  
								  

#fitted_GLS = fitGLS_partition(formula = "coef ~ 1", file = path,
#					coord.names = c("Long", "Lat"), partmat = partition_data, part_FUN = 'part_csv',
#					covar_FUN = "covar_exp", covar.pars = list(range = rng), nugget = ngt, distm_FUN = "distm_scaled", ncross = 32,
#					save.GLS = FALSE, do.t.test = TRUE, do.chisqr.test = TRUE, ncores = core_num, parallel = TRUE, progressbar = TRUE) # progressbar ignored if parallel = TRUE
#
#part_FUN = "part_data",
#                             distm_FUN = "distm_scaled", covar_FUN = "covar_exp",
#  part.f <- match.fun(part_FUN)
#  dist.f <- match.fun(distm_FUN)
#  covar.f <- match.fun(covar_FUN)
#  for(i in 1:npart){
#idat <- part.f(partmat[, i], formula = formula, formula0 = formula0, ...)
#fitGLS(save.xx = TRUE, save.invchol = TRUE, no.F = FALSE)).
#
#then: read gls, what do i need from the gls?
#
#
#then: crosspart_GLS(()
#
#then: test
#
#saveRDS(fitted_GLS, file = GLS_save_file)
#print(Sys.time() - start_t)
#
##fitted_GLS = readRDS(GLS_save_file)
#print(fitted_GLS)