#!/bin/bash

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

## Merge pixel-wise trend with independent variables
MERGEINDEP=FALSE

## Generate partition matrix for complete dataset
PARTITIONMATRIX=TRUE

## Split data into randomized partitions
PARTITION=FALSE

## Perform split GLS
SPLITGLS=FALSE

## Analyse split GLS results
SPLITANALYSIS=FALSE

## Merge split GLS results
MERGERESULT=FALSE


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
					
			printf %s\\n "${years[@]}" | parallel --jobs 20 gdal_translate -projwin $COUNTERX $COUNTERY $xend $yend -of VRT -a_nodata -32768 $WORKDIR'/010_raw_data/hii/v1/'{}'-01-01_hii_'{}'-01-01.vrt' $WORKDIR'/011_data/hii/v1/'{}'/hii_'$COUNTERX'_'$COUNTERY'.vrt'
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
	sample_tiles=400  	## Number of tiles to be randomly chosen for analysis
	n_per_tile=3000		## Number of pixels considered within each tile
	iterations=3		## Analysis is performed n times per tile
	
	# Outpath for all parameter estimates
	outFileSPCORS=$WORKDIR'/011_data/parts/alls_spcors.txt'
	outFileNUGGET=$WORKDIR'/011_data/parts/alls_nuggets.txt'
	outDirSPCORS=$WORKDIR'/011_data/parts/cor/'
	
	# Input directories of AR estimates, residuals, and original data
	dir=$WORKDIR'/011_data/hii/v1/ar_all/'
	dirstack=$WORKDIR'/011_data/hii/v1/00_stack/'
	
	# Estiamte range parameter, shuf - shuffle, tail - last elements
	ls $dir | grep .tif | shuf | tail -$sample_tiles | parallel -j 10 Rscript $WORKDIR'/090_scripts/parts_fitcor.R' $dir $n_per_tile $iterations $outFileSPCORS $outDirSPCORS {}
	
	# Estimate nugget parameter
	nr_samples=5000
	save_dir=$WORKDIR'/011_data/parts/gls/'
	
	ls $dir | grep .tif | shuf |tail -$sample_tiles | parallel -j 10 Rscript $WORKDIR'/090_scripts/parts_estimate_nugget.R' $dir $dirstack $nr_samples $outFileSPCORS $outFileNUGGET $save_dir {}
	
	#python3 $WORKDIR'/090_scripts/plots/00_distribution_range.py'
	#python3 $WORKDIR'/090_scripts/plots/00_distribution_nugget.py'
fi

indep_dir=( '011_data/countries' '011_data/dhi' '011_data/wdpa' '011_data/ecoregions' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/wui' '011_data/gdp' '011_data/gdp' '011_data/gdp' '011_data/gdp' ) 
indep_name=( 'countries' 'cumDHI' 'wdpa_prox' 'ecoregions' 'sumTotalMammals_300' 'sumTotalBirds_300' 'sumTotalAmphibians_300' 'sumTotalReptiles_300' 'global_wui_300' 'gdp_1990' 'gdp_2015' 'gdp_change' 'gdp_rel_change' ) 

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
				echo "File exists. Proceeding with the next steps."
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

if [ $PARTITIONMATRIX == TRUE ] ; then
	global_vrt_path=$WORKDIR'/011_data/hii/v1/merged_hii_ind.vrt'
	pm_path=$WORKDIR'/011_data/parts/pm/global_partition_uncompressed.rds'
	partition_size=2000
	
	ls $WORKDIR'/011_data/hii/v1/merged_ar_ind/'*.tif > $WORKDIR'/011_data/hii/v1/list_temp.txt'			
	gdalbuildvrt $global_vrt_path -input_file_list $WORKDIR'/011_data/hii/v1/list_temp.txt'
	rm $WORKDIR'/011_data/hii/v1/list_temp.txt'

	Rscript $WORKDIR'/090_scripts/parts_generate_pm.R' $global_vrt_path $pm_path $partition_size
fi

if [ $PARTITION == TRUE ] ; then
	
	#Rscript $WORKDIR/090_scripts/parts_split_partitions.R  $WORKDIR/011_data/hii/v1/temp_obs/hii_global_reduced_subset_5million.csv $WORKDIR/011_data/parts/pm/pm_global_300m_5million.rds $WORKDIR/011_data/parts/pm/gls_300m_subpm/
	Rscript $WORKDIR/090_scripts/parts_split_partitions.R  $WORKDIR/011_data/hii/v1/temp_obs/hii_global_reduced_subset_5million.csv $WORKDIR/011_data/parts/pm/global_partition.rds $WORKDIR/011_data/parts/pm/gls_300m_subpm/
	
	#data_path=
	#$WORKDIR'/011_data/parts/pm/global_partition.rds'
	#pm_path=$WORKDIR'/011_data/parts/pm/global_partition.rds'
	#sub_pm_outdir=$WORKDIR'/011_data/parts/pm/'
	
	#Rscript $WORKDIR'/090_scripts/parts_split_partitions.R' $data_path $pm_path $sub_pm_outdir
fi

if [ $SPLITGLS == TRUE ] ; then
perform vif and warn!
print if vif high
	confirmVIF=TRUE # If independent variables highly correlated accoding to VIF, stop to confirm
	
fi

if [ $SPLITANALYSIS == TRUE ] ; then

fi


if [ $MERGERESULT == TRUE ] ; then

fi

	
		
#- output correlation matrix, variance inflation factor test. then select!
# write vif new - with subset of the data