#!/bin/bash

## Restrict analysis to a subset of the data
CASE_NAME='global'
FILTER_SUBSET_PERCENT="1.0"
MIN_CAT='continents' # Value from l. 26
MIN_DATA_PER_CAT=100000
SPLIT_BY_CAT=FALSE
#INPUT_EXTENSION=''
#FILTER_CAT=''
#FILTER_VALUE=''
USE_EX_INDICES=FALSE # Use existing index file

# TODO IMPLEMENT
#FILTER_DATA_ARE_CAT=[ 'continents' ] # Value from l 26
#FILTER_DATA_ARE_CRIT=[ 1 ]
#FILTER_DATA_NOT_CAT=[ 3 ]
#FILTER_DATA_NOT_CRIT=[ 3 ]


# TODO
CHECK_VIF=FALSE ## Print variance inflation factors for dependent variables
VIF_SAMPLES=400 ### Run VIF on n partitions
VIF_CHECK=( 'cumDHI' 'wdpa_prox' 'sumTotalMammals_300' 'sumTotalBirds_300' 'sumTotalAmphibians_300' 'sumTotalReptiles_300' 'sumTotalMammals_crit_300' 'sumTotalBirds_crit_300' 'sumTotalAmphibians_crit_300' 'sumTotalReptiles_crit_300' 'global_wui_sum_Int16' 'gdp_2015' 'gdp_change' 'gdp_rel_change' )
PRINT_CORMATRIX=FALSE ## Print variance inflation factors for dependent variables



if [ $FILTER == TRUE ] ; then
	if [ $FILTER_SUBSET_PERCENT != 0 ] ; then
		
		#total_lines=$(wc -l < input.csv)
		#half_lines=$((total_lines / 2))
		#shuf -n $half_lines input.csv > output.csv
		
		python3 $WORKDIR'/090_scripts/filter_percent.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/global/' $CASE_NAME $FILTER_SUBSET_PERCENT $MIN_CAT $MIN_DATA_PER_CAT $SPLIT_BY_CAT $USE_EX_INDICES
	fi
fi


if [ $CHECK_VIF == TRUE ] ; then

	PM_PATH=$WORKDIR'/011_data/parts/data/rds/data_part' # Path to partition data

	sample_partitions=$(ls $PM_PATH'.'* | grep .rds | shuf | tail -$VIF_SAMPLES)
	echo $sample_partitions
	Rscript $WORKDIR'/090_scripts/variance_inflation_factor.R' ${#VIF_CHECK[@]} ${VIF_CHECK[@]} $sample_partitions
	
#perform vif and warn!
#print if vif high
#	confirmVIF=TRUE # If independent variables highly correlated accoding to VIF, stop to confirm
fi