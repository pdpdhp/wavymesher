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

proc blend_wave { mtd dpth prct wave_bcon wave_tcon airfoilfront leftcons domtrs wscales woutdegs} {
	
	global FLTB_Crvs0 Xzone TE_thk
	
	upvar 2 symsepdd asep
	
	set wbcon_sp [$wave_bcon split -I [.. 2 [$wave_bcon getDimension]]]
	set wtcon_sp [$wave_tcon split -I [.. 2 [$wave_tcon getDimension]]]
	
	set slopgNum [expr int([[lindex $leftcons 0] getDimension]/3)]

	set afb_sp [[[[lindex $airfoilfront 0] getEdge 4] getConnector 1] split -I \
		[.. 2 [[[[lindex $airfoilfront 0] getEdge 4] getConnector 1] getDimension]]]
		
	set aft_sp [[[[lindex $airfoilfront 1] getEdge 2] getConnector 1] split -I \
		[.. 2 [[[[lindex $airfoilfront 1] getEdge 2] getConnector 1] getDimension]]]

	if { [string compare $mtd spline]==0 } {
	
		set lft_slpin [pwu::Vector3 subtract [[lindex $leftcons 0] getXYZ -grid \
					[expr [[lindex $leftcons 0] getDimension]-$slopgNum-1]] \
									[[lindex $leftcons 0] getXYZ -arc 1] ]
		
		set lfb_slpin [pwu::Vector3 subtract [[lindex $leftcons 3] getXYZ -grid \
					$slopgNum] [[lindex $leftcons 3] getXYZ -grid 1]]
		
		set lft_slpout [pwu::Vector3 subtract [[lindex $leftcons 0] getXYZ -grid $slopgNum] \
									[[lindex $leftcons 0] getXYZ -arc 0] ]
		
		set lfb_slpout [pwu::Vector3 subtract [[lindex $leftcons 3] getXYZ -grid \
						[expr [[lindex $leftcons 3] getDimension]-$slopgNum-1]] \
									[[lindex $leftcons 3] getXYZ -arc 1] ]
		
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

		foreach wbt [lrange $wbcon_sp 0 end-1] wtc [lrange $wtcon_sp 0 end-1] \
						aft [lrange $aft_sp 0 end-1] afb [lrange $afb_sp 0 end-1] {
			
			set seg_spl [pw::SegmentSpline create]
			$seg_spl addPoint [$wtc getPosition -arc 1]
			$seg_spl addPoint [$aft getPosition -arc 1]
			$seg_spl setSlope Free
			$seg_spl setSlopeOut 1 [lindex $lfout_svecs 0]
			$seg_spl setSlopeIn 2 [lindex $lfin_svecs 0]
			set seg_crvT [pw::Curve create]
			$seg_crvT addSegment $seg_spl
			
			
			set seg_spl [pw::SegmentSpline create]
			$seg_spl addPoint [$afb getPosition -arc 1]
			$seg_spl addPoint [$wbt getPosition -arc 1]
			$seg_spl setSlope Free
			$seg_spl setSlopeOut 1 [lindex $lfin_svecs 1]
			$seg_spl setSlopeIn 2 [lindex $lfout_svecs 1]
			set seg_crvB [pw::Curve create]
			$seg_crvB addSegment $seg_spl
			
			lappend crvT_con [pw::Connector createOnDatabase $seg_crvT]
			lappend crvB_con [pw::Connector createOnDatabase $seg_crvB]
			
			[lindex $crvT_con end] setDimension [[lindex $leftcons 0] getDimension]
			[lindex $crvT_con end] setDistribution 1 \
						[[[lindex $leftcons 0] getDistribution 1] copy]
			
			[lindex $crvB_con end] setDimension [[lindex $leftcons 3] getDimension]
			[lindex $crvB_con end] setDistribution 1 \
						[[[lindex $leftcons 3] getDistribution 1] copy]
			
		}
	
	} elseif { [string compare $mtd default] || [string compare $mtd DU97function] } {
		
		foreach node [.. 2 [[lindex $leftcons 0] getDimension]] {
			lappend wvy_Xpos [lindex [ [lindex $leftcons 0] getXYZ -grid $node] 0]
		}

		RotTrsCrvs $FLTB_Crvs0 0 -90
		
		foreach wbt [lrange $wbcon_sp 0 end-1] wtc [lrange $wtcon_sp 0 end-1] \
					aft [lrange $aft_sp 0 end-1] afb [lrange $afb_sp 0 end-1] {
			
			set dpth_local [expr 100*(1-(abs([lindex [$wtc getXYZ -arc 1] 2] - \
							[lindex [$wbt getXYZ -arc 1] 2])/$TE_thk))]

			set flt_wvy_srf \
			[flatback_magic NO $mtd [lindex $FLTB_Crvs0 0] [lindex $FLTB_Crvs0 1] \
										777 $prct $dpth_local]

			set flt_wvy_prf [surface_curve $flt_wvy_srf]

			set flt_wvyt \
			[[lindex $flt_wvy_prf 0] split [[lindex $flt_wvy_prf 0] getParameter -X $Xzone]]

			set flt_wvyb \
			[[lindex $flt_wvy_prf 1] split [[lindex $flt_wvy_prf 1] getParameter -X $Xzone]]

			set yCord [lindex [$aft getXYZ -arc 1] 1]

			RotTrsCrvs [list {*}[lindex $flt_wvyt 1] {*}[lindex $flt_wvyb 1]] $yCord 90
			
			set midtop_pts []
			set midbot_pts []
			
			foreach xpos $wvy_Xpos {
				lappend midtop_pts [[lindex $flt_wvyt 1] getXYZ -X $xpos]
				lappend midbot_pts [[lindex $flt_wvyb 1] getXYZ -X $xpos]
			}
			
			lappend crvT_con [pw::Connector createFromPoints [list [$aft getXYZ -arc 1]\
							{*}[lreverse $midtop_pts] [$wtc getXYZ -arc 1]] ]
			
			lappend crvB_con [pw::Connector createFromPoints [list [$afb getXYZ -arc 1]\
							{*}[lreverse $midbot_pts] [$wbt getXYZ -arc 1]] ]

			pw::Entity project -type ClosestPoint \
							[lindex $crvT_con end] [lindex $flt_wvyt 1]
			pw::Entity project -type ClosestPoint \
							[lindex $crvB_con end] [lindex $flt_wvyb 1]
		}

	} else {
	
		puts "PLEASE SELECT RIGHT WAVY GENERATION METHOD!"
		exit -1
	
	}
	
	set midtop_cons [list [lindex $leftcons 0] {*}$crvT_con \
				[[[lindex $domtrs 1] getEdge 1] getConnector 1]]
	set midbot_cons [list [lindex $leftcons 3] {*}$crvB_con \
				[[[lindex $domtrs 2] getEdge 1] getConnector 1]]

	for {set j 0} {$j<[expr [llength $midtop_cons]-1]} {incr j} {
	lappend dmw_top [pw::DomainStructured createFromConnectors \
		 [list [lindex $midtop_cons $j] [lindex $aft_sp $j] [lindex $wtcon_sp $j] \
				   [lindex $midtop_cons [expr $j+1]] ]] 

	lappend dmw_bot [pw::DomainStructured createFromConnectors \
		 [list [lindex $midbot_cons $j] [lindex $afb_sp $j] [lindex $wbcon_sp $j] \
					   [lindex $midbot_cons [expr $j+1]] ]] 
	}

	set domwte_top [pw::DomainStructured join $dmw_top]
	set domwte_bot [pw::DomainStructured join $dmw_bot]

	set wave_tcon [pw::Connector join $wtcon_sp]
	set wave_bcon [pw::Connector join $wbcon_sp]
	set airfoil_ft [pw::Connector join $aft_sp]
	set airfoil_fb [pw::Connector join $afb_sp]
	
	puts "WAVY SURFACE IS BLENDED USING $mtd METHOD OVER $prct% of CHORD WITH $dpth% WAVE DEPTH!"
	puts $asep
	
	return [list $domwte_top $domwte_bot]
}
