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

import os
dirname = os.path.dirname(os.path.realpath(__file__))

Path(f"{dirname}").mkdir(parents=True, exist_ok=True)

#----------------------------GRID GUIDELINE--------------------
#TARGET Y PLUS FOR RANS AND HYBRID RANS/LES
TARG_YPR = [0.04488,0.08977,1.0,3.591,10.181]
#
#
#BOUNDARY BLOCK CELL GROWTH RATE
TARG_GR = [1.12,1.14,1.16,1.18,1.25]
#
#
# CHORDWISE SPACING ACCORDING TO GRID GUIDELINE
CHR_SPC = [0.0019375,0.003875,0.00775,0.0155,0.051]
#
#
# WAVE SPACINGS
WV_NOD = [56,36,20,12,5]
#
#
# TRAILING EDGE SPACING RATIO ACCORDING TO GRID GUIDELINE
TE_SRT = [0.00048,0.0012025,0.001925,0.0047625,0.0076]
#
#
# TRAILING EDGE NUMBER OF POINTS ACCORDING TO GRID GUIDELINE
TE_PT = [160,80,40,20,10]
#
#
# EXPLICIT EXTRUSION FACTORS ACCORDING TO GRID GUIDELINE
EXP_FAC = [0.45,0.45,0.45,0.45,0.45]
#
#
# IMPLICIT EXTRUSION FACTORS ACCORDING TO GRID GUIDELINE
IMP_FAC = [20.0,20.0,20.0,20.0,20.0]
#
#
# NORMAL EXTRUSION VOLUME RATIO ACCORDING TO GRID GUIDELINE
VOL_FAC = [0.45,0.45,0.45,0.45,0.5]
#
#====================================================================
#
NUM_LEVR = len(TARG_YPR)
#
#Flow Properties
#-----------------TEMPERATURE--------------
#(K)
T=288.15
#(R)
T_R = 489.78

#-----------------MACH NUMBER--------------
M=0.15

#------------------Reynolds----------------
Re = 10000000

#-----------------PRESSURE-----------------
#(Pa)
P=101325.0
#(psi)
P_psi=14.6959488

#-----------MEAN AERODYNAMIC CHORD--------
#(M)
D=1.0
#(INCH)
D_inch=1.0

#---------------GAS CONSTANT---------------
R=8314.4621
Rs=287.058
gama=1.4

#---------------IDEAL GAS-------------------
ro=P/((R/28.966)*T)

#---------------SOUND SPEED----------------
C=np.sqrt(gama*(P/ro))

#---------------VELOCITY-------------------
V=C*M

#KINEMATIC VISCOSITY/MOMENTOM DIFFUSIVITY--
no=(V*D)/Re

#--------DYNAMIC/ABSOLUTE VISCOSITY--------
mo=ro*no

#---REYNOLDS CHECK BASED ON IDEAL GAS------
Re1=(ro*V*D)/mo

#----SUTHERLAND LAW FOR FLOW PROPERTISE----
mo0 = 1.716e-05
mo0us = 2.488852e-9
T0 = 272.1
S = 110.4
Ts = T

#DYNAMIC/ABSOLUTE VISCOSITY based SUTHERLAND LAW
mos = mo0 * ((Ts/T0)**(3/2)) * ((T0 + S)/(Ts + S))

#-------DENSITY BASED ON SUTHERLAND ----------
ros = ((mos * Re)/(((gama*P)**0.5)*M*D))**2

#-----DENSITY BASED ON SUTHERLAND US----------
ros_lbinch3 = ros*3.6127292000084e-5

#-----SOUND SPEED BASED ON SUTHERLAND---------
Cs = np.sqrt(gama*(P/ros))

#-------VELOCITY BASED ON SUTHERLAND----------
Vs = Cs*M

#-----REYNOLD CHECK BASED ON SUTHERLAND-------
Res = (ros*Vs*D)/mos

#------------y+ calculation--------------------
#scholchting_skin_friction
cf=(2*np.log10(Re)-0.65)**(-2.3)

#----------WALL SHEAR STRESS------------------
ta_w=cf*0.5*ro*(V**2)
ta_ws=cf*0.5*ros*(Vs**2)

#-----------FRICTION VELOCITY----------------
us=np.sqrt(ta_w/ro)
uss=np.sqrt(ta_ws/ros)

# ---------- GRID PROPERTISE-----------------

Chord=D
chord_csize=np.array(CHR_SPC)*Chord
chord_csize_inch=chord_csize*39.37

ypr=np.array(TARG_YPR)

gr=np.array(TARG_GR)

wspc=np.array(WV_NOD)

teratio=np.array(TE_SRT)
leratio= teratio/2

te1_points=np.array(TE_PT)


Exp=np.array(EXP_FAC)
Imp=np.array(IMP_FAC)
Vol=np.array(VOL_FAC)

#-----------FIRST CELL HEIGHT | DELTA S-------
dsr=(ypr*mo)/(ro*us)
dssr=(ypr*mos)/(ros*uss)
dsr_inch=dsr*39.37
dssr_inch=dssr*39.37

#------------------GRID PROPERTISE--------------
grid_spec=np.column_stack((ypr,dssr,gr,chord_csize[0:NUM_LEVR],wspc[0:NUM_LEVR],teratio[0:NUM_LEVR],leratio[0:NUM_LEVR],te1_points[0:NUM_LEVR],Exp[0:NUM_LEVR],Imp[0:NUM_LEVR],Vol[0:NUM_LEVR]))

#------------------FLOW PROPERTISE--------------
#FLOW PROPERTISE BASED ON SUTHERLAND | SI

flow_spec_si=np.array([Res,D,P,T,ros,M])

#------------writing files---------------------
# grid propertise metric
f = open(f'{dirname}/grid_specification_metric.txt', 'w')
f.write("%7s %17s %9s %13s %10s %10s %10s %4s %9s %10s %10s\n" % ("Y+","Delta_S(m)","GR","Chord_Spc","Wave_Spc","TE Ratio","LE Ratio","TE","ExpExtr","ImpExtr","VolExtr"))

for i in range(NUM_LEVR):
    f.write(" % 1.3e  % 1.7e % 1.3e % 1.3e % 1.3e % 1.3e % 1.3e % 4d % 1.3e % 1.3e % 1.3e\n" % \
	(grid_spec[i,0],grid_spec[i,1],grid_spec[i,2],grid_spec[i,3],grid_spec[i,4],grid_spec[i,5],\
		grid_spec[i,6],grid_spec[i,7],grid_spec[i,8],grid_spec[i,9],grid_spec[i,10]))
f.close()

f = open(f'{dirname}/flow_propertise_si.txt', 'w')
f.write("%10s %14s %12s %12s %20s %10s \n" % ("Reynolds","Ref_chord(m)","Pressure(Pa)","Temp(K)","Density(Kg/m3)","Mach"))

f.write("%1.5e  %1.5e %1.7e  %1.7e %1.15e  %1.5e\r\n" % (flow_spec_si[0],flow_spec_si[1],\
								flow_spec_si[2],flow_spec_si[3],flow_spec_si[4],flow_spec_si[5]))
f.close()

