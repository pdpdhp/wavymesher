Wavy Mesher
================================

Introduction:
-------------
These scripts are written to generate flatback model of any airfoil and add waviness to the trailing edge of
the flatback model. At the end of the program the whole quasi 2D structured grid over the model of interest could be saved or exported. It has control over flatback back model specification, waviness parameters and grid specifications. In order to run the script modify the input file (i.e. customized_meshparameters.template) and follow the below instruction. When nothing as input mesh parameters is selected, default mesh parameters are used.

Batch
-----
```shell
pointwise -b wvymesher.glf ?MeshParameters.glf? airfoil_coordinates.txt <airfoil File>
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

Flatback Model Specificity:
---------------------------
Flatback profiles are created by smoothly adding to the thickness of aft camber line that results in a blunt base with a width know as percentage of chord. If flatback profile for an airfoil is not known, using below option it can be created. To add thickness to the original airfoil and have the flatback shape, two methods are implemented. The first one is the default by which scaled thickness difference from the maximum thickness location is being added to the aft portion. The second approach is a based on a fitted function that has been obtained from thickness distribution of DU97W300 and DU97Flatback. This function indicated as DU97function generates thickness differences to be added to the original airfoil. When it used with DU97W300, it gives the DU97flatback. It also can be used with other airfoils have their flatback model. Flatback percent indicates percentage of blunt base in comparison to the chord. When FLATBACK_GEN is set to NO, scripts uses the input airfoil coordinates for geometry creation, waviness and mesh generations.

```shell
#FLATBACK PROFILE GENERATION BASED ON INPUT AIRFOIL
#====================================================
#indicate if you need to generate flatback profile based on your input airfoil coordinates

set FLATBACK_GEN                   NO;# (YES/NO)

set FLATBACK_GEN_METHOD       default;# (default/DU97function) method to distribute thickness

set FLATBACK_PERCENT               10;# (%) percent of chord length
```

Waviness Specificity
--------------------
Three methods are implemented to generate the waves at TE. The default adds scaled thickness difference to the aft wavy portion to obtain streamwise thickness distribution. The DU97function uses the fitted function to add thickness difference to the aft wavy portion and have wavy streamwise thickness distribution. The spline simply creates spline between start and end of the wave in streamwise direction. Three types of waves are available. W1 is a sine function, W2 is a cosine function and W3 is cosine × sine. Ratio of min thickness of wavy trailing edge to max thickness of wavy trailing can be adjusted by WAVE\_DEPTH. Percentage of aft portion of chord for waviness can be adjusted by WAVE\_PERCENT. Amplitude is for W1 and W3. At last, number of waves can be set by NUM\_WAVE. Cosine function needs even number since it has identical at start and end of the span. W3 needs two wave numbers seperated by comma (,) corresponding to cosine and sine functions.

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

Wavy Spline Specificity
-----------------------
When spline is selected for waviness, tangent surface vector are used to keep C1 continuty where wave meets the surface of flatback model. To manipulate the spline where wave meets the flatback surface, WAVE\_inVScale can be adjusted. To manipulate the spline where wave ends at 100% chord, WAVE\_outVScale can be adjusted. To manipulate the bezier curve at end of the waves, two angles WAVE\_outTopVdeg and WAVE\_outBottomVdeg can be adjusted corresponding to the upper and lower waves. First one rotates clockwise, second one rotates counter-clockwise. In addition, upper and lower wavy curves at 100% chord can be rotated along latheral direction that lead to zig-zig types of waves. These two rotational angles can be adjusted by ZZ\_Atop and ZZ\_Abot.

```shell
#WAVY PARAMETERS ONLY FOR SPLINE METHOD FOR WAVY STREAMWISE THICKNESS DISTRIBUTION 
#----------------------------------------------------------------------------------
#wave inner surface tangent vector scale
set WAVE_inVScale                 1.5;# tangent vector scale where wave meets surface

#wave outter surface tangent vector scale
set WAVE_outVScale                0.9;# tangent vector scale where wave ends at TE 

#wave tanget vector angle (degree) at 100% chord | TOP
set WAVE_outTopVdeg               5.4;# (default/ a real number)

#wave tanget vector angle (degree) at 100% chord | BOTTOM
set WAVE_outBottomVdeg           15.0;# (default/ a real number)

#top wave rotational angle | TOP
set ZZ_Atop                         0;# (deg) lets wave rotates counter clockwise at upper edge

#bottom wave rotational angle | BOTTOM
set ZZ_Abot                         0;# (deg) lets wave rotates clockwise at lower edge
```

Mesh Specificity
----------------
Meshing specification can be defined at the bottom part of the mesh parameters input file. They are created in form list so series of meshes with different resolution can be defined and generation. Res_Lev at the top of the mesh parameter file correspond to mesh specification indicies. The last one is the coarsest level. The mesh is sctruded in normal direction and then the domain is extruded in spanwise direction. WV\_NOD indicates number of mesh nodes per half wave.

```shell
#---------------------GRID GUIDELINE SPECIFICATIONS--------------------------------
#EACH CORRESPONDING ELEMENT REPRESENT A GRID LEVEL INDICATED AT TOP TO BE GENERATED

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

