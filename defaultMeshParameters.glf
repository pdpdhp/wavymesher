# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

#            DU97 Flatback PROFILE:
#=====================================================
set airfoil                  FLATBACK;#

#               GRID REFINEMENT LEVEL:
#=====================================================
#Grid Levels vary from the first line (finest, level 0) of the grid_specification.txt to the last line (coarsest, level 6)!
set res_lev                         3;# From  0 (finest) to 6 (coarsest)

#GRID SYSTEM'S ARRANGEMENT: STRUCTURED OR UNSTRUCTRED
#====================================================
#PLEASE SELECT GRID SYSTEM:
set GRD_TYP                       STR;# STR (for STRUCTURED) | UNSTR (for UNSTRUCTURED)

# STRUCTURED SETTINGS:
#====================================================
#total height for farfield boundary condition
set Total_Height                  600;# 

#types of wavyness
set Wave_Type                      W2;# W1: sine function | W2: cosine function (uses wave depth)| W3: cos.sin

#Percent of min/max thickness
set Wave_Depth                     50;# ratio of min to max thickness at TE

#Percent of waviness at TE
set Wavy_Percent                   10;# percent of waviness at TE 

#top wave rotational angle
set ZZ_Atop                         0;# 

#bottom wave rotational angle
set ZZ_Abot                         0;# 

#Wavy Parameters
set Amplitude                  0.0125;# effective only for W1 and W3

#Number of Waves 
set Num_Wave                        4;# for W3 needs two numbers (i.e. 4,1) indicating cos and sin no. of waves | W2 requires even number

#wave inner surface tangent vector scale
set Wave_inVScale                 1.5;# inner tangent vector scale where wave meets the DU97 surface

#wave outter surface tangent vector scale
set Wave_outVScale                0.4;# outter tangent vector scale where wave ends at TE.

#wave tanget vector angle (degree) at 100% chord | TOP
set Wave_outTopVdeg              18.4;# (Default or a real number to indicate angle of wave at 100% TE)

#wave tanget vector angle (degree) at 100% chord | BOTTOM
set Wave_outBottomVdeg           15.0;# (Default or a real number to indicate angle of wave at 100% TE)


# GRID DIMENSION:
#===================================================
#SPAN DIMENSION FOR QUASI 2D MODEL IN -Y DIRECTION
set span                          1.0;# MAXIMUM 3.0

#Fix number of points in spanwise direction? If YES, indicate number of points below. 
set fixed_snodes                   NO;# (YES/NO)

#Number of points in spanwise direction. If you opt NO above, This parameter will be ignored
# and will be set automatically based on maximum spacing over wing, slat and flap.
set span_dimension                 44;# Only when fixed_snodes is NO

#CAE EXPORT:
#===================================================
#CAE SOLVER SELECTION. 
set cae_solver                   CGNS;# (Exp. SU2 or CGNS)

#POLYNOMIAL DEGREE FOR HIGH ORDER MESH EXPORT 
set POLY_DEG                       Q1;# (Q1:Linear - Q4:quartic) | FOR SU2 ONLY Q1

#ENABLES CAE EXPORT 
set cae_export                    YES;# (YES/NO)

#SAVES NATIVE FORMATS 
set save_native                   YES;# (YES/NO)

#-------------------------------------- GRID GUIDELINE--------------------------------------

#TARGET Y PLUS FOR RANS AND HYBRID RANS/LES
set TARG_YPR                           {0.04488,0.08977,1.0,3.591,10.181}

#BOUNDARY BLOCK CELL GROWTH RATE
set TARG_GR                                    {1.12,1.14,1.16,1.18,1.25}

# CHORDWISE SPACING ACCORDING TO GRID GUIDELINE
set CHR_SPC                     {0.0019375,0.003875,0.00775,0.0155,0.051}

# WAVE SPAVING GUIDELINE
set WV_NOD                                                {56,36,20,12,5}

# TRAILING EDGE SPACING RATIO ACCORDING TO GRID GUIDELINE
set TE_SRT                  {0.00048,0.0012025,0.001925,0.0047625,0.0076}

# TRAILING EDGE NUMBER OF POINTS ACCORDING TO GRID GUIDELINE
set TE_PT                                               {160,80,40,20,10}

# EXPLICIT EXTRUSION FACTORS ACCORDING TO GRID GUIDELINE
set EXP_FAC                                         {0.9,0.9,0.9,0.9,0.9}

# IMPLICIT EXTRUSION FACTORS ACCORDING TO GRID GUIDELINE
set IMP_FAC                                         {100,100,100,100,100}

# NORMAL EXTRUSION VOLUME RATIO ACCORDING TO GRID GUIDELINE
set VOL_FAC                                     {0.45,0.45,0.45,0.45,0.5}

#------------------------------------------------------------------------------------------
