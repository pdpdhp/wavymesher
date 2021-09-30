# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc range {from to} {
    if {$to>$from} {concat [range $from [incr to -1]] $to}
}

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

proc blend_wave {wave_bcon wave_tcon airfoilfront leftcons domtrs wscales woutdegs} {
	
	set wbcon_sp [$wave_bcon split -I [range 2 [$wave_bcon getDimension]]]
	set wtcon_sp [$wave_tcon split -I [range 2 [$wave_tcon getDimension]]]
	
	set slopgNum [expr int([[lindex $leftcons 0] getDimension]/3)]

	set afb_sp [[[[lindex $airfoilfront 0] getEdge 4] getConnector 1] split -I \
				[range 2 [[[[lindex $airfoilfront 0] getEdge 4] getConnector 1] getDimension]]]
	
	set aft_sp [[[[lindex $airfoilfront 1] getEdge 2] getConnector 1] split -I \
				[range 2 [[[[lindex $airfoilfront 1] getEdge 2] getConnector 1] getDimension]]]
	
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
	
	set otopslp [expr -1 * [lindex $woutdegs 0]]
	set obotslp [lindex $woutdegs 1]
	
	if {[string compare $otopslp Default]!=0 && [string compare $obotslp Default]!=0 } {

		set lft_ang [tngdeg [lindex $lft_slpout 0] [lindex $lft_slpout 2] ]
		set lfb_ang [tngdeg [lindex $lfb_slpout 0] [lindex $lfb_slpout 2] ]

		set lft_level [rotvec $lft_slpout [expr $lft_ang]]
		set lfb_level [rotvec $lfb_slpout [expr $lfb_ang]]

		set lft_slpout [rotvec $lft_level $otopslp]
		set lfb_slpout [rotvec $lfb_level $obotslp]

	} elseif {[string compare $otopslp Default]!=0} {
		
		set lft_ang [tngdeg [lindex $lft_slpout 0] [lindex $lft_slpout 2] ]
		set lft_level [rotvec $lft_slpout [expr $lft_ang]]
		set lft_slpout [rotvec $lft_level $otopslp]
		
	} elseif {[string compare $obotslp Default]!=0} {
		
		set lfb_ang [tngdeg [lindex $lfb_slpout 0] [lindex $lfb_slpout 2] ]
		set lfb_level [rotvec $lfb_slpout [expr $lfb_ang]]
		set lfb_slpout [rotvec $lfb_level $obotslp]
	} else {
		puts "PLEASE INDICATE CORRECT VALUE FOR WAVE TANGENT ANGLE IN YOUR INPUT FILE."
		exit -1
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
		[lindex $crvT_con end] setDistribution 1 [[[lindex $leftcons 0] getDistribution 1] copy]
		
		[lindex $crvB_con end] setDimension [[lindex $leftcons 3] getDimension]
		[lindex $crvB_con end] setDistribution 1 [[[lindex $leftcons 3] getDistribution 1] copy]
		
	}
	
	set midtop_cons [list [lindex $leftcons 0] {*}$crvT_con [[[lindex $domtrs 1] getEdge 1] getConnector 1]]
	set midbot_cons [list [lindex $leftcons 3] {*}$crvB_con [[[lindex $domtrs 2] getEdge 1] getConnector 1]]
	
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
	
	return [list $domwte_top $domwte_bot]
}


proc WaveRemesh {wscales woutdegs} {

	global w1_x w1_y w1_z w2_x w2_y w2_z blkexm span
	global N_third rightcon_top rightcon_bot airfoilfront left_hte \
					right_hte leftcons rmesh_trsdoms middoms blk
	global blktop blkbot blkte wMinVolv
	
	upvar 1 fexmod outfile
	
	set waveVolexam [pw::Examine create BlockVolume]
	
	foreach x $w1_x y $w1_y z $w1_z {
		lappend w1_pts [list $x $y $z]
	}
	
	foreach x $w2_x y $w2_y z $w2_z {
		lappend w2_pts [list $x $y $z]
	}
	
	set wave_bcon [pw::Connector createFromPoints $w1_pts]
	set wave_tcon [pw::Connector createFromPoints $w2_pts]
	
	set right_hteseg [pw::SegmentSpline create]
	$right_hteseg addPoint [[$wave_bcon getNode End] getXYZ]
	$right_hteseg addPoint [[$wave_tcon getNode End] getXYZ]
	set right_hte [pw::Connector create]
	$right_hte addSegment $right_hteseg
	
	$right_hte setDimension [$left_hte getDimension]
	$right_hte setDistribution 1 [[$left_hte getDistribution 1] copy]
	
	foreach dom $rmesh_trsdoms {
		lappend domtrs [$dom createPeriodic -translate [list 0 [expr -1*$span] 0]]
	}
	
	set blended [blend_wave $wave_bcon $wave_tcon $airfoilfront $leftcons $domtrs $wscales $woutdegs]
	
	set domwte_top [lindex $blended 0]
	set domwte_bot [lindex $blended 1]
	
	#domte
	set domwte_te [pw::DomainStructured createFromConnectors \
			[list $left_hte $wave_tcon $wave_bcon $right_hte]]
	
	#dommid1
	set domwte_mid1 [pw::DomainStructured createFromConnectors \
		[list $wave_tcon [[[lindex $domtrs 0] getEdge 2] getConnector 1] \
					[[[lindex $rmesh_trsdoms 0] getEdge 2] getConnector 1] \
							[[[lindex $middoms 1] getEdge 4] getConnector 1]]]
	
	#dommid2
	set domwte_mid2 [pw::DomainStructured createFromConnectors \
		[list $wave_bcon [[[lindex $domtrs 2] getEdge 2] getConnector 1] \
					[[[lindex $rmesh_trsdoms 2] getEdge 2] getConnector 1] \
							[[[lindex $middoms 2] getEdge 4] getConnector 1]]]
	
	#blk 1
	set blktop [pw::BlockStructured create]
	set pf11 [pw::FaceStructured create]
	$pf11 addDomain $domwte_top
	set pf21 [pw::FaceStructured create]
	$pf21 addDomain [lindex $domtrs 1]
	set pf31 [pw::FaceStructured create]
	$pf31 addDomain $domwte_mid1
	set pf41 [pw::FaceStructured create]
	$pf41 addDomain [lindex $rmesh_trsdoms 1]
	set pf51 [pw::FaceStructured create]
	$pf51 addDomain [lindex $middoms 0]
	set pf61 [pw::FaceStructured create]
	$pf61 addDomain [[[lindex $blk 0] getFace 4] getDomain 1]
	$blktop addFace $pf11
	$blktop addFace $pf21
	$blktop addFace $pf31
	$blktop addFace $pf41
	$blktop addFace $pf51
	$blktop addFace $pf61
	
	$waveVolexam addEntity $blktop
	
	#blk 2
	set blkbot [pw::BlockStructured create]
	set pf12 [pw::FaceStructured create]
	$pf12 addDomain $domwte_bot
	set pf22 [pw::FaceStructured create]
	$pf22 addDomain [lindex $domtrs 2]
	set pf32 [pw::FaceStructured create]
	$pf32 addDomain $domwte_mid2
	set pf42 [pw::FaceStructured create]
	$pf42 addDomain [lindex $rmesh_trsdoms 2]
	set pf52 [pw::FaceStructured create]
	$pf52 addDomain [lindex $middoms 2]
	set pf62 [pw::FaceStructured create]
	$pf62 addDomain [[[lindex $blk 0] getFace 2] getDomain 2]
	$blkbot addFace $pf12
	$blkbot addFace $pf22
	$blkbot addFace $pf32
	$blkbot addFace $pf42
	$blkbot addFace $pf52
	$blkbot addFace $pf62
	
	$waveVolexam addEntity $blkbot

	#blk 2
	set blkte [pw::BlockStructured create]
	set pf13 [pw::FaceStructured create]
	$pf13 addDomain $domwte_te
	set pf23 [pw::FaceStructured create]
	$pf23 addDomain [lindex $domtrs 0]
	set pf33 [pw::FaceStructured create]
	$pf33 addDomain $domwte_mid2
	set pf43 [pw::FaceStructured create]
	$pf43 addDomain [lindex $rmesh_trsdoms 0]
	set pf53 [pw::FaceStructured create]
	$pf53 addDomain [lindex $middoms 1]
	set pf63 [pw::FaceStructured create]
	$pf63 addDomain $domwte_mid1
	$blkte addFace $pf13
	$blkte addFace $pf23
	$blkte addFace $pf33
	$blkte addFace $pf43
	$blkte addFace $pf53
	$blkte addFace $pf63
	
	$waveVolexam addEntity $blkte
	
	$waveVolexam examine
	set wMinVolv [$waveVolexam getMinimum]
	
	puts $outfile "min wave volume: [format "%*e" 5 $wMinVolv]"
}
