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
FITAR=TRUE

## Estimate  spatial autocorrelation parameters, range and nugget
EST_AUTOCORR_PRM=FALSE


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
	#for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
	for (( COUNTERX=-5; COUNTERX<=175; COUNTERX+=5 )); do
		for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
			echo $COUNTERX
			echo $COUNTERY
			Rscript $WORKDIR'/090_scripts/parts_fitar.R' $WORKDIR $COUNTERX $COUNTERY
		done
	done
fi


if [ $EST_AUTOCORR_PRM == TRUE ] ; then

fi

## estimate  spatial autocorrelation parameters
#randomly select 300 ar_tiles, estimate range, of spatial autocorrelation
#samples=400
#dir='/data/FS_human_footprint/011_data/hii/v1/ar_all/csv/'
#dirstack='/data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/csv/'
#ls $dir |sort -R |tail -$samples | parallel -j 40 Rscript /data/FS_human_footprint/090_scripts/parts_fitcor.R $dir {} 3
#ls $dir |sort -R |tail -$samples | parallel -j 40 Rscript /data/FS_human_footprint/090_scripts/parts_estimate_nugget.R $dir $dirstack /data/FS_human_footprint/011_data/parts/alls_spcors.txt {}





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
