# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc tngdeg {vecx vecz} {
	global pi
	set pi [expr {acos(-1)}]
	set vecdeg [expr { (atan( $vecz/abs($vecx) ) * 180) / $pi }]
	return $vecdeg
}

proc rotvec {vec deg} {
	global pi
	set rad [expr ($deg * $pi) / 180]
	set xnew [expr [lindex $vec 0]*cos($rad) - [lindex $vec 2]*sin($rad)]
	set znew [expr [lindex $vec 0]*sin($rad) + [lindex $vec 2]*cos($rad)]
	set newvec [list $xnew [lindex $vec 1] $znew]
	return $newvec
}

proc RotTrsCrvs {crvs ypos deg} {
	pw::Entity transform [pwu::Transform rotation -anchor {0 0 0} {1 0 0} $deg] $crvs
	pw::Entity transform [pwu::Transform translation [list 0 $ypos 0]] $crvs
}

proc lrotate {xs {n 1}} {
	if {!$n} {return $xs}
	if {$n<0} {return [lrotate $xs [expr {[llength $xs]+$n}]]}

	foreach x [lassign $xs y] {
	lappend ys $x
	}
	lappend ys $y
	lrotate $ys [incr n -1]
}

proc blend_wave { mtd dpth prct wave_bcon wave_tcon airfoilfront leftcons domtrs wscales woutdegs} {
	
	global FLTB_Crvs0 FLTB_Crvs1 Xzone TE_thk wave_Crvs air_Crvs NUM_WAVE span chordln wave_sg
	
	upvar 2 symsepdd asep
	
	set slopgNum [expr int([[lindex $leftcons 0] getDimension]/3)]
	
	set afb [[[lindex $airfoilfront 0] getEdge 4] getConnector 1]
	
	set aft [[[lindex $airfoilfront 1] getEdge 2] getConnector 1]
	
	set midDimTop [[lindex $leftcons 0] getDimension]
	set midDimSp [$aft getDimension]
	
	set lft_slpin [pwu::Vector3 subtract [[lindex $leftcons 0] getXYZ -grid \
							[expr $midDimTop-$slopgNum-1]] \
								[[lindex $leftcons 0] getXYZ -arc 1] ]
		
	set lfb_slpin [pwu::Vector3 subtract [[lindex $leftcons 3] getXYZ -grid \
					$slopgNum] [[lindex $leftcons 3] getXYZ -grid 1]]
		
	set lft_slpout [pwu::Vector3 subtract [[lindex $leftcons 0] getXYZ -grid $slopgNum] \
								[[lindex $leftcons 0] getXYZ -arc 0] ]
		
	set lfb_slpout [pwu::Vector3 subtract [[lindex $leftcons 3] getXYZ -grid \
							[expr $midDimTop-$slopgNum-1]] \
								[[lindex $leftcons 3] getXYZ -arc 1] ]
	
	RotTrsCrvs $FLTB_Crvs1 $span 0
	RotTrsCrvs $FLTB_Crvs0 0 -90
	
	set nwPos [expr int($wave_sg*$NUM_WAVE)]
	set nsPos [expr int(3*$midDimTop)]

	set y_Pos [.. 0 $nwPos]
	
	foreach y $y_Pos {lappend ys_Pos [expr -1*($y/double($nwPos))*$span]}
	
	foreach crv $FLTB_Crvs1 {
		lappend BeginCrvs [$crv split [$crv getParameter -X $Xzone]]
	}

	lappend mid_tcrv [lindex [lindex $BeginCrvs 0] 1]
	lappend mid_bcrv [lindex [lindex $BeginCrvs 1] 1]
	
	set ys_Pos [lreplace $ys_Pos 0 0]
	
	foreach node [.. 2 [[lindex $leftcons 0] getDimension]] {
		lappend x_tPos [lindex [[lindex $leftcons 0] getXYZ -grid $node] 0]
		lappend x_bPos [lindex [[lindex $leftcons 3] getXYZ -grid $node] 0]
	}
	
	set xs_tPos [lreverse $x_tPos]
	set xs_bPos $x_bPos
	
	set left_Tconsp [[lindex $leftcons 0] split -I [.. 2 [[lindex $leftcons 0] getDimension]]]
	set left_Bconsp [[lindex $leftcons 3] split -I [.. 2 [[lindex $leftcons 3] getDimension]]]

	foreach i [.. 0 [llength $xs_tPos]] \
				lt [lreverse [lrange $left_Tconsp 1 end]]\
				 lb [lrange $left_Bconsp 1 end] {
		lappend sp_crvt($i) [[$lt getNode Begin] getXYZ]
		lappend sp_crvb($i) [[$lb getNode Begin] getXYZ]
	}
	
	lappend midWTCrv $aft
	lappend midWBCrv $afb
	
	if { ! [string compare $mtd spline] } {
	
		set otopslp [lindex $woutdegs 0]
		set obotslp [lindex $woutdegs 1]
		
		if {[string compare $otopslp default]!=0 && [string compare $obotslp default]!=0 } {
			
			set otopslp [expr -1 * [lindex $woutdegs 0]]
			set lft_ang [tngdeg [lindex $lft_slpout 0] [lindex $lft_slpout 2] ]
			set lfb_ang [tngdeg [lindex $lfb_slpout 0] [lindex $lfb_slpout 2] ]

			set lft_level [rotvec $lft_slpout [expr $lft_ang]]
			set lfb_level [rotvec $lfb_slpout [expr $lfb_ang]]

			set lft_slpout [rotvec $lft_level $otopslp]
			set lfb_slpout [rotvec $lfb_level $obotslp]

		} elseif {[string compare $otopslp default]!=0} {
			
			set otopslp [expr -1 * [lindex $woutdegs 0]]
			set lft_ang [tngdeg [lindex $lft_slpout 0] [lindex $lft_slpout 2] ]
			set lft_level [rotvec $lft_slpout [expr $lft_ang]]
			set lft_slpout [rotvec $lft_level $otopslp]
			
		} elseif {[string compare $obotslp default]!=0} {
			
			set lfb_ang [tngdeg [lindex $lfb_slpout 0] [lindex $lfb_slpout 2] ]
			set lfb_level [rotvec $lfb_slpout [expr $lfb_ang]]
			set lfb_slpout [rotvec $lfb_level $obotslp]
			
		}

		set lfin_vectors [list $lft_slpin $lfb_slpin]
		set lfout_vectors [list $lft_slpout $lfb_slpout]

		foreach invec $lfin_vectors outvec $lfout_vectors {
			set in_nvec [pwu::Vector3 normalize $invec]
			set out_nvec [pwu::Vector3 normalize $outvec]

			lappend lfin_svecs [pwu::Vector3 scale $invec [lindex $wscales 0]]
			lappend lfout_svecs [pwu::Vector3 scale $outvec [lindex $wscales 1]]
		}

		foreach y [lrange $ys_Pos 1 end-1] { 
			
			set seg_tspl [pw::SegmentSpline create]
			$seg_tspl addPoint [[lindex $wave_Crvs 1] getXYZ -Y $y]
			$seg_tspl addPoint [[lindex $air_Crvs 0] getXYZ -Y $y]
			$seg_tspl setSlopeOut 1 [lindex $lfout_svecs 0]
			$seg_tspl setSlopeIn 2 [lindex $lfin_svecs 0]
			$seg_tspl setSlope Free

			lappend crvT_con [pw::Curve create]
				[lindex $crvT_con end] addSegment $seg_tspl
		
			set seg_bspl [pw::SegmentSpline create]
			$seg_bspl addPoint [[lindex $air_Crvs 1] getXYZ -Y $y]
			$seg_bspl addPoint [[lindex $wave_Crvs 0] getXYZ -Y $y]
			$seg_bspl setSlopeOut 1 [lindex $lfin_svecs 1]
			$seg_bspl setSlopeIn 2 [lindex $lfout_svecs 1]
			$seg_bspl setSlope Free

			lappend crvB_con [pw::Curve create]
				[lindex $crvB_con end] addSegment $seg_bspl
		
			lappend mid_tcrv [lindex $crvT_con end]
			lappend mid_bcrv [lindex $crvB_con end]
			
			foreach xt $xs_tPos xb $xs_bPos i [.. 0 [llength $xs_tPos]] {
				lappend sp_crvt($i) [[lindex $mid_tcrv end] getXYZ -X $xt]
				lappend sp_crvb($i) [[lindex $mid_bcrv end] getXYZ -X $xb]
			}
		}

	} elseif { ! [string compare $mtd default] || ! [string compare $mtd DU97function] } {
		
		foreach y [lrange $ys_Pos 1 end-1] { 
			
			set ld [expr 100*(1-(abs([lindex [[lindex $wave_Crvs 1] getXYZ -Y $y] 2]-\
						[lindex [[lindex $wave_Crvs 0] getXYZ -Y $y] 2])/$TE_thk))]

			set flt_srf \
				[flatback_magic NO $mtd [lindex $FLTB_Crvs0 0] [lindex $FLTB_Crvs0 1] \
											777 $prct $ld]
			
			set flt_prf [surface_curve $flt_srf]
			
			set flt_wvyt [[lindex $flt_prf 0] split [[lindex $flt_prf 0] getParameter -X $Xzone]]
			set flt_wvyb [[lindex $flt_prf 1] split [[lindex $flt_prf 1] getParameter -X $Xzone]]

			RotTrsCrvs [list {*}$flt_wvyt {*}$flt_wvyb] $y 90
			
			lappend mid_tcrv [lindex $flt_wvyt 1]
			lappend mid_bcrv [lindex $flt_wvyb 1]
			
			foreach xt $xs_tPos xb $xs_bPos i [.. 0 [llength $xs_tPos]] {
				lappend sp_crvt($i) [[lindex $mid_tcrv end] getXYZ -X $xt]
				lappend sp_crvb($i) [[lindex $mid_bcrv end] getXYZ -X $xb]
			}
		}

	} else {
	
		puts "PLEASE SELECT RIGHT WAVY GENERATION METHOD!"
		exit -1
	
	}
	
	RotTrsCrvs $FLTB_Crvs0 [expr -1*$span] 90
	
	foreach crv $FLTB_Crvs0 {
		lappend EndCrvs [$crv split [$crv getParameter -X $Xzone]]
	}
	
	set right_Tcon [[[lindex $domtrs 1] getEdge 1] getConnectors]
	set right_Bcon [[[lindex $domtrs 2] getEdge 1] getConnectors]
	
	foreach i [.. 0 [llength $xs_tPos]] rt [lreverse [lrange $right_Tcon 1 end]] \
							rb [lrange $right_Bcon 1 end] {
		lappend sp_crvt($i) [$rt getXYZ -arc 0]
		lappend sp_crvb($i) [$rb getXYZ -arc 0]
		set mdCrvs [surface_curve [list $sp_crvt($i) $sp_crvb($i)]]
		lappend midWTCrv [pw::Connector createOnDatabase [lindex $mdCrvs 0]]
		lappend midWBCrv [pw::Connector createOnDatabase [lindex $mdCrvs 1]]
		[lindex $midWTCrv end] setDimension $midDimSp
		[lindex $midWBCrv end] setDimension $midDimSp
		pw::Entity project -type ClosestPoint [lindex $midWTCrv end] [lindex $mdCrvs 0]
		pw::Entity project -type ClosestPoint [lindex $midWBCrv end] [lindex $mdCrvs 1]
	}
	
	lappend midWTCrv $wave_tcon
	lappend midWBCrv $wave_bcon
	
	set midWTCrv1 [lrange $midWTCrv 0 end-1]
	set midWTCrv11 [lrange [lrotate $midWTCrv] 0 end-1]
	
	set midWBCrv1 [lrange $midWBCrv 0 end-1]
	set midWBCrv11 [lrange [lrotate $midWBCrv] 0 end-1]
	
	foreach mT $midWTCrv1 mTn $midWTCrv11 rT [lreverse $right_Tcon] lT [lreverse $left_Tconsp] \
					mB $midWBCrv1 mBn $midWBCrv11 rB $right_Bcon lB $left_Bconsp {
		lappend domw_top [pw::DomainStructured createFromConnectors [list $mT $rT $mTn $lT]]
		lappend domw_bot [pw::DomainStructured createFromConnectors [list $mB $rB $mBn $lB]]
	}
	
	set domwte_top [pw::DomainStructured join $domw_top]
	set domwte_bot [pw::DomainStructured join $domw_bot]
	
	set right_Tcon [pw::Connector join $right_Tcon]
	set right_Bcon [pw::Connector join $right_Bcon]
	set left_Tcon [pw::Connector join $left_Tconsp]
	set left_Bcon [pw::Connector join $left_Bconsp]
	
	puts "WAVY SURFACE IS BLENDED USING $mtd METHOD OVER $prct% of CHORD WITH [format %.2f $dpth]% WAVE DEPTH!"
	puts $asep
	
	return [list $domwte_top $domwte_bot]
}
