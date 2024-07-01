import numpy as np
import matplotlib.pyplot as plt
import sys
import matplotlib
from matplotlib import cm
import pandas as pd # http://pandas.pydata.org/
from netCDF4 import Dataset, num2date
from scipy.stats import ttest_ind
import pandas as pd
import math
from scipy.stats.stats import pearsonr
import scipy
from scipy import signal
from scipy.stats import t
from scipy import stats
import os
import re
import random

model='MPI-ESM1-2-XR'
ncfile=Dataset("../anom/OLR.day.anomalies.2015-2050.nc", mode = "r")
time = ncfile.variables[ "time" ][:]
time_units = ncfile.variables[ "time" ].units
datevar=num2date(time,time_units)
#store date information
var_tsteps=len(time)
#print(var_tsteps)
var_year=np.zeros(var_tsteps)
var_day=np.zeros(var_tsteps)
var_mon=np.zeros(var_tsteps)
for tt in range(var_tsteps):
    var_day[tt]=datevar[tt].day
    var_mon[tt]=datevar[tt].month
    var_year[tt]=datevar[tt].year

ncfile=Dataset("MJO_PC_ssp_baseonREOF.nc", mode = "r")
#reverse y axis
PC1=ncfile.variables[ "PC1" ][:]
PC2=ncfile.variables[ "PC2" ][:]
RMM1=np.array(PC1)
RMM2=np.array(PC2)
amplitude=ncfile.variables[ "MJO_INDEX" ][:]
#for tt in range(10):
#    print(RMM1[100+tt],RMM2[100+tt])

fileout='MJO_indices_'+str(model)+'.txt'
f1=open(fileout,'w+')

fileout='MJO_indices_'+str(model)+'_phases81.txt'
f2=open(fileout,'w+')

fileout='MJO_indices_'+str(model)+'_phases23.txt'
f3=open(fileout,'w+')

fileout='MJO_indices_'+str(model)+'_phases45.txt'
f4=open(fileout,'w+')

fileout='MJO_indices_'+str(model)+'_phases67.txt'
f5=open(fileout,'w+')

fileout='Phases12345678_RWBA_dates_MJOamp.txt'
f6=open(fileout,'w+')

#RMM1=np.array(PC1/np.std(PC1,axis=0))
#RMM2=np.array(PC2/np.std(PC2,axis=0))
phase=np.zeros((len(RMM1)))
for tt in range(len(RMM1)):
#    angle=np.arctan(RMM2[tt]/RMM1[tt])
#    angle_degree=angle*180.0/math.pi
#    angle_degree=angle_degree+360
#    print(angle_degree)
    if RMM1[tt]>0 and RMM2[tt]>0 and abs(RMM1[tt])>abs(RMM2[tt]):
       phase[tt]=5
    if RMM1[tt]>0 and RMM2[tt]>0 and abs(RMM2[tt])>abs(RMM1[tt]):
       phase[tt]=6
    if RMM1[tt]<0 and RMM2[tt]>0 and abs(RMM2[tt])>abs(RMM1[tt]):
       phase[tt]=7
    if RMM1[tt]<0 and RMM2[tt]>0 and abs(RMM1[tt])>abs(RMM2[tt]):
       phase[tt]=8
    if RMM1[tt]<0 and RMM2[tt]<0 and abs(RMM1[tt])>abs(RMM2[tt]):
       phase[tt]=1
    if RMM1[tt]<0 and RMM2[tt]<0 and abs(RMM2[tt])>abs(RMM1[tt]):
       phase[tt]=2
    if RMM1[tt]>0 and RMM2[tt]<0 and abs(RMM2[tt])>abs(RMM1[tt]):
       phase[tt]=3
    if RMM1[tt]>0 and RMM2[tt]<0 and abs(RMM1[tt])>abs(RMM2[tt]):
       phase[tt]=4
    if amplitude[tt]>=0 and var_year[tt]>=2015 and var_year[tt]<=2050:
       f1.write(str(int(var_year[tt]))+' '+str(int(var_mon[tt]))+' '+str(int(var_day[tt]))+' '+str(round(RMM1[tt], 7))+' '+str(round(RMM2[tt], 7))+' '+str(round(amplitude[tt], 7))+' '+str(int(phase[tt]))+'\n')

       print(var_year[tt],var_mon[tt],var_day[tt],amplitude[tt],phase[tt])

    if amplitude[tt]>=1 and var_year[tt]>=2015 and var_year[tt]<=2050 and var_mon[tt]>=6 and var_mon[tt]<=11:
       f6.write(str(int(var_year[tt]*10000+var_mon[tt]*100+var_day[tt]))+' '+str(round(amplitude[tt], 7))+' '+str(int(phase[tt]))+'\n')

       if phase[tt]==1 or phase[tt]==8:
          f2.write(str(int(var_year[tt]))+' '+str(int(var_mon[tt]))+' '+str(int(var_day[tt]))+' '+str(round(RMM1[tt], 7))+' '+str(round(RMM2[tt], 7))+' '+str(round(amplitude[tt], 7))+' '+str(int(phase[tt]))+'\n')

       if phase[tt]==2 or phase[tt]==3:
          f3.write(str(int(var_year[tt]))+' '+str(int(var_mon[tt]))+' '+str(int(var_day[tt]))+' '+str(round(RMM1[tt], 7))+' '+str(round(RMM2[tt], 7))+' '+str(round(amplitude[tt], 7))+' '+str(int(phase[tt]))+'\n')

       if phase[tt]==4 or phase[tt]==5:
          f4.write(str(int(var_year[tt]))+' '+str(int(var_mon[tt]))+' '+str(int(var_day[tt]))+' '+str(round(RMM1[tt], 7))+' '+str(round(RMM2[tt], 7))+' '+str(round(amplitude[tt], 7))+' '+str(int(phase[tt]))+'\n')

       if phase[tt]==6 or phase[tt]==7:
          f5.write(str(int(var_year[tt]))+' '+str(int(var_mon[tt]))+' '+str(int(var_day[tt]))+' '+str(round(RMM1[tt], 7))+' '+str(round(RMM2[tt], 7))+' '+str(round(amplitude[tt], 7))+' '+str(int(phase[tt]))+'\n')

