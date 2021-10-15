# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc ParamDefualt {fdef} {

	set fdefinterp [interp create -safe]

	set fp [open $fdef r]
	set defscript [read $fp]
	close $fp

	$fdefinterp eval $defscript

	global res_lev GRD_TYP FLATBACK_GEN FLATBACK_GEN_METHOD FLATBACK_PERCENT WAVE_GEN_METHOD \
		WAVE_TYPE WAVE_DEPTH WAVE_PERCENT AMPLITUDE NUM_WAVE WAVE_Begin_Segment_Scale \
		WAVE_End_Segment_Scale WAVE_Top_Segment_Angle WAVE_Bottom_Segment_Angle \
		WAVE_Rotational_Angle_Top WAVE_Rotational_Angle_Bottom TOTAL_HEIGHT UNS_ALG UNS_CTYP \
		SIZE_DCY span fixed_snodes span_dimension FLATBACK_export WAVY_FLATBACK_export cae_solver \
		POLY_DEG cae_export save_native REYNOLDS_NUM MACH TARG_YPR TARG_GR CHR_SPC WV_NOD TE_SRT TE_PT \
		EXP_FAC IMP_FAC VOL_FAC 
	
	set defParas [list res_lev GRD_TYP FLATBACK_GEN FLATBACK_GEN_METHOD FLATBACK_PERCENT WAVE_GEN_METHOD \
			WAVE_TYPE WAVE_DEPTH WAVE_PERCENT AMPLITUDE NUM_WAVE WAVE_Begin_Segment_Scale \
			WAVE_End_Segment_Scale WAVE_Top_Segment_Angle WAVE_Bottom_Segment_Angle \
			WAVE_Rotational_Angle_Top WAVE_Rotational_Angle_Bottom TOTAL_HEIGHT UNS_ALG UNS_CTYP \
			SIZE_DCY span fixed_snodes span_dimension FLATBACK_export WAVY_FLATBACK_export \
			cae_solver POLY_DEG cae_export save_native REYNOLDS_NUM MACH TARG_YPR TARG_GR CHR_SPC \
			WV_NOD TE_SRT TE_PT EXP_FAC IMP_FAC VOL_FAC]

	foreach para $defParas {
		set parav [$fdefinterp eval "set ${para}"]
			set ${para} $parav
			lappend meshparacol [list $parav]
	}
	
	return [list $defParas $meshparacol]
}
