package require PWI_Glyph 3.18.3

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


pw::Application reset
pw::Application clearModified

set scriptDir [file dirname [info script]]

set airfoilp "s830.nmb"

set fpmod [open $scriptDir/$airfoilp r]

while {[gets $fpmod line] >= 0} {
	puts $line
	lappend nxnodes [expr [lindex [split $line ] 0]]
	lappend nynodes [expr [lindex [split $line ] 1]]
}
close $fpmod

#surface_curve [uplow_surfaces $nxnodes $nynodes]

set fmod [open "s830a.txt" w]

for {set j 0} {$j<90} {incr j} {
	puts $fmod "[format "%.13f, %.13f" [lindex [lreverse $nxnodes] $j] [lindex [lreverse $nynodes] $j]]"

}

for {set j 0} {$j<100} {incr j} {
	puts $fmod "[format "%.13f, %.13f" [lindex $nxnodes $j] [lindex $nynodes $j]]"

}



close $fmod
