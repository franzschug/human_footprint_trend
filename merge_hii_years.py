#!/usr/bin/env python3

import sys
import os
import numpy as np
import pandas as pd

#print('Number of arguments:', len(sys.argv), 'arguments.')
print('Argument List:', str(sys.argv))

counterx = str(sys.argv[1]).split(" ")[0]
countery = str(sys.argv[2]).split(" ")[0]

#print(counterx)

outPath = "/data/FS_human_footprint/010_raw_data/hii/v1/ts_stack/csv/hii_" + str(counterx) + "_" + str(countery) + ".csv"

years= [2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020]

for y in years:
    print(counterx + "_" + countery + "_" + str(y))
    path = "/data/FS_human_footprint/010_raw_data/hii/v1/" + str(y) + "/hii_" + str(counterx) + "_" + str(countery) + ".csv"
    try: # if file is empty
        t = pd.read_csv(path, sep=" ", header = None)
    except: # exit and do not stack the data
        exit()
    #print(t)
    if(y == 2001):
        df = t
        df["id"] = df.index + 1
        df = df[['id', 0, 1, 2]]
        df = df.rename(columns={'id': 'FID', 0: 'Long', 1: 'Lat', 2: '2001'})
    else:
        df[str(y)] = t[2]

df.replace(-32768, 0, inplace = True)
#print(df)

## write array to text file
df.to_csv(outPath, sep=",", header=True, index=False)
