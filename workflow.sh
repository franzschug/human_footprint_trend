#!/bin/bash

jbs=20

## Working directory
WORKDIR='/data/FS_human_footprint'

## Merge HII tiles from GG Earth Engine DL // does not apply to most recent version (global mosaics delivered by N. Robinson)!
MERGEHII=FALSE

## Tile annual HII data to 5x5 degrees for faster IO
TILEHII=FALSE

## Stack annual time series of HII tiles 
STACK=FALSE

## Conduct pixel-wise trend analysis for time series stacks
FITAR=FALSE

## Estimate  spatial autocorrelation parameters, range and nugget
EST_AUTOCORR_PRM=FALSE

## Prepare, tile independent variables (create tiles)
PREPINDEP=FALSE
indep_dir=( '011_data/countries' '011_data/dhi' '011_data/wdpa' '011_data/ecoregions' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/wui' '011_data/gdp' '011_data/gdp' '011_data/gdp' '011_data/gdp' '011_data/continent' '011_data/biomes' '011_data/wdpa' ) 
indep_name=( 'countries' 'cumDHI' 'wdpa_prox' 'ecoregions' 'sumTotalMammals_300' 'sumTotalBirds_300' 'sumTotalAmphibians_300' 'sumTotalReptiles_300' 'sumTotalMammals_crit_300' 'sumTotalBirds_crit_300' 'sumTotalAmphibians_crit_300' 'sumTotalReptiles_crit_300' 'global_wui_sum_Int16' 'gdp_1990' 'gdp_2015' 'gdp_change' 'gdp_rel_change' 'continents' 'biomes' 'wdpa_categories' )
index=( 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 )
ar_name=( 'long' 'lat' 'coeff' 'pval' )
ar_index=( 0 1 2 3 )
	
## Merge pixel-wise trend layer with independent variables for tiles
MERGEINDEP=FALSE

## Prepare csv from stacked images for remotePARTS, remove nodata, organize global data by layer
PREPCSV=FALSE

## Extract a subset of the data (and split by continent)
FILTER=FALSE
CASE_NAME='continental' ## CASE_NAME will be used for all further analysis. E.g., 'global' for global analysis, and 'continental' for continental
FILTER_SUBSET_PERCENT="100." # Float
MIN_CAT='continents'
SPLIT_BY_CAT=TRUE

## Generate partition matrix
PARTITIONMATRIX=FALSE
WRITE_OPT_CSV=ALL #ALL, TEST, NONE

## Split data into randomized partitions following the partition matrix
PARTITION=FALSE
WRITE_OPT_CSV=ALL #ALL, TEST, NONE

## Perform split GLS
SPLITGLS=TRUE
PARTITIONS=15000 # Use a subset of partitions. 0 = Use all partitions.
FORMULA='coeff~1+wdpa_prox+wdpa_prox*ecoregions' # e.g., 'coeff ~ 1', 'coeff~1+ecoregions+biomes+countries', 'coeff~1+wdpa_prox+wdpa_prox*ecoregions', 'coeff~1+wdpa_categories', 'coeff~1+wdpa_prox*ecoregions'
FORMULA0='coeff~1' # e.g., 'coeff ~ 1'
FORMID='wdpaprox' # For model id in file structure, e.g., '' for intercept-only

## Perform GLS cross comparisons
SPLITCROSS=FALSE
NCROSSFILES=20

## Analyse and merge split GLS results
SPLITANALYSIS=FALSE




if [ $MERGEHII == TRUE ] ; then
	years=( 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 )
	for i in "${years[@]}"; do
		mkdir -p $WORKDIR'/010_raw_data/hii/v1/'$i'/'
		gdalwarp -srcnodata -32768 -dstnodata -32768 $WORKDIR'/010_raw_data/hii/v1/'$i'/'*'.tif' $WORKDIR'/010_raw_data/hii/v1/'$i'-01-01_hii_'$i'-01-01.vrt'
	done
fi

if [ $TILEHII == TRUE ] ; then
	years=( 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 )

	for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			echo $COUNTERX
			xend=$(($COUNTERX+5))
			yend=$(($COUNTERY-5))
					
			printf %s\\n "${years[@]}" | parallel --jobs $jbs gdal_translate -projwin $COUNTERX $COUNTERY $xend $yend -of VRT -a_nodata -32768 $WORKDIR'/010_raw_data/hii/v1/hii_'{}'-01-01.tif' $WORKDIR'/011_data/hii/v1/'{}'/hii_'$COUNTERX'_'$COUNTERY'.vrt'
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
	
	#gdalwarp '/data/FS_human_footprint/011_data/hii/v1/00_stack/hii_0_50.vrt' '/data/FS_human_footprint//011_data/hii/v1/00_stack/hii_0_50.tif'
fi

if [ $FITAR == TRUE ] ; then
	for (( COUNTERX=-65; COUNTERX<=175; COUNTERX+=5 )); do
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
	
	# Estimate range parameter, shuf - shuffle, tail - last elements
	#ls $dir | grep .tif | shuf | tail -$sample_tiles | parallel -j $jbs Rscript $WORKDIR'/090_scripts/parts_fitcor.R' $dir $n_per_tile $iterations $outFileSPCORS $outDirSPCORS {}
	
	# Estimate nugget parameter
	nr_samples=5000
	save_dir=$WORKDIR'/011_data/parts/gls/'
	
	#ls $dir | grep .tif | shuf |tail -$sample_tiles | parallel -j $jbs Rscript $WORKDIR'/090_scripts/parts_estimate_nugget.R' $dir $dirstack $nr_samples $outFileSPCORS $outFileNUGGET $save_dir {}
	
	python3 $WORKDIR'/090_scripts/plots/00_distribution_range.py'
	python3 $WORKDIR'/090_scripts/plots/00_distribution_nugget.py'
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
	
	combinedVars=("${ar_name[@]}" "${indep_name[@]}")
	namesStr=$(IFS=','; echo "${combinedVars[*]}")
	
	# Remove no data lines
	#ls $WORKDIR'/011_data/hii/v1/merged_ar_ind' | grep '_temp.csv' | parallel -j $jbs python3 $WORKDIR'/090_scripts/prep_csv_for_partGLS.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{} $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{}'_nona.csv' $namesStr

	# Remove originals
	#ls $WORKDIR'/011_data/hii/v1/merged_ar_ind' | grep '_temp.csv\b' | parallel -j $jbs rm $WORKDIR'/011_data/hii/v1/merged_ar_ind/'{}

	#parallel -j $jbs python3 $WORKDIR'/090_scripts/merge_in_columns_for_global_analysis.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/' $WORKDIR'/011_data/hii/v1/merged_ar_ind/global/' ::: "${indep_name[@]}"  :::+ "${index[@]}"
	
	#parallel -j $jbs python3 $WORKDIR'/090_scripts/merge_in_columns_for_global_analysis.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/' $WORKDIR'/011_data/hii/v1/merged_ar_ind/global/' ::: "${ar_name[@]}"  :::+ "${ar_index[@]}"
	
	### Write Geotiff for one example tile for all datasets
	#for p in $(seq 1 ${#indep_dir[@]}); do
	#	i=$(($p - 1))
	#	#gdalwarp $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_-90_40.vrt' $WORKDIR'/'${indep_dir[$i]}'/tiles/'${indep_name[$i]}'_-90_40.tif'
	#	gdalwarp '/data/FS_human_footprint/011_data/wui/tiles/global_wui_sum_Int16_-85_40.vrt' '/data/FS_human_footprint/011_data/wui/tiles/global_wui_sum_Int16_-85_40.tif'
	#done
	
fi

if [ $FILTER == TRUE ] ; then
	if [ $FILTER_SUBSET_PERCENT != 0 ] ; then
		python3 $WORKDIR'/090_scripts/filter_percent.py' $WORKDIR'/011_data/hii/v1/merged_ar_ind/' $CASE_NAME $FILTER_SUBSET_PERCENT $MIN_CAT $SPLIT_BY_CAT 1
	fi
fi

if [ $PARTITIONMATRIX == TRUE ] ; then
	
	partition_size=2000
	max_col_per_part=8000
	
	# If multiple categories (continents)
	if [ "$CASE_NAME" != "global" ]; then
		mapfile -t lines < $WORKDIR'/011_data/hii/v1/merged_ar_ind/'$CASE_NAME'/categories.txt'

		for line in "${lines[@]}"; do
			echo "Processing line: $line"
			file_path=$WORKDIR/011_data/hii/v1/merged_ar_ind/$CASE_NAME/${indep_name[0]}_$line.csv
			pm_path=$WORKDIR'/011_data/parts/pm/'$CASE_NAME'_'$line'/'
			num_lines=$(wc -l < "$file_path")
			
			echo $num_lines
			Rscript $WORKDIR'/090_scripts/parts_generate_pm.R' $num_lines $pm_path $partition_size $max_col_per_part
		done

	# If only one category (global)
	else
		file_path=$WORKDIR/011_data/hii/v1/merged_ar_ind/$CASE_NAME/${indep_name[0]}.csv
		pm_path=$WORKDIR'/011_data/parts/pm/'$CASE_NAME
		num_lines=$(wc -l < "$file_path")
		
		echo $num_lines
		Rscript $WORKDIR'/090_scripts/parts_generate_pm.R' $num_lines $pm_path $partition_size $max_col_per_part
	fi

fi

if [ $PARTITION == TRUE ] ; then

	# If multiple categories (continents)
	if [ "$CASE_NAME" != "global" ]; then
		mapfile -t lines < $WORKDIR'/011_data/hii/v1/merged_ar_ind/'$CASE_NAME'/categories.txt'
		for line in "${lines[@]}"; do
		
			echo "Processing line: $line"
			sub_pm_outdir=$WORKDIR'/011_data/parts/data/'$CASE_NAME'_'$line'/'
			PM_PATH=$WORKDIR'/011_data/parts/pm/'$CASE_NAME'_'$line'/rds/global_partition' # Path to partition data
			pm_paths=$(ls $PM_PATH'_'*)
			
			combinedVars=("${ar_name[@]}" "${indep_name[@]}")
			namesStr=$(IFS=','; echo "${combinedVars[*]}")
			
			parallel -j 5 Rscript $WORKDIR'/090_scripts/parts_split_partitions.R' $WORKDIR'/011_data/hii/v1/merged_ar_ind/'$CASE_NAME'/' $namesStr $line $sub_pm_outdir ::: "${pm_paths[@]}"

		done
		
	# If only one category (global)
	else
		sub_pm_outdir=$WORKDIR'/011_data/parts/data/'$CASE_NAME'/'
		PM_PATH=$WORKDIR'/011_data/parts/pm/'$CASE_NAME'/rds/global_partition' # Path to partition data
		pm_paths=$(ls $PM_PATH'_'*)

		combinedVars=("${ar_name[@]}" "${indep_name[@]}")
		namesStr=$(IFS=','; echo "${combinedVars[*]}")
	
		parallel -j 5 Rscript $WORKDIR'/090_scripts/parts_split_partitions.R' $WORKDIR'/011_data/hii/v1/merged_ar_ind/'$CASE_NAME'/' $namesStr '' $sub_pm_outdir ::: "${pm_paths[@]}"
	fi

fi


if [ $SPLITGLS == TRUE ] ; then

	if [ "$CASE_NAME" != "global" ]; then # continental case
		mapfile -t lines < $WORKDIR'/011_data/hii/v1/merged_ar_ind/'$CASE_NAME'/categories.txt'
		for line in "${lines[@]}"; do
			
			echo "Processing line: $line"
			if [ "$PARTITIONS" != 0 ]; then
				ls -p $WORKDIR/011_data/parts/data/$CASE_NAME'_'$line'/rds/' | grep -v / | shuf | head -n $PARTITIONS > $WORKDIR/011_data/parts/data/$CASE_NAME'_'$line/filelist.txt
				
			else
				ls $WORKDIR/011_data/parts/data/$CASE_NAME'_'$line/rds/ > $WORKDIR/011_data/parts/data/$CASE_NAME'_'$line'/filelist.txt'
			fi
			
			parallel -a $WORKDIR/011_data/parts/data/$CASE_NAME'_'$line/filelist.txt -j $jbs Rscript $WORKDIR'/090_scripts/parts_split_gls.R' $WORKDIR'/011_data/parts/data/'$CASE_NAME'_'$line'/rds/' $WORKDIR'/011_data/parts/alls_spcors_abs.txt' $WORKDIR'/011_data/parts/alls_nuggets.txt' $WORKDIR'/011_data/parts/gls_split/'$CASE_NAME'_'$line'_'$FORMID'/' $FORMULA $FORMULA0 {}
		done
		
	else # global case
		if [ "$PARTITIONS" != 0 ]; then
			ls -p $WORKDIR/011_data/parts/data/$CASE_NAME/rds/ | grep -v / | shuf | head -n $PARTITIONS > $WORKDIR/011_data/parts/data/$CASE_NAME/filelist.txt
		else
			ls $WORKDIR/011_data/parts/data/$CASE_NAME/rds/ > $WORKDIR/011_data/parts/data/$CASE_NAME/filelist.txt
		fi
		
		parallel -a $WORKDIR/011_data/parts/data/$CASE_NAME/filelist.txt -j $jbs Rscript $WORKDIR'/090_scripts/parts_split_gls.R' $WORKDIR'/011_data/parts/data/'$CASE_NAME'/rds/' $WORKDIR'/011_data/parts/alls_spcors_abs.txt' $WORKDIR'/011_data/parts/alls_nuggets.txt' $WORKDIR'/011_data/parts/gls_split/'$CASE_NAME'/' $FORMULA $FORMULA0 {}
	fi
fi

if [ $SPLITCROSS == TRUE ] ; then

	## Randomly select nfiles*2 pairs of GLS results
	NCROSSFILES=20 # Desired pairs / 2
	
	if [ "$CASE_NAME" != "global" ]; then # continental case
		mapfile -t lines < $WORKDIR'/011_data/hii/v1/merged_ar_ind/'$CASE_NAME'/categories.txt'
		for line in "${lines[@]}"; do
		
			echo "Processing line: $line"
			folder=$WORKDIR'/011_data/parts/gls_split/'$CASE_NAME'_'$line'_'$FORMID'/'
			output_file=$WORKDIR'/011_data/parts/gls_cross/'$CASE_NAME'_'$line'_'$FORMID'.txt'
			echo $folder
			echo $output_file
			
			# List all files in the folder, shuffle them, and select the first nfiles files
			files=($(ls "$folder" | shuf | head -n $NCROSSFILES))
			
			# Check if there are at least NCROSSFILES files to form NCROSSFILES*2 pairs
			if [ ${#files[@]} -lt $NCROSSFILES ]; then
			  echo "Not enough files to form pairs."
			  exit 1
			fi
			
			# Loop through the files and create pairs
			for ((i=0; i<${#files[@]}; i+=2)); do
				# Check if there is a next file to pair with
				if ((i + 1 < ${#files[@]})); then
					echo "${files[i]} ${files[i+1]}" >> $output_file
				else
					# If there's an odd number of files, the last file won't be paired
					echo "${files[i]}" >> $output_file
				fi
			done
			
			parallel -a $output_file -j $jbs Rscript $WORKDIR'/090_scripts/parts_split_cross.R' $WORKDIR'/011_data/parts/gls_split/'$CASE_NAME'_'$line'_'$FORMID'/' {} $WORKDIR'/011_data/parts/data/'$CASE_NAME'_'$line'/rds/' $WORKDIR'/011_data/parts/gls_cross/'$CASE_NAME'_'$line'_'$FORMID'/' $WORKDIR'/011_data/parts/alls_spcors_abs.txt'

		done
		
	else # global case
		folder=$WORKDIR'/011_data/parts/gls_split/'$CASE_NAME'/'
		output_file=$WORKDIR'/011_data/parts/gls_cross/'$CASE_NAME'.txt'	
		
		# List all files in the folder, shuffle them, and select the first nfiles files
		files=($(ls "$folder" | shuf | head -n $NCROSSFILES))
		
		# Check if there are at least NCROSSFILES files to form NCROSSFILES*2 pairs
		if [ ${#files[@]} -lt $NCROSSFILES ]; then
		  echo "Not enough files to form pairs."
		  exit 1
		fi
		
		# Loop through the files and create pairs
		for ((i=0; i<${#files[@]}; i+=2)); do
			# Check if there is a next file to pair with
			if ((i + 1 < ${#files[@]})); then
				echo "${files[i]} ${files[i+1]}" >> $output_file
			else
				# If there's an odd number of files, the last file won't be paired
				echo "${files[i]}" >> $output_file
			fi
		done
	
		parallel -a $output_file -j $jbs Rscript $WORKDIR'/090_scripts/parts_split_cross.R' $WORKDIR'/011_data/parts/gls_split/'$CASE_NAME'/' {} $WORKDIR'/011_data/parts/data/'$CASE_NAME'/rds/' $WORKDIR'/011_data/parts/gls_cross/'$CASE_NAME'/' $WORKDIR'/011_data/parts/alls_spcors_abs.txt'

	fi
fi

if [ $SPLITANALYSIS == TRUE ] ; then
	
	SUBSET_GLS=50
	SUBSET_PAIRS=50
	Rscript '/data/FS_human_footprint/090_scripts/parts_split_analysis.R' '/data/FS_human_footprint/011_data/parts/gls_split/' '/data/FS_human_footprint/011_data/parts/gls_cross/global/' '/data/FS_human_footprint/011_data/parts/gls_analysis/out_global.rds' $SUBSET_GLS $SUBSET_PAIRS
	
	#use reference levels file
	Rscript '/data/FS_human_footprint/090_scripts/parts_split_analysis.R' '/data/FS_human_footprint/011_data/parts/gls_split/continental_2_ecobiocnt/' '/data/FS_human_footprint/011_data/parts/gls_cross/continental_2_ecobiocnt/' '/data/FS_human_footprint/011_data/parts/gls_analysis/test.rds' '/data/FS_human_footprint/011_data/parts/gls_analysis/levels_reference.txt' 1 0
	
fi