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
EST_AUTOCORR_PRM=TRUE


## Merge pixel-wise trend with explanatory variables
MERGEEXPL=FALSE

#partition data!
#run split parallel gls
# split analysis

POSTPROCESS=FALSE
#Rscript $WORKDIR'/090_scripts/parts_fitar.R' $WORKDIR 0 40

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
			
			# stack to csv
			#python3 /data/FS_human_footprint/090_scripts/merge_hii_years.py $COUNTERX $COUNTERY
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
	outFileSPCORS="/data/FS_human_footprint/011_data/parts/alls_spcors.txt"
	outFileNUGGET="/data/FS_human_footprint/011_data/parts/alls_nuggets.txt"
	outDirSPCORS="/data/FS_human_footprint/011_data/parts/cor/"
	
	# Input directories of AR estimates, residuals, and original data
	dir='/data/FS_human_footprint/011_data/hii/v1/ar_all_4/'
	dirstack='/data/FS_human_footprint/011_data/hii/v1/00_stack/'
	
	# Estiamte range parameter, shuf - shuffle, tail - last elements
	#ls $dir | grep .tif | shuf | tail -$sample_tiles | parallel -j 10 Rscript /data/FS_human_footprint/090_scripts/parts_fitcor.R $dir $n_per_tile $iterations $outFileSPCORS $outDirSPCORS {}
	
	partition_size
	
	# Estimate nugget parameter
	#ls $dir | grep .tif | shuf |tail -$sample_tiles | parallel -j 10 Rscript /data/FS_human_footprint/090_scripts/parts_estimate_nugget.R $dir $dirstack /data/FS_human_footprint/011_data/parts/alls_spcors.txt {}
	Rscript /data/FS_human_footprint/090_scripts/parts_estimate_nugget.R '/data/FS_human_footprint/011_data/hii/v1/ar_all_4/' '/data/FS_human_footprint/011_data/hii/v1/00_stack/' /data/FS_human_footprint/011_data/parts/alls_spcors.txt hii_-95_40.tif
	
	
	#python3 /data/FS_human_footprint/090_scripts/plots/00_distribution_range.py
	#python3 /data/FS_human_footprint/090_scripts/plots/00_distribution_nugget.py
fi




#MERGEEXPL 
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
