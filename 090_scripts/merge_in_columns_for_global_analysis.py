#!/usr/bin/env python3

import sys
import os
import numpy as np
import pandas as pd

if (len(sys.argv)!=5):
  print("Four arguments expected")
  exit()
else:
  inDir = str(sys.argv[1]).split(" ")[0]
  outDir = str(sys.argv[2]).split(" ")[0]
  indep_name = str(sys.argv[3]).split(" ")[0]
  index = int(str(sys.argv[4]).split(" ")[0])
  print(index)

counterx = -180
l=0
lenPath = outDir + indep_name + "_length.csv"

while(counterx <= 175):
    countery = 90
    while(countery >= -85):
        print(str(counterx) + "_" + str(countery))
        
        outPath = outDir + indep_name + ".csv"
        path = inDir + "hii_" + str(counterx) + "_" + str(countery) + "_ind.tif_temp.csv_nona.csv"
        
        #remove lines with not len*(indep_name) colum
        countery = countery - 5
 
        try: # if file is empty
            t = pd.read_csv(path, sep=",", header = None)
            t = t.iloc[:, index]
            l = l + len(t)
            print(len(t))
            t.to_csv(outPath, mode='a', sep=",", header=False, index=False)
           
        except Exception as e: 
            print(e)

    counterx = counterx + 5

with open(lenPath, 'a') as file:
    file.write(str(l) + '\n')