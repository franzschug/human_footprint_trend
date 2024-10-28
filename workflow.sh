#!/bin/bash

jbs=20

## Working directory
WORKDIR='/data/FS_human_footprint'

## Merge HII tiles from GG Earth Engine DL
MERGEHII=FALSE

## Tile annual HII data to 5x5 degrees for faster IO
TILE=FALSE

## Stack annual HII clips time series
STACK=FALSE

## Conduct pixel-wise trend analysis to time series stacks
FITAR=FALSE

## Estimate  spatial autocorrelation parameters, range and nugget
EST_AUTOCORR_PRM=FALSE

## Prepare, tile independent variables
PREPINDEP=FALSE
indep_dir=( '011_data/countries' '011_data/dhi' '011_data/wdpa' '011_data/ecoregions' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/wui' '011_data/gdp' '011_data/gdp' '011_data/gdp' '011_data/gdp' '011_data/continent' '011_data/biomes' ) 
indep_name=( 'countries' 'cumDHI' 'wdpa_prox' 'ecoregions' 'sumTotalMammals_300' 'sumTotalBirds_300' 'sumTotalAmphibians_300' 'sumTotalReptiles_300' 'sumTotalMammals_crit_300' 'sumTotalBirds_crit_300' 'sumTotalAmphibians_crit_300' 'sumTotalReptiles_crit_300' 'global_wui_sum_Int16' 'gdp_1990' 'gdp_2015' 'gdp_change' 'gdp_rel_change' 'continents' 'biomes' )
#col_names=( 'Long' 'Lat' 'coef' 'pval' 'country' 'cumdhi' 'wdpa' 'eco' 'mam' 'brid' 'amph' 'rept' 'wui' 'gdp90' 'gdp15' 'gdpch' 'gdprelch' 'contin' )
index=( 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 )
ar_name=( 'long' 'lat' 'coeff' 'pval' )
ar_index=( 0 1 2 3 )
	
## Merge pixel-wise trend with independent variables
MERGEINDEP=FALSE

## Prepare csv for remotePARTS
PREPCSV=FALSE

FILTER=FALSE
## Restrict analysis to a subset of the data
USE_FILTERED=TRUE
FILTER_SUBSET_PERCENT="1"
MIN_CAT='0' # Value from l. 26
MIN_DATA_PER_CAT=20000
INPUT_EXTENSION=''
FILTER_CAT=''
FILTER_VALUE=''
USE_EX_INDICES=TRUE # Use existing index file

# TODO IMPLEMENT
#FILTER_DATA_ARE_CAT=[ 'continents' ] # Value from l 26
#FILTER_DATA_ARE_CRIT=[ 1 ]
#FILTER_DATA_NOT_CAT=[ 3 ]
#FILTER_DATA_NOT_CRIT=[ 3 ]

## Generate partition matrix for complete dataset
PARTITIONMATRIX=FALSE
WRITE_OPT_CSV=ALL #ALL, TEST, NONE

## Split data into randomized partitions
PARTITION=FALSE
WRITE_OPT_CSV=ALL #ALL, TEST, NONE

## Perform split GLS
SPLITGLS=TRUE

## Analyse split GLS results
SPLITANALYSIS=FALSE

## Merge split GLS results
MERGERESULT=FALSE


MAP_CHANGE=FALSE

if [ $MERGEHII == TRUE ] ; then
	years=( 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 )
	for i in "${years[@]}"; do
		mkdir -p $WORKDIR'/010_raw_data/hii/v1/'$i'/'
		gdalwarp -srcnodata -32768 -dstnodata -32768 $WORKDIR'/010_raw_data/hii/v1/'$i'/'*'.tif' $WORKDIR'/010_raw_data/hii/v1/'$i'-01-01_hii_'$i'-01-01.vrt'
	done
fi

if [ $TILE == TRUE ] ; then
	years=( 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 )

	for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			echo $COUNTERX
			xend=$(($COUNTERX+5))
			yend=$(($COUNTERY-5))
					
			printf %s\\n "${years[@]}" | parallel --jobs $jbs gdal_translate -projwin $COUNTERX $COUNTERY $xend $yend -of VRT -a_nodata -32768 $WORKDIR'/010_raw_data/hii/v1/'{}'-01-01_hii_'{}'-01-01.vrt' $WORKDIR'/011_data/hii/v1/'{}'/hii_'$COUNTERX'_'$COUNTERY'.vrt'
		done
	done
fi

if [ $STACK == TRUE ] ; then
	years=( 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 )
	mkdir -p $WORKDIR/011_data/hii/v1/00_stack;
	
	for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			xend=$(($COUNTERX+5))
			yend=$(($COUNTERY-5))
			
			echo $COUNTERX
			echo $COUNTERY
			fileArr=()
			
			for y in "${years[@]}"
			do
				fileArr+=($WORKDIR'/011_data/hii/v1/'$y'/hii_'$COUNTERX'_'$COUNTERY'.vrt')
			done
			
			printf "%s\n" "${fileArr[@]}" > $WORKDIR'/011_data/hii/v1/00_stack/list_temp.txt'
			
			gdalbuildvrt -separate $WORKDIR'/011_data/hii/v1/00_stack/hii_'$COUNTERX'_'$COUNTERY'.vrt' -input_file_list $WORKDIR'/011_data/hii/v1/00_stack/list_temp.txt'

			rm $WORKDIR'/011_data/hii/v1/00_stack/list_temp.txt'
		done
	done
fi

if [ $FITAR == TRUE ] ; then
	for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			echo $COUNTERX
			echo $COUNTERY
			Rscript $WORKDIR'/090_scripts/parts_fitar.R' $WORKDIR $COUNTERX $COUNTERY
		done
	done
fi

if [ $EST_AUTOCORR_PRM == TRUE ] ; then
	# Randomly sample n tiles, n pixels per tile, and n iterations
	sample_tiles=800  	## Number of tiles to be randomly chosen for analysis
	n_per_tile=3000		## Number of pixels considered within each tile
	iterations=3		## Analysis is performed n times per tile
	extent=5			## Tile extent in degrees
	
	# Outpath for all parameter estimates
	outFileSPCORS=$WORKDIR'/011_data/parts/alls_spcors_abs.txt'
	outFileNUGGET=$WORKDIR'/011_data/parts/alls_nuggets.txt'
	outDirSPCORS=$WORKDIR'/011_data/parts/cor/'
	
	# Input directories of AR estimates, residuals, and original data
	dir=$WORKDIR'/011_data/hii/v1/ar_all/'
	dirstack=$WORKDIR'/011_data/hii/v1/00_stack/'
	
	# Estiamte range parameter, shuf - shuffle, tail - last elements
	ls $dir | grep .tif | shuf | tail -$sample_tiles | parallel -j $jbs Rscript $WORKDIR'/090_scripts/parts_fitcor.R' $dir $n_per_tile $iterations $outFileSPCORS $outDirSPCORS $extent {}
	
	# Estimate nugget parameter
	nr_samples=5000
	save_dir=$WORKDIR'/011_data/parts/gls/'
	
	#ls $dir | grep .tif | shuf |tail -$sample_tiles | parallel -j $jbs Rscript $WORKDIR'/090_scripts/parts_estimate_nugget.R' $dir $dirstack $nr_samples $outFileSPCORS $outFileNUGGET $save_dir {}
	
	#python3 $WORKDIR'/090_scripts/plots/00_distribution_range.py'
	#python3 $WORKDIR'/090_scripts/plots/00_distribution_nugget.py'
fi

if [ $PREPINDEP == TRUE ] ; then
	for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			echo $COUNTERX
			echo $COUNTERY
			
			xend=$(($COUNTERX+5))
			yend=$(($COUNTERY-5))
			
			# Check if directories and names have different length
			if [ ! "${#indep_dir[@]}" -eq "${#indep_name[@]}" ]; then
			  echo "List of directories and list of names have different length!"
			  break
			fi

			for p in $(seq 1 ${#indep_dir[@]}); do
				i=$(($p - 1))
				echo ${indep_dir[$i]}
				echo ${indep_name[$i]}
				echo $WORKDIR'/'${indep_dir[$i]}'/'${indep_name[$i]}'.tif'
				echo $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_'$COUNTERX'_'$COUNTERY.vrt
				gdal_translate -projwin $COUNTERX $COUNTERY $xend $yend -of VRT -ot Int32 -a_nodata -999 $WORKDIR'/'${indep_dir[$i]}'/'${indep_name[$i]}'.tif' $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_'$COUNTERX'_'$COUNTERY.vrt
			done
		done
	done
	
	# Write Geotiff for one example tile
	for p in $(seq 1 ${#indep_dir[@]}); do
		i=$(($p - 1))
		gdalwarp $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_-95_40.vrt' $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_-95_40.tif'
	done
fi

if [ $MERGEINDEP == TRUE ] ; then
	for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			echo $COUNTERX
			echo $COUNTERY
			
			elements=()
			
			hii_file=$WORKDIR'/011_data/hii/v1/ar_coeff_pv/hii_'$COUNTERX'_'$COUNTERY'.tif'
			
			if [ -e "$hii_file" ]; then
				echo "File exists. Proceeding with merge."
				elements+=$hii_file
			
				for p in $(seq 1 ${#indep_dir[@]}); do
					i=$(($p - 1))
					elements+=("$WORKDIR/${indep_dir[$i]}/tiles/${indep_name[$i]}_"$COUNTERX"_"$COUNTERY".vrt")
				done
				gdal_merge.py -o $WORKDIR'/011_data/hii/v1/merged_ar_ind/hii_'$COUNTERX'_'$COUNTERY'_ind.tif' -co "COMPRESS=LZW" -separate "${elements[@]}"
			
			else
				echo "HII does not exist. Exiting."
			fi
		done
	done
fi

if [ $PREPCSV == TRUE ] ; then	
	# Translate tif to csv
	#ls $WORKDIR'/011_data/hii/v1/merged_ar_ind' | grep '_ind.tif' | parallel -j $jbs gdal2xyz.py -allbands $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{} $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{}'_temp.csv'
	
	#combinedVars=("${ar_name[@]}" "${indep_name[@]}")
	#namesStr=$(IFS=','; echo "${combinedVars[*]}")
	
	# Remove no data lines
	#ls $WORKDIR'/011_data/hii/v1/merged_ar_ind' | grep '_temp.csv' | parallel -j $jbs python3 $WORKDIR'/090_scripts/prep_csv_for_partGLS.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{} $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{}'_nona.csv' $namesStr
	
	# Remove originals
	#ls $WORKDIR'/011_data/hii/v1/merged_ar_ind' | grep '_temp.csv\b' | parallel -j $jbs rm $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{}
	
	parallel -j $jbs python3 $WORKDIR'/090_scripts/merge_in_columns_for_global_analysis.py' $WORKDIR'/011_data/hii/v1/	d_ar_ind/' $WORKDIR'/011_data/hii/v1/merged_ar_ind/global/' ::: "${indep_name[@]}"  :::+ "${index[@]}"
	
	#parallel -j $jbs python3 $WORKDIR'/090_scripts/merge_in_columns_for_global_analysis.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/' $WORKDIR'/011_data/hii/v1/merged_ar_ind/global/' ::: "${ar_name[@]}"  :::+ "${ar_index[@]}"
	
	### Write Geotiff for one example tile for all datasets
	#for p in $(seq 1 ${#indep_dir[@]}); do
	#	i=$(($p - 1))
	#	gdalwarp $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_-95_40.vrt' $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_-95_40.tif'
	#done
	
fi

if [ $FILTER == TRUE ] ; then
	if [ $FILTER_SUBSET_PERCENT != 0 ] ; then
		python3 $WORKDIR'/090_scripts/filter_percent.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/global/' $FILTER_SUBSET_PERCENT $MIN_CAT $MIN_DATA_PER_CAT $USE_EX_INDICES
	fi
fi

if [ $PARTITIONMATRIX == TRUE ] ; then
	global_vrt_outpath=$WORKDIR'/011_data/hii/v1/merged_hii_ind.vrt'
	
	if [ $USE_FILTERED == TRUE ] ; then
		file_path=$WORKDIR/011_data/hii/v1/merged_ar_ind/global/filtered_1pc/${indep_name[0]}.csv
	else
		file_path=$WORKDIR/011_data/hii/v1/merged_ar_ind/global/${indep_name[0]}.csv
	fi
	
	pm_path=$WORKDIR'/011_data/parts/pm/filtered_1pc'
	partition_size=2000
	max_col_per_part=8000
	
	num_lines=$(wc -l < "$file_path")
	#ls $WORKDIR'/011_data/hii/v1/merged_ar_ind/'*.tif > $WORKDIR'/011_data/hii/v1/list_temp.txt'			
	#gdalbuildvrt $global_vrt_outpath -input_file_list $WORKDIR'/011_data/hii/v1/list_temp.txt'
	#rm $WORKDIR'/011_data/hii/v1/list_temp.txt'
	
	Rscript $WORKDIR'/090_scripts/parts_generate_pm.R' $num_lines $pm_path $partition_size $max_col_per_part
fi

if [ $PARTITION == TRUE ] ; then
	
	#file_extension=''
	sub_pm_outdir=$WORKDIR'/011_data/parts/data/'

	pm_paths=$(ls $WORKDIR/011_data/parts/pm/filtered_1pc/rds/global_partition_*)
	directory='filtered_1pc'

	combinedVars=("${ar_name[@]}" "${indep_name[@]}")
	namesStr=$(IFS=','; echo "${combinedVars[*]}")
	
	for path in $pm_paths; do
		echo $path
		Rscript $WORKDIR'/090_scripts/parts_split_partitions.R' $WORKDIR'/011_data/hii/v1/merged_ar_ind/global/'$directory'/' $path $namesStr $sub_pm_outdir $directory
	done

	# TODO For filter, use file extension from previous block
	
fi

#if [ $SPLITGLS == TRUE ] ; then
#perform vif and warn!
#print if vif high
#	confirmVIF=TRUE # If independent variables highly correlated accoding to VIF, stop to confirm
#	
#fi

#if [ $SPLITANALYSIS == TRUE ] ; then
#
#fi
#
#
#if [ $MERGERESULT == TRUE ] ; then
#
#fi

	
		
#- output correlation matrix, variance inflation factor test. then select!
# write vif new - with subset of the data




if [ $MAP_CHANGE == TRUE ] ; then
	for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			python3 $WORKDIR'/090_scripts/00_change/001_zonal_stats_hii_total.py' $COUNTERX $COUNTERY
		done
	done
fi