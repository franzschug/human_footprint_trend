#!/bin/bash

# tile annual hii data for faster io
years=( 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 )
#for i in "${years[@]}"; do
#	mkdir /data/FS_human_footprint/010_raw_data/hii/v1/$i/
#	gdalwarp -srcnodata -32768 -dstnodata -32768 /data/FS_human_footprint/010_raw_data/hii/v1/$i-01-01_hii_$i-01-01.tif /data/FS_human_footprint/010_raw_data/hii/v1/$i-01-01_hii_$i-01-01.vrt
#done

#for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
#	for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
		xend=$(($COUNTERX+5))
		yend=$(($COUNTERY-5))
			
		#printf %s\\n "${years[@]}" | parallel --jobs 20 gdal_translate -projwin $COUNTERX $COUNTERY $xend $yend -of VRT -a_nodata -32768 /data/FS_human_footprint/010_raw_data/hii/v1/{}-01-01_hii_{}-01-01.vrt /data/FS_human_footprint/010_raw_data/hii/v1/{}/hii_$COUNTERX'_'$COUNTERY.vrt
		
		#printf %s\\n "${years[@]}" | parallel --jobs 20 gdal_translate -of XYZ /data/FS_human_footprint/010_raw_data/hii/v1/{}/hii_$COUNTERX'_'$COUNTERY.vrt /data/FS_human_footprint/010_raw_data/hii/v1/{}/hii_$COUNTERX'_'$COUNTERY.csv
		
		#wait
		
		#printf %s\\n "${years[@]}" | parallel --jobs 20  sed -i '/32768/d' /data/FS_human_footprint/010_raw_data/hii/v1/{}/hii_$COUNTERX'_'$COUNTERY.csv
		
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

## fitAR, save results, map and text
#for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
#	for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
#		#echo $COUNTERX
#		#echo $COUNTERY
#		#Rscript /data/FS_human_footprint/090_scripts/parts_fitar.R $COUNTERX $COUNTERY
#	done
#done

## estimate  spatial autocorrelation parameters
#randomly select 300 ar_tiles, estimate range, of spatial autocorrelation
samples=400
dir='/data/FS_human_footprint/011_data/hii/v1/ar_all/csv/'
dirstack='/data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/csv/'
#ls $dir |sort -R |tail -$samples | parallel -j 40 Rscript /data/FS_human_footprint/090_scripts/parts_fitcor.R $dir {} 3
#ls $dir |sort -R |tail -$samples | parallel -j 40 Rscript /data/FS_human_footprint/090_scripts/parts_estimate_nugget.R $dir $dirstack /data/FS_human_footprint/011_data/parts/alls_spcors.txt {}

	
## gls
### todo todo parallelize!!!!!!  fitgls first to est rng, then use in partition gls


# merge result map
 ####  todo todo todo todo todo todo todo todo todo 
  
# estimate nugget based on V value (based on range), and using multiple gls
# size based on good partition size

# use same randomization as for ar, then in r script, extract x and y to load raw data

# gls partition
