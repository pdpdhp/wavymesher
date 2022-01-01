# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================
import numpy as np
import math
import matplotlib
matplotlib.use('Agg')

from pathlib import Path
from math import hypot
from matplotlib import pyplot as plt
import os
dirname = os.path.dirname(os.path.realpath(__file__))
Path(f"{dirname}").mkdir(parents=True, exist_ok=True)

#wave tags to identify them
W1 = 1
W2 = 2
W3 = 3
YES = 1
NO = 0
#------------------------wave specifications are set by wavymesher scripts--------------------
#Wave Type
WAVE_TYPE = [W2]
#
#
#Wave Depth
WAVE_DEPTH = [50]
#
#
#Wavy Percent
WAVE_PERCENT = [10]
#
#
#Wave's Amp.
AMPLITUDE = [0.0125]
#
#
#Wave's Amp.
AMPLITUDE_RATIO = [40]
#
#
#Number of waves in lateral direction
NUM_WAVE = [8]
#
#
#Number of points per wave in lateral direction
WV_NOD = [36.0]
#
#
#Span Dimension
span = [0.5]
#
#
#ZigZag top wave rotational angle
ZZ_Atop = [0]
#
#
#ZigZag bottom wave rotational angle
ZZ_Abot = [0]
#
#
# ending point heights
ENDSU = [1.0,0.062,0.0]
#
#
# ending point heights
ENDSL = [1.0,-0.05,0.0]
#
#====================================================================
#
nperiod = 180* np.array(NUM_WAVE)
#

theta = np.radians(ZZ_Atop[0])
betha = np.radians(-ZZ_Abot[0])

rtop = np.array(( (np.cos(theta), -np.sin(theta)),
               (np.sin(theta),  np.cos(theta)) ))

rbot = np.array(( (np.cos(betha), -np.sin(betha)),
               (np.sin(betha),  np.cos(betha)) ))

Npt = int(WV_NOD[0]*NUM_WAVE[0])

if Npt== 0:
	Npt = int(WV_NOD[0])

y_pos = list (np.linspace(0, -1*span[0], Npt))
xtop_pos = np.repeat(1, len(y_pos))
xbot_pos = np.repeat(1, len(y_pos))
max_thick = ENDSU[1] - ENDSL[1]
half_thick = max_thick/2

# different wave equations
if WAVE_TYPE[0] == W1:
	wchar = 'W1'
	AMPLITUDEU = AMPLITUDE[0] * (AMPLITUDE_RATIO[0]/100)
	ztop_pos = AMPLITUDEU * np.sin(np.radians(nperiod[0]*np.array(y_pos))) + ENDSU[1]
	zbot_pos = AMPLITUDE * np.sin(np.radians(nperiod[0]*np.array(y_pos))) - ENDSL[1]
elif WAVE_TYPE[0] == W2:
	wchar = 'W2'
	AMPLITUDE = 0.25*max_thick*(1 -(WAVE_DEPTH[0]/100))
	AMPLITUDEU = AMPLITUDE * (AMPLITUDE_RATIO[0]/100)
	ztop_pos = AMPLITUDEU * np.cos(np.radians(nperiod[0]*np.array(y_pos))) + ENDSU[1] - AMPLITUDEU
	zbot_pos = -AMPLITUDE * np.cos(np.radians(nperiod[0]*np.array(y_pos))) - ENDSL[1] + AMPLITUDE
elif WAVE_TYPE[0] == W3:
	wchar = 'W3'
	AMPLITUDEU = AMPLITUDE[0] * (AMPLITUDE_RATIO[0]/100)
	ztop_pos = ENDSU[1] - AMPLITUDEU * np.cos(np.radians(nperiod[0]*np.array(y_pos))) * np.sin(np.radians(nperiod[1]*np.array(y_pos)))
	zbot_pos =  - ENDSL[1] + AMPLITUDE * np.cos(np.radians(nperiod[0]*np.array(y_pos))) * np.sin(np.radians(nperiod[1]*np.array(y_pos)))

topnodes = np.stack((np.array(xtop_pos-1), np.array(ztop_pos-ENDSU[1])))
botnodes = np.stack((np.array(xbot_pos-1), np.array(zbot_pos+ENDSL[1])))

for i in range(int(len(y_pos))):
	topnodes.T[:][i] = rtop.dot(topnodes.T[:][i])
	botnodes.T[:][i] = rbot.dot(botnodes.T[:][i])

# adjusting ending points in spanwise direction for small variations
xtop_pos = topnodes[:][0] + 1.0
xbot_pos = botnodes[:][0] + 1.0

fxtop_pos = ["%.3f" % xtop for xtop in xtop_pos]
fxbot_pos = ["%.3f" % xbot for xbot in xbot_pos]

ffxtop_pos = [float(i) for i in fxtop_pos]
ffxbot_pos = [float(i) for i in fxbot_pos]

ztop_pos = topnodes[:][1] + ENDSU[1]
zbot_pos = botnodes[:][1] + ENDSL[1]

fztop_pos = ["%.8f" % ztop for ztop in ztop_pos]
fzbot_pos = ["%.8f" % zbot for zbot in zbot_pos]

ffztop_pos = [float(i) for i in fztop_pos]
ffzbot_pos = [float(i) for i in fzbot_pos]

ffztop_pos[-1] = ENDSU[1]
ffzbot_pos[-1] = ENDSL[1]

#------------------GRID PROPERTISE--------------
#upper wavy coordinates
wave1=np.column_stack((ffxtop_pos, y_pos, ffztop_pos))

#lower wavy coordinates
wave2=np.column_stack((ffxbot_pos, y_pos, ffzbot_pos))

#-----------------WAVE PROPERTISE---------------
upmax = max(wave1[:,2])
upmin = min(wave1[:,2])

lowmax = max(wave2[:,2])
lowmin = min(wave2[:,2])

upmax_cor = np.zeros(Npt)+upmax
lowmax_cor = np.zeros(Npt)+lowmax
upmin_cor =  np.zeros(Npt)+upmin
lowmin_cor =  np.zeros(Npt)+lowmin

wvdepth = (abs(upmin-lowmax)/abs(upmax-lowmin))*100
wvampl = abs(lowmax-lowmin)*0.5
ampl_ratio = AMPLITUDE_RATIO[0]

#averaging local thickness across the wave
avg_thk = 0.0
for i in range(len(wave1[:,2])):
	avg_thk += abs(wave1[i,2] - wave2[i,2])

avg_thk = avg_thk/(i+1)
#------------writing files---------------------
# grid propertise metric
f = open(f'{dirname}/wave_top.txt', 'w')
for i in range(len(y_pos)):
	f.write("  % 1.7e   % 1.7e  % 1.7e\n" % (wave1[i,0],wave1[i,1],wave1[i,2]))
f.close()

f = open(f'{dirname}/wave_bot.txt', 'w')
for i in range(len(y_pos)):
	f.write("  % 1.7e   % 1.7e  % 1.7e\n" % (wave2[i,0],wave2[i,1],wave2[i,2]))
f.close()

#---------------plotting the waves--------------
plt.title("Traling Edge Wavy Line", fontsize=12)
plt.plot(wave1[:,1],wave1[:,2], '-r', label='upper wavy traling edge', Linewidth=1.5);
plt.plot(wave2[:,1],wave2[:,2], '-b', label='lower wavy traling edge', Linewidth=1.5);
plt.plot(wave2[:,1],upmax_cor, '-k', label='upper max', Linewidth=0.15);
plt.plot(wave2[:,1],upmin_cor, '-.k', label='upper min', dashes=(5, 15), Linewidth=0.25);
plt.plot(wave2[:,1],lowmax_cor, '-.k', label='lower max', dashes=(5, 15), Linewidth=0.25);
plt.plot(wave2[:,1],lowmin_cor, '-k', label='lower min', Linewidth=0.15);

max_thkx = [-span[0]*0.5,-span[0]*0.5]
max_thky = [upmax,lowmin]
min_thkx = [-span[0]*0.75,-span[0]*0.75]
min_thky = [upmin,lowmax]
arw_sze = 0.002

plt.plot(max_thkx,max_thky,'-k', Linewidth=0.75);
plt.arrow(-span[0]*0.5,upmax-2*arw_sze,0.0,arw_sze, shape='full', color='k', lw=0, head_length=arw_sze, head_width=arw_sze*5)
plt.arrow(-span[0]*0.5,lowmin+2*arw_sze,0.0,-arw_sze, shape='full', color='k', lw=0, head_length=arw_sze, head_width=arw_sze*5)
plt.text(-span[0]*0.5,0.0," max thickness", fontsize=7)
plt.plot(min_thkx,min_thky,'-k', Linewidth=0.75);
plt.arrow(-span[0]*0.75,upmin-2*arw_sze,0.0,arw_sze, shape='full', color='k', lw=0, head_length=arw_sze, head_width=arw_sze*5)
plt.arrow(-span[0]*0.75,lowmax+2*arw_sze,0.0,-arw_sze, shape='full', color='k', lw=0, head_length=arw_sze, head_width=arw_sze*5)
plt.text(-span[0]*0.75,0.0," min thickness", fontsize=7)

plt.xlabel('spanwise direction', fontsize=10)
plt.ylabel('trailing edge thickness', fontsize=10)
plt.yticks(np.arange(lowmin, upmax+0.01, 0.01))
plt.legend(fontsize=5)
plt.text(-span[0], upmax+0.002, 'WAVE DEPTH = %2.4f%%'%(wvdepth), fontsize=7)
plt.text(-span[0]*0.65, upmax+0.002, 'WAVE AMPL. = %f'%(wvampl), fontsize=7) 
plt.text(-span[0]*0.28, upmax+0.002, 'AVG THICKNESS = %f'%(avg_thk), fontsize=7) 
plt.text(-span[0]*0.28, upmin-0.005, 'AMPL RATIO = %2.2f%%'%(ampl_ratio), fontsize=7)

plt.text(-span[0], lowmin-0.0035, 'TYPE WAVE = %s'%(wchar), fontsize=7)
plt.text(-span[0]*0.65, lowmin-0.0035, 'NODES/WAVE = %d'%(WV_NOD[0]), fontsize=7) 
plt.text(-span[0]*0.28, lowmin-0.0035, 'NO. WAVES = %d'%(NUM_WAVE[0]), fontsize=7) 

plt.savefig(f'{dirname}/TE_wavy_lines.pdf', bbox_inches='tight')
