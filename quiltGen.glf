# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc MDL_GEN { flatback } {
	
	global span nxnodes nynodes airfoil_mdl FLTB_Crvs0 FLTB_Crvs1 TE_thk ENDSU ENDSL
	global airfoil_input
	
	upvar 1 symsepdd asep
	upvar 1 NprofullFilename nprofile
	
	set airfoil_input [lindex [split $nprofile '/'] end]
	
	set flt [lindex $flatback 0]
	set fltmethod [lindex $flatback 1]
	set fltpercent [lindex $flatback 2]
	
	if {[string compare $flt YES]==0} {
		
		set nprofile_crvs [surface_curve [uplow_surfaces $nxnodes $nynodes]]
		
		surface_scale $nprofile_crvs
		
		set FLTB_Cords [flatback_magic $flt $fltmethod \
					[lindex $nprofile_crvs 0] [lindex $nprofile_crvs 1] $fltpercent]
		
		puts "FLATBACK COORDINATES ($fltpercent% OF CHORD) ARE GENERATED BY $fltmethod METHOD."
		puts $asep
		
	} else {
		
		set FLTB_Cords [uplow_surfaces $nxnodes $nynodes]
		
		puts "NO FLATBACK COORDINATES ARE CALCULATED."
		puts $asep
	}
	
	set FLTB_Crvs0 [surface_curve $FLTB_Cords]
	set FLTB_Crvs1 [surface_curve $FLTB_Cords]
	
	if { ! [string compare $flt NO]} { surface_scale [list $FLTB_Crvs0 $FLTB_Crvs1] }
	
	set ENDS_u [[lindex $FLTB_Crvs0 0] getXYZ -arc 1]
	set ENDS_l [[lindex $FLTB_Crvs0 1] getXYZ -arc 1]
	
	set TE_thk [expr abs([lindex $ENDS_u 1] - [lindex $ENDS_l 1])]
	
	set ENDSU "[lindex $ENDS_u 0],[lindex $ENDS_u 1],[lindex $ENDS_u 2]"
	set ENDSL "[lindex $ENDS_l 0],[lindex $ENDS_l 1],[lindex $ENDS_l 2]"
	
	pw::Entity transform [pwu::Transform translation [list 0 0 $span]] $FLTB_Crvs1
	
	foreach crv0 $FLTB_Crvs0 crv1 $FLTB_Crvs1 {
		set seg_te [pw::SegmentSpline create]
			$seg_te addPoint [$crv0 getXYZ -arc 1]
			$seg_te addPoint [$crv1 getXYZ -arc 1]
		lappend TE_Crvs [pw::Curve create]
		[lindex $TE_Crvs end] addSegment $seg_te
	}
	
	set seg_le [pw::SegmentSpline create]
		$seg_le addPoint [[lindex $FLTB_Crvs0 0] getXYZ -arc 0]
		$seg_le addPoint [[lindex $FLTB_Crvs1 0] getXYZ -arc 0]
	set LE_Crv [pw::Curve create]
	$LE_Crv addSegment $seg_le
	
	foreach crv0 $FLTB_Crvs0 crv1 $FLTB_Crvs1 crvte $TE_Crvs {

		lappend airfoil_Srfs [pw::Surface create]
		
		[lindex $airfoil_Srfs end] patch -tolerance 1e-20 -surfaceTolerance 1e-20 \
							-fitTolerance 1e-20 -fitInterior 1 \
									$crv0 $TE_Crvs $crv1 $LE_Crv
	}
	
	set TE_Srf [pw::Surface create]
	$TE_Srf interpolate -orient Same [lindex $TE_Crvs 0] [lindex $TE_Crvs 1]
	
	set airfoil_mdl [pw::Model assemble [list {*}$airfoil_Srfs $TE_Srf]]
	
	if {[string compare $flt YES]==0} {
	
		puts "QUASI 2D MODEL IS GENERATED BASED ON FLATBACK PROFILE OVER $span SPAN."
		puts $asep
	
	} else {
		puts "QUASI 2D MODEL IS GENERATED BASED ON '$airfoil_input' OVER $span SPAN."
		puts $asep
	}
	
}
