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
PREPINDEP=TRUE

## Merge pixel-wise trend with independent variables
MERGEINDEP=FALSE

## Generate partition matrix for complete dataset
PARTITIONMATRIX=FALSE

## Split data into randomized partitions
PARTITION=FALSE


SPLITGLS=FALSE

SPLITANALYSIS=FALSE

#partition data!
#run split parallel gls
# split analysis


if [ $MERGEHII == TRUE ] ; then
	years=( 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 )
	for i in "${years[@]}"; do
		mkdir -p $WORKDIR'/010_raw_data/hii/v1/'$i'/'
		gdalwarp -srcnodata -32768 -dstnodata -32768 $WORKDIR'/010_raw_data/hii/v1/'$i'-01-01_hii_'$i'-01-01.tif' $WORKDIR'/010_raw_data/hii/v1/'$i'-01-01_hii_'$i'-01-01.vrt'
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
	dir=$WORKDIR'/011_data/hii/v1/ar_all_4/'
	dirstack=$WORKDIR'/011_data/hii/v1/00_stack/'
	
	# Estiamte range parameter, shuf - shuffle, tail - last elements
	ls $dir | grep .tif | shuf | tail -$sample_tiles | parallel -j 10 Rscript $WORKDIR'/090_scripts/parts_fitcor.R' $dir $n_per_tile $iterations $outFileSPCORS $outDirSPCORS {}
	
	# Estimate nugget parameter
	nr_samples=5000
	
	ls $dir | grep .tif | shuf |tail -$sample_tiles | parallel -j 10 Rscript $WORKDIR'/090_scripts/parts_estimate_nugget.R' $dir $dirstack $nr_samples $WORKDIR'/011_data/parts/alls_spcors.txt' {}
	
	python3 $WORKDIR'/090_scripts/plots/00_distribution_range.py'
	python3 $WORKDIR'/090_scripts/plots/00_distribution_nugget.py'
fi

#indep_dir=( '011_data/countries' '011_data/dhi' '011_data/wdpa' '011_data/ecoregions' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/species_richness' '011_data/wui' '011_data/gdp' '011_data/gdp' '011_data/gdp' '011_data/gdp' ) 

indep_dir=( '011_data/wui' '011_data/gdp' '011_data/gdp' '011_data/gdp' '011_data/gdp' ) 

#indep_name=( 'countries' 'cumDHI' 'wdpa_prox' 'ecoregions' 'sumTotalMammals' 'sumTotalBirds' 'sumTotalAmphibians' 'sumTotalReptiles' 'global_wui' 'gdp_1990' 'gdp_2015' 'gdp_change' 'gdp_rel_change' ) 

indep_name=( 'global_wui' 'gdp_1990' 'gdp_2015' 'gdp_change' 'gdp_rel_change' ) 
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
			temp=("${indep_var[@]}")
			temp=( "${temp[@]/%/"$COUNTERX"_"$COUNTERY".vrt}" )
			temp=( "${temp[@]/#/"$WORKDIR"}" )
			#printf '%s ' "${temp[@]}"
			printf "${temp[*]}"

			gdal_merge.py -o $WORKDIR'/data/FS_human_footprint/011_data/hii/v1/merged_ar_ind/hii_'$COUNTERX'_'$COUNTERY'_ind.tif' -co "COMPRESS=LZW" -separate "${temp[@]}"
			
			#'/data/FS_human_footprint/011_data/hii/v1/ar_coeff_pv/tif/AF_temp/hii_'$COUNTERX'_'$COUNTERY'.tif' '/data/FS_human_footprint/011_data/dhi/tiles_xy_fix/cumDHI_'$COUNTERX'_'$COUNTERY'.vrt' '/data/FS_human_footprint/011_data/wdpa/tiles_xy_fix/wdpa_prox_'$COUNTERX'_'$COUNTERY'.vrt' '/data/FS_human_footprint/011_data/ecoregions/tiles_xy_fix/ecoregions_'$COUNTERX'_'$COUNTERY'.vrt' '/data/FS_human_footprint/011_data/gdp/tiles_xy_fix/gdp_2015_'$COUNTERX'_'$COUNTERY'.tif' '/data/FS_human_footprint/011_data/species_richness/tiles/sprich_300_'$COUNTERX'_'$COUNTERY'.tif'
		done
	done
fi

if [ $PARTITIONMATRIX == TRUE ] ; then
	global_vrt_path=$WORKDIR'011_data/hii/v1/merged_ar_ind/'*'.vrt'
	pm_path=$WORKDIR'011_data/parts/pm/global_partition.rds'
	partition_size=2000
	
	gdalbuildvrt $WORKDIR'011_data/hii/v1/merged_hii_ind.vrt' $global_vrt_path

	Rscript $WORKDIR'/090_scripts/parts_generate_pm.R' $global_vrt_path $pm_path
fi

if [ $PARTITION == TRUE ] ; then
	data_path=
	$WORKDIR'011_data/parts/pm/global_partition.rds'
	pm_path=$WORKDIR'011_data/parts/pm/global_partition.rds'
	sub_pm_outdir=$WORKDIR'011_data/parts/pm/'
	
	Rscript $WORKDIR'/090_scripts/parts_split_partitions.R' $data_path $pm_path $sub_pm_outdir
fi

if [ $SPLITGLS == TRUE ] ; then
perform vif and warn!
print if vif high
	confirmVIF=TRUE # If independent variables highly correlated accoding to VIF, stop to confirm
	
fi

if [ $SPLITANALYSIS == TRUE ] ; then

fi


	
		
#- output correlation matrix, variance inflation factor test. then select!
# write vif new - with subset of the data



#if [ $FITAR == TRUE ] ; then
#for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
#	for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
		#xend=$(($COUNTERX+5))
		#yend=$(($COUNTERY-5))
			
		##remove####printf %s\\n "${years[@]}" | parallel --jobs 20 gdal_translate -of XYZ /data/FS_human_footprint/010_raw_data/hii/v1/{}/hii_$COUNTERX'_'$COUNTERY.vrt /data/FS_human_footprint/010_raw_data/hii/v1/{}/hii_$COUNTERX'_'$COUNTERY.csv
		
		#remove###wait
		
		#remove##printf %s\\n "${years[@]}" | parallel --jobs 20  sed -i '/32768/d' /data/FS_human_footprint/010_raw_data/hii/v1/{}/hii_$COUNTERX'_'$COUNTERY.csv
		
		#fileArr=()
		#for i in "${years[@]}"
		#do
		#	fileArr+=("/data/FS_human_footprint/010_raw_data/hii/v1/"$i"/hii_"$COUNTERX"_"$COUNTERY".vrt")
		#done
		#printf "%s\n" "${fileArr[@]}" > "/data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/list_temp.txt"
		
		## stack to vrt
		#gdalbuildvrt -separate /data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/hii_$COUNTERX'_'$COUNTERY.vrt -input_file_list /data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/list_temp.txt

		#rm "/data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/list_temp.txt"
		
		# stack to csv
		#python3 /data/FS_human_footprint/090_scripts/merge_hii_years.py $COUNTERX $COUNTERY
#	done
#done





	
## gls
### todo todo parallelize!!!!!!  fitgls first to est rng, then use in partition gls


# merge result map
 ####  todo todo todo todo todo todo todo todo todo 
  
# estimate nugget based on V value (based on range), and using multiple gls
# size based on good partition size

# use same randomization as for ar, then in r script, extract x and y to load raw data

# gls partition
