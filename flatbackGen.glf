# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc .. {a {b ""} {step 1}} {
	if {$b eq ""} {set b $a; set a 0} ;
	if {![string is int $a] || ![string is int $b]} {
		scan $a %c a; scan $b %c b
		incr b $step ;
		set mode %c
	} else {set mode %d}
	set ss [sgn $step]
	if {[sgn [expr {$b - $a}]] == $ss} {
		set res [format $mode $a]
		while {[sgn [expr {$b-$step-$a}]] == $ss} {
			lappend res [format $mode [incr a $step]]
		}
	set res
	} ;
}

proc sgn x {expr {($x>0) - ($x<0)}}

# wavy/flatback thickness distributor based on du97 function 
proc Flbk_SrfDUTHDis { xu xl Ucrv Lcrv {Wave NO} {wdepth 50}} {
	
	global ref_u ref_l endtk_u endtk_l chordln xuref xlref end_tu end_tl eps pi
	
	upvar 1 FLT_PRC_UP flatback_percent
	
	if { [string compare $Wave YES]==0 } {
		set te_tk [expr $wdepth*0.01*([lindex [$Ucrv getXYZ -X $chordln] 1] - \
							[lindex [$Lcrv getXYZ -X $chordln] 1])]
	} else {
		set te_tk [expr [lindex [$Ucrv getXYZ -X $chordln] 1] - [lindex [$Lcrv getXYZ -X $chordln] 1]]
	}
	

	foreach x $xu {

		lappend u_tk [$Ucrv getXYZ -X $x]
	
		if {$x>$xuref} {
			
			set xutk [lindex [lindex $u_tk end] 0]
			set dutk [expr ($ref_u - abs([lindex [lindex $u_tk end] 1]))]
			set sign 1
			set tg_s 1
			
			set up_thk_dis [upper_flatback_thickness_dis $xutk $dutk $flatback_percent \
											$endtk_u $te_tk]

			# messy correction when it generates waviness at aft portion | UPPER SURFACE
			if { [string compare $Wave YES]==0 } {
				
				set sign -1
				set up_thk_dis [expr ((($x-$xuref)/($chordln-$xuref))**1.02)*$up_thk_dis]
				
				if {teq(0, $up_thk_dis)} { set up_thk_dis $eps }
				
				set xvar [expr (($x-$xlref)/($chordln-$xlref))]
				
				set tg_s [expr ((1+cos($pi-$xvar*$pi*0.5))**2*\
					([lindex [lindex $u_tk end] 1] - $end_tu))/$up_thk_dis]
			}
			
			#node distribution of waviness portion
			lappend flatback_upper [list [lindex [lindex $u_tk end] 0] \
					[expr [lindex [lindex $u_tk end] 1] + $sign*$tg_s*$up_thk_dis]\
								 [lindex [lindex $u_tk end] 2] ]
		
		} else {
			
			#node distribution of none waviness portion
			lappend flatback_upper [list [lindex [lindex $u_tk end] 0] \
							[lindex [lindex $u_tk end] 1] \
								[lindex [lindex $u_tk end] 2] ]
		
		}
	}
	
	lappend rescue_d 0
	
	foreach x $xl {
	
		lappend l_tk [$Lcrv getXYZ -X $x]

		if {$x>$xlref} {
			
			set xltk [lindex [lindex $l_tk end] 0]
			set dltk [expr (abs($ref_l) - abs([lindex [lindex $l_tk end] 1]))]
			set sign 1
			set tg_s 1
			
			# messy correction when it generates waviness at aft portion | LOWER SURFACE
			if { [string compare $Wave YES]==0 } {
				set dltk [expr abs($dltk)]
				
				lappend rescue_d $dltk
			
				if {[lindex $rescue_d end]<[lindex $rescue_d end-1]} {
					set max_value [tcl::mathfunc::max {*}$rescue_d]
					set max_diff [expr $max_value - [lindex $rescue_d end]]
					set dltk [expr $max_value + $max_diff/3]
				}
				
				set dltk [expr ((($x-$xlref)/($chordln-$xlref))**1.03)*$dltk]
				
				set low_thk_dis [lower_flatback_thickness_dis $xltk $dltk $flatback_percent \
											$endtk_l $te_tk]
				
				if {teq(0, $low_thk_dis)} { set low_thk_dis $eps }
				
				set xvar [expr (($x-$xlref)/($chordln-$xlref))]
				
				set tg_s [expr ((1+cos($pi-$xvar*$pi*0.5))**1.5*\
						([lindex [lindex $l_tk end] 1] - $end_tl))/($low_thk_dis)]
				
			} else {
				
				set low_thk_dis [lower_flatback_thickness_dis $xltk $dltk $flatback_percent \
											$endtk_l $te_tk]
			}
			
			#node distribution of waviness portion
			lappend flatback_lower [list [lindex [lindex $l_tk end] 0] \
						[expr [lindex [lindex $l_tk end] 1] - \
						$tg_s*$sign*$low_thk_dis] [lindex [lindex $l_tk end] 2] ]

		} else {
			
			#node distribution of none waviness portion
			lappend flatback_lower [list [lindex [lindex $l_tk end] 0] \
							[lindex [lindex $l_tk end] 1] \
								[lindex [lindex $l_tk end] 2] ]
		}
	}

	return [list $flatback_upper $flatback_lower]
}

# wavy/flatback thickness distributor based on linear scaling of thickness differences (default)
proc Flbk_SrfDefault { xu xl Ucrv Lcrv uSc lSc {Wave NO}} {

	global ref_u ref_l xuref xlref chordln eps end_tu end_tl pi
	
	foreach x $xu {
	
		lappend u_tk [$Ucrv getXYZ -X $x]
		
		if {$x>=$xuref} {

			set xutk [lindex [lindex $u_tk end] 0]
			set dutk [expr (abs($ref_u) - abs([lindex [lindex $u_tk end] 1]))]
			set sign 1
			set tg_s 1
			
			set up_thk_dis [expr $uSc*abs($dutk)]
			
			# messy correction when it generates waviness at aft portion | UPPER SURFACE
			if { [string compare $Wave YES]==0 } {
				set sign 1
				set up_thk_dis [expr ((($x-$xuref)/($chordln-$xuref))**1.03)*$up_thk_dis]
			
				if {teq(0, $up_thk_dis)} { set up_thk_dis $eps }
				
				set xvar [expr (($x-$xlref)/($chordln-$xlref))]
				
				set tg_s [expr ((1+cos($pi-$xvar*$pi*0.5))**1.5*\
						([lindex [lindex $u_tk end] 1] - $end_tu))/$up_thk_dis]
			}
			
			#node distribution of waviness portion
			lappend flatback_upper [list [lindex [lindex $u_tk end] 0] \
					[expr [lindex [lindex $u_tk end] 1] - $sign*$tg_s*$up_thk_dis] \
								[lindex [lindex $u_tk end] 2] ]
		} else {
			
			#node distribution of none waviness portion
			lappend flatback_upper [list [lindex [lindex $u_tk end] 0] \
						[lindex [lindex $u_tk end] 1] \
							[lindex [lindex $u_tk end] 2] ]
		}
	}
	
	lappend rescue_d 0
	
	foreach x $xl {
	
		lappend l_tk [$Lcrv getXYZ -X $x]
		
		if {$x>$xlref} {
			set xltk [lindex [lindex $l_tk end] 0]
			set dltk [expr (abs($ref_l) - abs([lindex [lindex $l_tk end] 1]))]
			set sign 1
			set tg_s 1
			
			# messy correction when it generates waviness at aft portion | LOWER SURFACE
			if { [string compare $Wave YES]==0 } {
				set sign -1
				
				lappend rescue_d $dltk
			
				if {[lindex $rescue_d end]<[lindex $rescue_d end-1]} {
					set max_value [tcl::mathfunc::max {*}$rescue_d]
					set max_diff [expr $max_value - [lindex $rescue_d end]]
					set dltk [expr $max_value + $max_diff/3]
				}
				
				set dltk [expr ((($x-$xlref)/($chordln-$xlref))**1.5)*$dltk]
				
				set low_thk_dis [expr $lSc*abs($dltk)]
				
				if {teq(0, $low_thk_dis)} { set low_thk_dis $eps }
				
				set xvar [expr (($x-$xlref)/($chordln-$xlref))]
				
				set tg_s [expr ((1+cos($pi-$xvar*$pi*0.5))**1.05*\
						([lindex [lindex $l_tk end] 1] - $end_tl))/($low_thk_dis)]

			} else {
			
				set low_thk_dis [expr $lSc*abs($dltk)]
			}
			
			#node distribution of waviness portion
			lappend flatback_lower [list [lindex [lindex $l_tk end] 0] \
					[expr [lindex [lindex $l_tk end] 1] + $sign*$tg_s*$low_thk_dis] \
								[lindex [lindex $l_tk end] 2] ]
		} else {
			
			#node distribution of none waviness portion
			lappend flatback_lower [list [lindex [lindex $l_tk end] 0] \
					[lindex [lindex $l_tk end] 1] \
							[lindex [lindex $l_tk end] 2] ]
		}
	}
	
	return [list $flatback_upper $flatback_lower]
}

proc Flbk_NdDis {Flbk_Tag Ucrv Lcrv FLT_PRC {reDis 50}} {
	
	global chordln ref_u ref_l xuref xlref end_u end_l FLT_PRC_UP
	
	foreach pt [.. 0 1000] { lappend x_arcs [expr $pt/1000.0] }
	
	foreach x [list {*}$x_arcs 1.0] {
		lappend utk [lindex [$Ucrv getXYZ -arc $x] 1]
		lappend xutk [lindex [$Ucrv getXYZ -arc $x] 0]
		lappend ltk [lindex [$Lcrv getXYZ -arc $x] 1]
		lappend xltk [lindex [$Lcrv getXYZ -arc $x] 0]
	}
	
	set end_u [lindex [$Ucrv getXYZ -arc 1] 1]
	set end_l [lindex [$Lcrv getXYZ -arc 1] 1]
	
	if { [string compare $Flbk_Tag YES]==0 } {

		set max_utk [tcl::mathfunc::max {*}$utk]
		set min_ltk [tcl::mathfunc::min {*}$ltk]

		set max_utk_indx [lsearch $utk $max_utk]
		set min_ltk_indx [lsearch $ltk $min_ltk]

		set xuref [lindex $xutk $max_utk_indx]
		set xlref [lindex $xltk $min_ltk_indx]
		
		set FLT_PRC_UP $FLT_PRC 
		
	} else {
		
		set xuref [expr 0.01*(100-$reDis)*$chordln]
		set xlref $xuref
		set FLT_PRC_UP [expr (abs($end_u-$end_l)/$chordln)*100]
	}
	
	set xu_locs $xutk
	set xl_locs $xltk
		
	lappend u_tk [$Ucrv getXYZ -X $xuref]
	lappend l_tk [$Lcrv getXYZ -X $xlref]
		
	set ref_u [expr [lindex [lindex $u_tk 0] 1]]
	set ref_l [expr [lindex [lindex $l_tk 0] 1]]
	
	set refs [list $ref_u $ref_l]

	set ends [list $end_u $end_l]
	return [list $xu_locs $xl_locs $refs $ends]
}


#upper surface/lower surface
proc uplow_surfaces { xnodes ynodes } {
	
	set smr_swth [expr [lindex $ynodes 0] - [lindex $ynodes end]]

	set min_nxnodes [tcl::mathfunc::min {*}$xnodes]
	set min_inx [lsearch $xnodes $min_nxnodes]
	
	foreach upx [lrange $xnodes 0 $min_inx] upy [lrange $ynodes 0 $min_inx] {
		lappend upper_surf [list $upx $upy 0]
	}

	foreach lwx [lrange $xnodes $min_inx end] lwy [lrange $ynodes $min_inx end] {
		lappend lower_surf [list $lwx $lwy 0]
	}
	
	if { $smr_swth < 0 } {

		set low [lreverse $upper_surf]
		set upper_surf [lreverse $lower_surf]
		set lower_surf $low

	} elseif { $smr_swth == 0} {

		set smr_swth [expr [lindex $ynodes 1] - [lindex $ynodes end-1]]

		if { $smr_swth < 0 } {
			set low [lreverse $upper_surf]
			set upper_surf [lreverse $lower_surf]
			set lower_surf $low
		}
	}

	return [list [lreverse $upper_surf] $lower_surf]
}

#upper surface/lower surface's curves
proc surface_curve { surfaces } {

	foreach srf $surfaces {

		set Spsegment [pw::SegmentSpline create]
		$Spsegment setSlope Free
	
		foreach node $srf {
			$Spsegment addPoint [list [lindex $node 0] [lindex $node 1] [lindex $node 2]]
		}
	
		lappend Spcurve [pw::Curve create]
		[lindex $Spcurve end] addSegment $Spsegment
	
	}

	return $Spcurve
}

#upper surface/lower surface scale for precision
proc surface_scale { surfaces } {
	
	foreach srf $surfaces {
		pw::Entity transform [pwu::Transform scaling -anchor {0 0 0} {0.001 0.001 0.001}] $srf
	}

}

proc flt_specs { flt_Dsc flt_prc Ucrv Lcrv {wdpth 50}} {
	
	global ref_u ref_l endtk_u endtk_l chordln end_u end_l end_tu end_tl
	
	set endtk_u [expr abs($ref_u - $end_u)]
	set endtk_l [expr abs($ref_l - $end_l)]
	
	#scale factors for thickness distributions of default 
	set uscale [expr ($flt_prc*$chordln*0.01*0.5-abs($end_u))/$endtk_u]
	
	set lscale [expr abs($flt_prc*$chordln*0.01*0.5-abs($end_l))/$endtk_l]

	#getting min and max thickness at TE
	set max_te [expr abs($end_u - $end_l)*0.5]
	set min_te [expr $wdpth*0.01*$max_te]
	
	#target TE end location
	set end_tu [expr [lindex [lindex $flt_Dsc 3] 0] - $min_te]
	set end_tl [expr [lindex [lindex $flt_Dsc 3] 1] + $min_te]
	
	#scale factors for thickness distributions of DU97 thickness distribution function
	set minw_usc [expr ($max_te-$min_te)/($ref_u - $max_te)]
	set minw_lsc [expr ($max_te-$min_te)/($max_te - abs($ref_l))]
	
	return [list [lindex $flt_Dsc 0] [lindex $flt_Dsc 1] $uscale $lscale $minw_usc $minw_lsc]
}

proc flatback_magic { Fgen Method Ucrv Lcrv {FLT_PRC 10} {Wavy_Percent 40} {Wavy_depth 50} } {
	
	global FLT_PRC_UP
	
	#generating flatback using default thickness distribution
	if { [string compare $Fgen YES]==0 && [string compare $Method default]==0 } {

		set flt_dis [Flbk_NdDis $Fgen $Ucrv $Lcrv $FLT_PRC]

		set flt [flt_specs $flt_dis $FLT_PRC_UP $Ucrv $Lcrv]

		set fblend_surfaces [Flbk_SrfDefault [lindex $flt 0] [lindex $flt 1] \
				$Ucrv $Lcrv [expr -1*[lindex $flt 2]] [expr -1*[lindex $flt 3]]]
	
	#generating flatback using DU97function thickness distribution
	} elseif { [string compare $Fgen YES]==0 && [string compare $Method DU97function]==0 } {

		set flt_dis [Flbk_NdDis $Fgen $Ucrv $Lcrv $FLT_PRC]

		set flt [flt_specs $flt_dis $FLT_PRC_UP $Ucrv $Lcrv $Wavy_depth]

		set fblend_surfaces [Flbk_SrfDUTHDis [lindex $flt 0] [lindex $flt 1] $Ucrv $Lcrv]
	
	#generating waviness aft portion using default thickness distribution
	} elseif { [string compare $Fgen YES]!=0 && [string compare $Method default]==0 } {
		
		set flt_dis [Flbk_NdDis $Fgen $Ucrv $Lcrv $FLT_PRC $Wavy_Percent]

		set flt [flt_specs $flt_dis $FLT_PRC_UP $Ucrv $Lcrv $Wavy_depth]

		set fblend_surfaces [Flbk_SrfDefault [lindex $flt 0] [lindex $flt 1] \
						$Ucrv $Lcrv [lindex $flt 4] [lindex $flt 5] YES]
	
	#generating waviness aft portion using DU97function thickness distribution
	} elseif { [string compare $Fgen YES]!=0 && [string compare $Method DU97function]==0 } {

		set flt_dis [Flbk_NdDis $Fgen $Ucrv $Lcrv $FLT_PRC $Wavy_Percent]

		set flt [flt_specs $flt_dis $FLT_PRC_UP $Ucrv $Lcrv $Wavy_depth]

		set fblend_surfaces [Flbk_SrfDUTHDis [lindex $flt 0] [lindex $flt 1] \
						$Ucrv $Lcrv YES $Wavy_depth]

	#lets splin have control over thickness distribution of aft waviness portion
	} elseif { [string compare $Fgen YES]!=0 && [string compare $Method Spline]==0 } {

		set fblend_surfaces -1

	} else {

		puts "PLEASE SELECT RIGHT FLATBACK OR WAVY THICKNESS DISTRIBUTION OPTION!"
		exit -1
	}

	return $fblend_surfaces
}
