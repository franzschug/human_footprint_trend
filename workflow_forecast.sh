#!/bin/bash

jbs=20

## Working directory
WORKDIR='/data/FS_human_footprint'

for (( COUNTERX=-180; COUNTERX<=175; COUNTERX+=5 )); do
	for (( COUNTERY=90; COUNTERY>=-85; COUNTERY-=5 )); do
		echo $COUNTERX
		echo $COUNTERY
		#python3 $WORKDIR'/090_scripts/hii_forecast.py' $COUNTERX $COUNTERY
		
		#ca. 3km
		gdalwarp -ts 185 185 -r average '/data/FS_human_footprint/011_data/hii/v1/forecast/300m/hii_forecast_'$COUNTERX'_'$COUNTERY'.tif' '/data/FS_human_footprint/011_data/hii/v1/forecast/3km/hii_forecast_'$COUNTERX'_'$COUNTERY'.tif'
		
		#ca. 10km
		gdalwarp -ts 53 53 -r average '/data/FS_human_footprint/011_data/hii/v1/forecast/300m/hii_forecast_'$COUNTERX'_'$COUNTERY'.tif' '/data/FS_human_footprint/011_data/hii/v1/forecast/10km/hii_forecast_'$COUNTERX'_'$COUNTERY'.tif'
	done
done