Wavy Mesher
================================

Introduction:
-------------
This script is written to generate flatback model of any airfoil, add wavy shapes to the trailing edge, and generate structured mesh for that model. At the end of the program the whole quasi 2D structured grid over the flatback/wavy-flatback model of interest can be saved or exported. It gives full control over the flatback/wavy-flatback model, wavy parameters and grid specifications. In order to run the program, modify the input file (i.e. customized_meshparameters.template) and follow below instruction. When nothing as input mesh parameters is selected or specified, default parameters are used.

Batch
-----
```shell
pointwise -b wvymesher.glf ?MeshParameters.glf? airfoil_coordinates.txt <airfoil file>
```

GUI
---
![GUI](https://github.com/pdpdhp/wavymesher/blob/main/wavymesherGUI.png)

Input Airfoil Coordinates:
--------------------------
Input airfoil coordinates must be in two columns seperated by a comma (,) starting from the trailing edge point of the upper surface to the trailing edge point of the lower surface.

```shell
first row of airfoil coordinates: x0, y0 --> Upper TE point
.
.
.
last row of airfoil coordinates: xn, yn --> Lower TE point
```

Flatback Model Parameters:
---------------------------
Flatback profile is created by smoothly adding to the thickness of aft camber line that results in a blunt base with a width specified as percentage of chord. If flatback profile for an airfoil is not available, it can be created. In order to add thickness to the original shape and have the flatback shape, two methods are implemented. The first one is indicated as 'default' and through which scaled thickness difference from the maximum thickness location is added to the aft portion. The second approach is a based on a fitted function that obtained from thickness distribution of DU97W300 and DU97Flatback. This function indicated as 'DU97function' generates thickness difference distribution to be added to the original shape in order to obtain the flatback shape. When this function is used with DU97W300 airfoil, DU97flatback is obtained. This fitted thickness distribution function also can be used with other airfoils and have their flatback shapes. Flatback percent indicates percentage of blunt base with respect to the chord. When FLATBACK_GEN is NO, scripts uses the input airfoil coordinates to create the geometry, waviness and generate the mesh.

```shell
#FLATBACK PROFILE GENERATION BASED ON INPUT AIRFOIL
#====================================================
#indicate if you need to generate flatback profile based on your input airfoil coordinates

set FLATBACK_GEN                   NO;# (YES/NO)

set FLATBACK_GEN_METHOD       default;# (default/DU97function) method to distribute thickness

set FLATBACK_PERCENT               10;# (%) percent of chord length
```

Waviness Parameters:
--------------------
Three options are available to generate waves at trailing edge. The default method adds scaled thickness difference to the aft wavy portion to obtain streamwise thickness distribution of flatback model. The DU97function uses a fitted function to generate the thickness difference distribution for the aft wavy portion and have the wavy streamwise thickness distribution. The spline method simply creates series of spline between start and end of the wave in streamwise direction. Meanwhile, three types of waves are available. W1 is a sine function, W2 is a cosine function and W3 is cosine × sine function. Ratio of min thickness at wavy trailing edge to max thickness at wavy trailing can be modified by WAVE\_DEPTH. Percentage of aft portion of chord for wavy generation can be adjusted by WAVE\_PERCENT. Amplitude of the wave is only an option for W1 and W3 waves. At last, number of waves can be selected by NUM\_WAVE. Cosine function needs even number of waves, since the wavy model has identical shape at start and end of the span. W3 wave requires two wave numbers seperated by comma (,) corresponding to cosine and sine of the wave function.

```shell
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
```

Wavy Spline Method:
-------------------
When spline is selected for wavy parametrization, spline segment vector are used to keep C1 continuty where wave meets the surface of flatback model. To manipulate the shape of spline curve where wave meets the flatback surface, WAVE\_Begin\_Segment\_Scale can be modified. To manipulate the shape of spline where wave ends at the end of the chord, WAVE\_End\_Segment_Scale can be adjusted. To manipulate the ending points of spline curve where wave ends, two angles WAVE\_Top\_Segment\_Angle and WAVE\_Bottom\_Segment\_Angle can be modified representing the spline of upper and lower waves. First one rotates clockwise, second one rotates counter-clockwise. In addition, upper and lower wavy curves at 100% of chord can be rotated along the latheral direction to have zig-zig shape of waves at trailing edge. These two rotational angles can be adjusted by WAVE\_Rotational\_Angle\_Top and WAVE\_Rotational\_Angle\_Bottom.

```shell
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
```

Mesh Specificity:
-----------------
Meshing specifications can be defined at the bottom part of the mesh parameters input file. They represent lists so series of meshes with different resolution can be defined and be generated. At the top of the mesh parameter file, grid refinement level is inidcated as 'res_lev' and it indicates index of mesh specification parameter in each list. The last element in the list represents the coarsest level. WV\_NOD meshing parameter indicates number of mesh nodes per wave.

```shell
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
set EXP_FAC                                                  {0.9,0.9,0.9,0.9,0.9}

# IMPLICIT EXTRUSION FACTORS ACCORDING TO GRID GUIDELINE
set IMP_FAC                                                  {100,100,100,100,100}

# NORMAL EXTRUSION VOLUME RATIO ACCORDING TO GRID GUIDELINE
set VOL_FAC                                              {0.45,0.45,0.45,0.45,0.5}
```

