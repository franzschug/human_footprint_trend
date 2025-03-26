
import matplotlib as plt
from matplotlib import pyplot
import scipy.stats as stats
import pandas as pd
import numpy as np
pd.options.mode.chained_assignment = None  # default='warn'

plt.pyplot.rcParams['pdf.fonttype'] = 42
plt.pyplot.rcParams['ps.fonttype'] = 42
plt.pyplot.rcParams['axes.linewidth'] = 0.2 #set the value globally
plt.pyplot.rcParams['xtick.major.size'] = 0
plt.pyplot.rcParams['xtick.major.width'] = 0.5
plt.pyplot.rcParams['xtick.minor.size'] = 0
plt.pyplot.rcParams['xtick.minor.width'] = 1
plt.rcParams["font.weight"] = "bold"
plt.rcParams["axes.labelweight"] = "bold"

plt.pyplot.rc('font', size=6)                   # controls default text sizes
plt.pyplot.rc('axes', titlesize=6)     # fontsize of the axes title
plt.pyplot.rc('axes', labelsize=6)    # fontsize of the x and y labels
pyplot.rc('xtick', labelsize=6)   # fontsize of the tick labels
pyplot.rc('ytick', labelsize=6)    # fontsize of the tick labels
#pyplot.rc('legend', fontsize=SMALL_SIZE)    # legend fontsize
plt.pyplot.rc('figure', titlesize=7)  # fontsize of the figure title

plt.pyplot.rc('axes', axisbelow=True)

data = pd.read_csv('/data/FS_human_footprint/011_data/parts/alls_nuggets.txt', header=None).to_numpy().flatten()
#print(data)
print(np.median(data))

bins = 100
density = stats.gaussian_kde(data)
n, x, _ = plt.pyplot.hist(data, bins=np.linspace(0, 1, bins), 
                   histtype=u'step', density=True)  

#plt.pyplot.plot(x, density(x)*100)
plt.pyplot.vlines(x=np.median(data), ymin=0, ymax=100, color='r')
plt.pyplot.vlines(x=np.mean(data), ymin=0, ymax=100, color='g')

plt.pyplot.ylim(0,20)
plt.pyplot.xlim(0,1)

plt.pyplot.tight_layout(h_pad=4, w_pad=1)
plt.pyplot.savefig('/data/FS_human_footprint/014_results/020_plots/00_distribtion_nugget.png')