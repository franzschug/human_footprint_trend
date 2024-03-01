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
  fileSub = args[1]
  range_path = args[2]
  nugget_path = args[3]
  gls_outdir = args[4]
  intermediate_res_outdir = args[5]
}

START_TIME = Sys.time()

# ____ Setup ____
currentIt = as.numeric(gsub("\\D", "", fileSub))

partGLS_savepath = paste(gls_outdir, 'gls_part_', currentIt, '.rds', sep = "", collapse = NULL)
if(!dir.exists(gls_outdir)){dir.create(gls_outdir)}
print(partGLS_savepath)
#load range
rng_temp = read.csv(range_path, na.strings = "NA", header=FALSE, sep=',')
rng = median(as.numeric(unlist(rng_temp)))

#load nugget
ngt_temp = read.csv(nugget_path, na.strings = "NA", header=FALSE, sep=',')
ngt = median(as.numeric(unlist(ngt_temp)))

# define formulas
form = 'coef ~ 1'
form0 = 'coef ~ 1'

partition_data = readRDS(fileSub)
#print(partition_data)
#print(head(partition_data[[1]]))
#print(head(partition_data[[2]]))

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

###### LIMITED TO 6 PARTS FOR TEST PURPOSES
npart = 6


for(i in 1:npart){	
	partsize = nrow(partition_data[[i]])
	print('part')
	print(i)
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
		
		#print(head(covar_coefs))
		#print(paste('Npart ', i, 'File ', currentIt))
		#print(Sys.time() - START_TIME)
	}
		
	if (i < ncross){
		print('i<cross')
		for (j in (i+1):ncross) { 
			print('j')
			print(j)
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
			
			#print(paste('Npart ', j, 'File ', currentIt))
			#print(Sys.time() - START_TIME)
			Vij = do.call(covar.f, args = append(list(d = dist.f(icoords, jcoords)), list(range = rng)))
			dfs = remotePARTS:::calc_dfpart(partsize = partsize, p = ncol(partGLS[[j]]$xx), p0 = ncol(partGLS[[j]]$xx0))
			#print(dfs)
			
			#print(paste('CovMatrix and df, parts ', i, 'and ', j))
			#print(Sys.time() - START_TIME)
			
			rGLS = remotePARTS:::crosspart_GLS(xxi = partGLS[[i]]$xx, xxj = partGLS[[j]]$xx, xxi0 = partGLS[[i]]$xx0, xxj0 = partGLS[[j]]$xx0, invChol_i = partGLS[[i]]$invcholV, invChol_j = partGLS[[j]]$invcholV, Vsub = Vij, nug_i = partGLS[[i]]$nugget, nug_j = partGLS[[j]]$nugget, df1 = dfs[1], df2 = dfs[2], small = FALSE)
			
			cross = which( (cross.pairs[,1] == i) & (cross.pairs[, 2] == j) )
			rcoefs[cross, ,] <- rGLS$rcoefij
			rSSRs[cross] <- ifelse(is.na(rGLS$rSSRij) | is.infinite(rGLS$rSSRij), NA, rGLS$rSSRij)
			rSSEs[cross] <- rGLS$rSSEij
			print('cross')
			print(cross)
			print(rSSEs[cross])
			print(rSSEs)
			print(rSSRs[cross])
			print(rSSRs)
			print(Fstats)
			print(paste('crosspart, parts ', i, 'and ', j))
			print(Sys.time() - START_TIME)
				
		}
	}
}	

print(rcoefs)
rcoefficients = apply(rcoefs, MARGIN=c(2,3), FUN = function(x){mean(x, na.rm = TRUE)})
print(rcoefficients)
dfs = remotePARTS:::calc_dfpart(partsize, p, p0)

saveRDS(coefs, file = paste(intermediate_res_outdir, 'coefs_', currentIt, '.rds', sep = "", collapse = NULL))
saveRDS(covar_coefs, file = paste(intermediate_res_outdir, 'covar_coefs_', currentIt, '.rds', sep = "", collapse = NULL))
saveRDS(rcoefficients, file = paste(intermediate_res_outdir, 'rcoefs_', currentIt, '.rds', sep = "", collapse = NULL))
saveRDS(dfs, file = paste(intermediate_res_outdir, 'dfs_', currentIt, '.rds', sep = "", collapse = NULL))
saveRDS(npart, file = paste(intermediate_res_outdir, 'npart_', currentIt, '.rds', sep = "", collapse = NULL))
saveRDS(rSSRs, file = paste(intermediate_res_outdir, 'rssr_', currentIt, '.rds', sep = "", collapse = NULL))
saveRDS(rSSEs, file = paste(intermediate_res_outdir, 'rsse_', currentIt, '.rds', sep = "", collapse = NULL))
saveRDS(Fstats, file = paste(intermediate_res_outdir, 'fstat_', currentIt, '.rds', sep = "", collapse = NULL))
quit()