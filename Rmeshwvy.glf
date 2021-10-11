# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc WaveRemesh {method wdpth wprc wscales woutdegs} {

	global w1_x w1_y w1_z w2_x w2_y w2_z blkexm span
	global N_third rightcon_top rightcon_bot airfoilfront left_hte \
					right_hte leftcons rmesh_trsdoms middoms blk
	global blktop blkbot blkte wMinVolv
	
	upvar 1 fexmod outfile
	
	set waveVolexam [pw::Examine create BlockVolume]
	
	set min_w1_z [tcl::mathfunc::min {*}$w2_z]
	set max_w1_z [tcl::mathfunc::max {*}$w2_z]
	
	set wv_dpth_up [expr ($min_w1_z/$max_w1_z)*100]
	
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
	
	set blended [blend_wave $method $wv_dpth_up $wprc \
			$wave_bcon $wave_tcon $airfoilfront $leftcons $domtrs $wscales $woutdegs]
	
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