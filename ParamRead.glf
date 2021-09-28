# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc ParamDefualt {fdef} {

	set fdefinterp [interp create -safe]

	set fp [open $fdef r]
	set defscript [read $fp]
	close $fp

	$fdefinterp eval $defscript

	global airfoil res_lev GRD_TYP Total_Height Wave_Type Wave_Depth Wavy_Percent ZZ_Atop ZZ_Abot Amplitude Num_Wave \
		 span fixed_snodes span_dimension cae_solver \
			POLY_DEG cae_export save_native TARG_YPR TARG_GR CHR_SPC WV_NOD TE_SRT TE_PT \
							EXP_FAC IMP_FAC VOL_FAC defParas meshparacol

	set defParas [list airfoil res_lev GRD_TYP Total_Height Wave_Type Wave_Depth Wavy_Percent ZZ_Atop ZZ_Abot Amplitude \
		Num_Wave span fixed_snodes span_dimension cae_solver \
			POLY_DEG cae_export save_native TARG_YPR TARG_GR CHR_SPC WV_NOD TE_SRT \
									TE_PT EXP_FAC IMP_FAC VOL_FAC]

	foreach para $defParas {
		set parav [$fdefinterp eval "set ${para}"]
			set ${para} $parav
			lappend meshparacol [list $parav]
	}
	
	return 0
}
