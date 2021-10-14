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
from pathlib import Path
from math import hypot

import os
dirname = os.path.dirname(os.path.realpath(__file__))

Path(f"{dirname}").mkdir(parents=True, exist_ok=True)

#Types of waves
W1 = 1
W2 = 2
W3 = 3
YES = 1
NO = 0
#
#----------------------------Wave Specifications--------------------
#Wave Type
WAVE_TYPE = [W1]
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
#Number of waves in lateral direction
NUM_WAVE = [0]
#
#
#Number of points per wave in lateral direction
WV_NOD = [5.0]
#
#
#Span Dimension
span = [1.0]
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
ENDSU = [1.0,0.05,0.0]
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

if WAVE_TYPE[0] == W1:
	ztop_pos = AMPLITUDE * np.sin(np.radians(nperiod[0]*np.array(y_pos))) + ENDSU[1]
	zbot_pos = AMPLITUDE * np.sin(np.radians(nperiod[0]*np.array(y_pos))) - ENDSL[1]
elif WAVE_TYPE[0] == W2:
	AMPLITUDE = 0.25*max_thick*(1 -(WAVE_DEPTH[0]/100))
	ztop_pos = AMPLITUDE * np.cos(np.radians(nperiod[0]*np.array(y_pos))) + ENDSU[1] - AMPLITUDE
	zbot_pos = -AMPLITUDE * np.cos(np.radians(nperiod[0]*np.array(y_pos))) - ENDSL[1] + AMPLITUDE
elif WAVE_TYPE[0] == W3:
	ztop_pos = ENDSU[1] - AMPLITUDE * np.cos(np.radians(nperiod[0]*np.array(y_pos))) * np.sin(np.radians(nperiod[1]*np.array(y_pos)))
	zbot_pos =  - ENDSL[1] + AMPLITUDE * np.cos(np.radians(nperiod[0]*np.array(y_pos))) * np.sin(np.radians(nperiod[1]*np.array(y_pos)))

topnodes = np.stack((np.array(xtop_pos-1), np.array(ztop_pos-ENDSU[1])))
botnodes = np.stack((np.array(xbot_pos-1), np.array(zbot_pos+ENDSL[1])))

for i in range(int(len(y_pos))):
	topnodes.T[:][i] = rtop.dot(topnodes.T[:][i])
	botnodes.T[:][i] = rbot.dot(botnodes.T[:][i])

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
wave1=np.column_stack((ffxtop_pos, y_pos, ffztop_pos))

#GRID PROPERTIES INCH
wave2=np.column_stack((ffxbot_pos, y_pos, ffzbot_pos))


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

