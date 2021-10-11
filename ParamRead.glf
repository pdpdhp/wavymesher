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
		WAVE_TYPE WAVE_DEPTH WAVE_PERCENT AMPLITUDE NUM_WAVE WAVE_inVScale WAVE_outVScale \
		 WAVE_outTopVdeg WAVE_outBottomVdeg ZZ_Atop ZZ_Abot TOTAL_HEIGHT span fixed_snodes \
		  span_dimension cae_solver POLY_DEG cae_export save_native TARG_YPR TARG_GR CHR_SPC \
		   WV_NOD TE_SRT TE_PT EXP_FAC IMP_FAC VOL_FAC defParas meshparacol

	set defParas [list res_lev GRD_TYP FLATBACK_GEN FLATBACK_GEN_METHOD FLATBACK_PERCENT WAVE_GEN_METHOD \
			WAVE_TYPE WAVE_DEPTH WAVE_PERCENT AMPLITUDE NUM_WAVE WAVE_inVScale WAVE_outVScale \
			 WAVE_outTopVdeg WAVE_outBottomVdeg ZZ_Atop ZZ_Abot TOTAL_HEIGHT span fixed_snodes \
			  span_dimension cae_solver POLY_DEG cae_export save_native TARG_YPR TARG_GR CHR_SPC \
			   WV_NOD TE_SRT TE_PT EXP_FAC IMP_FAC VOL_FAC]

	foreach para $defParas {
		set parav [$fdefinterp eval "set ${para}"]
			set ${para} $parav
			lappend meshparacol [list $parav]
	}
	
	return 0
}
