#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

### split dataset into partitions of 2,000 elements each. group partitions into files of 2,000,000 elements max.
### arg1: path to input dataset
### arg2: path to save partition matrix (input if existing, output if not existing), needs to match input dataset!
### arg3: output dir to save partition matrix
#Rscript ./090_scripts/parts_split_partitions.R  ./011_data/hii/v1/ar_coeff_pv/csv/hii_global_reduced_subset_5million.csv ./011_data/parts/pm/pm_global_300m_5million.rds ./011_data/parts/pm/gls_300m_subpm/

### collect all part files
fileArr=()
for file in ./011_data/parts/pm/gls_300m_subpm/rds/*
	do
	  fileArr+=($file)
	done

### fit GLS to parts NOTE NOTE NOTE: Currently, no parallelization. only first file, i.e. first 2m points, i.e. 1,000 partitions, are computed 
### arg1: path of part
### arg2: path to range estimates
### arg3: path to nugget estimates
Rscript ./090_scripts/parts_split_gls.R ./011_data/parts/pm/gls_300m_subpm/rds/sub_partition_data_1.rds ./011_data/parts/alls_spcors.txt ./011_data/parts/alls_nuggets.txt
### FIX FIX TODO TODO parallel -j 30 Rscript ./090_scripts/parts_split_gls.R ::: ${fileArr[@]} ./011_data/parts/alls_spcors.txt ./011_data/parts/alls_nuggets.txt
  
### merge results from all parts
#Rscript ./090_scripts/parts_split_analysis.R