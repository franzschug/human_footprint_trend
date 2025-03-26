#!/usr/bin/env python3

import sys
import os
import csv
import pandas as pd
import numpy as np
pd.options.mode.chained_assignment = None  # default='warn'

if (len(sys.argv)!=7):
  print("Six arguments expected")
  exit()
else:
  inDir = str(sys.argv[1]).split(" ")[0]
  case_name = str(sys.argv[2]).split(" ")[0]
  percent = float(str(sys.argv[3]).split(" ")[0])
  min_cat = str(sys.argv[4]).split(" ")[0]
  split_by_cat = str(sys.argv[5]).split(" ")[0]
  useExistingIndex = str(sys.argv[6]).split(" ")[0]

if(case_name == ''):
    print("Case name cannot be empty when data are filtered")
    exit()


csvs = [f for f in os.listdir(inDir) if f.endswith('.csv')]

if not os.path.exists(inDir + case_name):
    os.makedirs(inDir + case_name)
        
def select_indices(group):    
    # Check if the group has fewer than min_data_per_cat elements
    #if len(group) < min_data_per_cat:
    #    print('return nothing')
    #    return# pd.Index([])  # Return an empty Index if the group is too small
        
    #group_count = int(len(group) * (percent/100))
    selected_count = int(len(group) * (percent/100))

    #selected_count = max(group_count, min_data_per_cat)
    
    # Sample the indices
    return group.sample(n=selected_count, random_state=42)


key_file_path = inDir + '/' + case_name + "/categories.txt"

if(useExistingIndex == '0'):
    if(min_cat != '0'):
        path = inDir + 'global/' + min_cat + ".csv"
        t = pd.read_csv(path, sep=",", header = None)
        print('loaded')
        
        # Group by the first (and only) column and apply the selection
        index_groups = t.groupby(0, group_keys=True)
        group_keys = index_groups.groups.keys()
        
        #Save group keys to list
        with open(key_file_path, 'w') as file:
            for key in group_keys:
                file.write(f"{key}\n")

        selected_indices = index_groups.apply(select_indices)

        selected_indices = selected_indices.reset_index(level=0, drop=True)       
        selected_indices = selected_indices.groupby(0, group_keys=False)

        if(split_by_cat == 'TRUE'):
            
            #group dataset by value again?
            for key, s in selected_indices:
                print('s')
                print(s)
                
                indexPath = inDir + case_name + '/index_' + min_cat + '_' + str(percent).replace('.', '') + '_' + str(s[0].unique()[0]) + '.csv'
                #print(indexPath)
                
                write_s = s.index.tolist()
                ##print(write_s)
                with open(indexPath, mode='w', newline='') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerows([[index] for index in write_s])
        else:

            indexPath = inDir + case_name + '/index_' + min_cat + '_' + str(percent).replace('.', '') + '.csv'
            
            #selected_indices = [item for sublist in selected_indices for item in sublist]
            index_list = []
            
            for i in selected_indices:
                if(len(i) > 0):
                    index_list.extend(i.index.tolist())
            
            selected_indices = index_list
            
            with open(indexPath, mode='w', newline='') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerows([[index] for index in selected_indices])
    else:
        path = inDir + csvs[0]
        #print('load')
        t = pd.read_csv(path, sep=",", header = None)

        #print('done')
        #percent_count = int(rows * (percent/100))

        selected_indices = select_indices(t)

        # Convert to a list
        selected_indices = selected_indices.index.tolist()  
        
        indexPath = inDir + case_name + '/index_' + str(percent).replace('.', '') + '.csv'
        
        with open(indexPath, mode='w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerows([[index] for index in selected_indices])


#filter all files in directory
if(useExistingIndex == '1'):
    # Loop through the categories
    categories = []

    with open(key_file_path, 'r') as file:
        lines = file.readlines()
        for line in lines:
            categories.append(line.strip())
 
    for cat in categories:
        selected_indices = []
        
        print(cat)
        filename = inDir + case_name + "/index_" + min_cat + "_" + str(percent).replace('.', '') + "_" + str(cat) + ".csv"
        print(filename)
        
        files_temp = [f for f in os.listdir(inDir + '/global') if not f.endswith('length.csv')]
        files_tobe_filtered = [os.path.splitext(filename)[0] for filename in files_temp]

        if os.path.exists(filename):
            with open(filename, mode='r', newline='') as file:
                csv_reader = csv.reader(file)
                for row in csv_reader:
                    selected_indices.extend(row)  # Add each row to the values list
        
        for ftbf in files_tobe_filtered:
            inPath = inDir + '/global/' + ftbf + ".csv"
            print(inPath)
            filtered_outpath = inDir + case_name + "/" + ftbf + "_" + str(cat) + ".csv"
            
            if not os.path.isfile(filtered_outpath):
                df = pd.read_csv(inPath, header=None)
                filtered_df = df.iloc[selected_indices]
                filtered_df.to_csv(filtered_outpath, index=False, header=False)
        