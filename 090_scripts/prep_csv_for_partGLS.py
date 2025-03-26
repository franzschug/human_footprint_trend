#!/usr/bin/env python3

import sys
import pandas as pd
import numpy as np
pd.options.mode.chained_assignment = None  # default='warn'

if (len(sys.argv)!=4):
  print("Three arguments expected")
  exit()
else:
  inPath = str(sys.argv[1]).split(" ")[0]
  outPath = str(sys.argv[2]).split(" ")[0]
  colnm = str(sys.argv[3]).split(" ")[0]

data = pd.read_csv(inPath, header=None, sep=' ')
data[4].replace(0, np.nan, inplace=True)
data[4].replace(-32768, np.nan, inplace=True)

colnames = colnm.split(",")

data.columns = colnames

data = data.dropna()

data = data.round({'long': 3, 'lat': 3, 'coeff': 2, 'pval': 4})

for j in range(4,22):
    data = data.astype({data.columns[j]: int})

data.to_csv(outPath, sep=",", header=False, index=False)