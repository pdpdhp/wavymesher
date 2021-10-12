# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

#               GRID REFINEMENT LEVEL:
#====================================================
#Grid Levels vary from the first line (finest, level 0) 
#corresponding to last to first elements of grid guideline below.
set res_lev                         4;# From  0 (finest) to (coarsest) | last elements are for coarsest

#GRID SYSTEM'S ARRANGEMENT: STRUCTURED OR UNSTRUCTRED
#====================================================
#PLEASE SELECT GRID SYSTEM:
set GRD_TYP                       STR;# STR (for STRUCTURED)

#FLATBACK PROFILE GENERATION BASED ON INPUT AIRFOIL
#====================================================
#indicate if you need to generate flatback profile based on your input airfoil coordinates

set FLATBACK_GEN                   NO;# (YES/NO)

set FLATBACK_GEN_METHOD       default;# (default/DU97function) method to distribute thickness

set FLATBACK_PERCENT               10;# (%) percent of chord length

#WAVINESS SPECIFICATION FOR FLATBACK PROFILE
#====================================================
#inidcate how do you want to generate waviness at TE on your flatback airfoil

set WAVE_GEN_METHOD           default;# (default/DU97function/spline) method to distribute thickness on waves

#types of wavyness
set WAVE_TYPE                      W2;# W1: sine function | W2: cosine function (uses wave depth)| W3: cos.sin

#Percent of min/max thickness
set WAVE_DEPTH                     50;# ratio of min to max thickness at wavy TE

#Percent of waviness at TE
set WAVE_PERCENT                   10;# (%) percent of chord length on which waviness grows at TE 

#Wavy Parameters
set AMPLITUDE                  0.0125;# ampl. of wave for only for W1 and W3 types

#Number of Waves 
set NUM_WAVE                        4;# W2 needs even number | W3 needs two numbers (i.e. 4,1) --> cos and sin

#WAVY PARAMETERS ONLY FOR SPLINE METHOD 
#----------------------------------------------------
#wave inner surface tangent vector scale 
set WAVE_Begin_Segment_Scale      1.5;# tangent vector scale where wave meets surface

#wave outter surface tangent vector scale 
set WAVE_End_Segment_Scale        0.9;# tangent vector scale where wave ends at TE 

#wave tanget vector angle (degree) at 100% chord | TOP 
set WAVE_Top_Segment_Angle        5.4;# (default OR a real number)

#wave tanget vector angle (degree) at 100% chord | BOTTOM 
set WAVE_Bottom_Segment_Angle    15.0;# (default OR a real number)

#top wave rotational angle | TOP 
set WAVE_Rotational_Angle_Top       0;# (deg) lets wave rotates counter clockwise at upper edge

#bottom wave rotational angle | BOTTOM 
set WAVE_Rotational_Angle_Bottom    0;# (deg) lets wave rotates clockwise at lower edge

#STRUCTURED SETTINGS:
#====================================================
# approximate total diameter of o-type grid 
set TOTAL_HEIGHT                  600;# 

#GRID DIMENSION:
#====================================================
#SPAN DIMENSION FOR QUASI 2D MODEL IN -Y DIRECTION
set span                          1.0;#

#Fix number of points in spanwise direction? If YES, indicate number of points below. 
set fixed_snodes                   NO;# (YES/NO)

#Number of points in spanwise direction. When NO, it will be ignored and set
# automatically based on maximum spacing over profile.
set span_dimension                 44;# effective only when fixed_snodes is NO

#MODEL EXPORT:
#===================================================
#TO EXPORT FLATBACK MODEL'S CAD FILE
set FLATBACK_export               YES;# (YES/NO)

#TOP EXPORT WAVY FLATBACK MODEL'S CAD FILE
set WAVY_FLATBACK_export          YES;# (YES/NO)

#CAE EXPORT:
#===================================================
#CAE SOLVER SELECTION. 
set cae_solver                   CGNS;# (Exp. SU2 or CGNS)

#POLYNOMIAL DEGREE FOR HIGH ORDER MESH EXPORT 
set POLY_DEG                       Q1;# (Q1:Linear - Q4:quartic) | FOR SU2 ONLY Q1

#ENABLES CAE EXPORT 
set cae_export                    YES;# (YES/NO)

#SAVES NATIVE FORMATS 
set save_native                    NO;# (YES/NO)

#---------------------GRID GUIDELINE SPECIFICATIONS--------------------------------
#EACH CORRESPONDING ELEMENT REPRESENT A GRID LEVEL INDICATED AT TOP

#TARGET Y PLUS FOR RANS AND HYBRID RANS/LES
set TARG_YPR                                    {0.04488,0.08977,1.0,3.591,10.181}

#BOUNDARY BLOCK CELL GROWTH RATE
set TARG_GR                                             {1.12,1.14,1.16,1.18,1.25}

# CHORDWISE SPACING ACCORDING TO GRID GUIDELINE
set CHR_SPC                              {0.0019375,0.003875,0.00775,0.0155,0.051}

# WAVE SPAVING GUIDELINE
set WV_NOD                                                         {56,36,20,12,5}

# TRAILING EDGE SPACING RATIO ACCORDING TO GRID GUIDELINE
set TE_SRT                           {0.00048,0.0012025,0.001925,0.0047625,0.0076}

# TRAILING EDGE NUMBER OF POINTS ACCORDING TO GRID GUIDELINE
set TE_PT                                                        {160,80,40,20,10}

# EXPLICIT EXTRUSION FACTORS ACCORDING TO GRID GUIDELINE
set EXP_FAC                                                  {0.1,0.1,0.1,0.1,0.1}

# IMPLICIT EXTRUSION FACTORS ACCORDING TO GRID GUIDELINE
set IMP_FAC                                                  {0.2,0.2,0.2,0.2,0.2}

# NORMAL EXTRUSION VOLUME RATIO ACCORDING TO GRID GUIDELINE
set VOL_FAC                                              {0.45,0.45,0.45,0.45,0.5}

#------------------------------------------------------------------------------------------
