# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc Topo_Prep_Mesh {wavyp} {
	
	global ypg dsg grg chord_sg ter_sg ler_sg tpts_sg exp_sg imp_sg vol_sg TOTAL_HEIGHT res_lev
	global model_2D model_Q2D span fixed_snodes span_dimension
	global N_third rightcon_top rightcon_bot airfoilfront left_hte right_hte leftcons rmesh_trsdoms middoms
	global blk blkexam cae_solver w1_y GRD_TYP chordln Xzone extr_watchout
	
	global HYB_HEIGHT maxstepfac air_Crvs
	global domBCs blkBCs 
	
	# collecting boundaries as it builds
	array set domBCs []
	array set blkBCs []
	
	set Xzone [expr $chordln - ($wavyp*$chordln)/100.]
	
	set DBall [pw::Database getAll]
	
	pw::Entity transform [pwu::Transform rotation -anchor {0 0 0} {1 0 0} 90] $DBall
	
	set DBmod [pw::Database getAll -type pw::Model]
	
	set Consdb [pw::Connector createOnDatabase -parametricConnectors Aligned -merge 0 [list $DBmod]]
	
	set Refcon_sp [lrange $Consdb 3 4]
	
	foreach con $Refcon_sp {
		$con setDimensionFromSpacing $chord_sg
	}
	
	[[lindex $Refcon_sp 0] getDistribution 1] setBeginSpacing $ter_sg
	[[lindex $Refcon_sp 0] getDistribution 1] setEndSpacing $ler_sg
	
	[[lindex $Refcon_sp 1] getDistribution 1] setBeginSpacing $ler_sg
	[[lindex $Refcon_sp 1] getDistribution 1] setEndSpacing $ter_sg

	foreach con $Refcon_sp {
		lappend Refcon_spsp [$con split [$con getParameter -X $Xzone]]
	}
	
	foreach con $Refcon_spsp {
		lappend leftcons [lindex $con 0]
		lappend leftcons [lindex $con 1]
	}
	
	[lindex $leftcons 0] setDimension [[lindex $leftcons 3] getDimension ]
	
	set left_hte [lindex $Consdb end]
	set right_hte [lindex $Consdb end-1]
	$right_hte delete
	
	# removing unnecessary connectors
	foreach con [list {*}[lrange $Consdb 0 2] {*}[lrange $Consdb end-3 end-2]] {
		$con delete
	} 
	
	$left_hte setDimension $tpts_sg
	
	lappend leftcons $left_hte
	
	set HYB_HEIGHT $TOTAL_HEIGHT
	
	if { ! [string compare $GRD_TYP HYB] } {
	
		set TOTAL_HEIGHT [expr $chordln*0.08]
		
		if { $TOTAL_HEIGHT < [expr 0.65*$extr_watchout] } {
			set TOTAL_HEIGHT [expr 0.65*$extr_watchout]
		}
		
	}
	
	set maxstepfac [list 10000 7000 5000 3000 2000]
	
	set leftedge [pw::Edge createFromConnectors $leftcons]
	set dom_left [pw::DomainStructured create]
	$dom_left addEdge $leftedge
	set leftxtr [pw::Application begin ExtrusionSolver [list $dom_left]]
	$leftxtr setKeepFailingStep true
	$dom_left setExtrusionSolverAttribute NormalMarchingMode Plane
	$dom_left setExtrusionSolverAttribute NormalMarchingVector {-0 1 -0}
	$dom_left setExtrusionSolverAttribute NormalInitialStepSize $dsg
	$dom_left setExtrusionSolverAttribute SpacingGrowthFactor $grg
	$dom_left setExtrusionSolverAttribute NormalMaximumStepSize \
		[expr [[lindex $leftcons 1] getAverageSpacing]*[lindex $maxstepfac $res_lev]]
	$dom_left setExtrusionSolverAttribute StopAtHeight $TOTAL_HEIGHT
	$dom_left setExtrusionSolverAttribute NormalExplicitSmoothing $exp_sg
	$dom_left setExtrusionSolverAttribute NormalImplicitSmoothing $imp_sg
	$dom_left setExtrusionSolverAttribute NormalKinseyBarthSmoothing 0.0
	$dom_left setExtrusionSolverAttribute NormalVolumeSmoothing $vol_sg
	$leftxtr run 900
	
	#checking stop condition
	set stopCond [$leftxtr getStopConditionData [lindex [$leftxtr getRunResult] 1]]

	if { [string compare [lindex $stopCond 2] Height] } {
		puts "NORMAL EXTRUSION FAILED! PLEASE CHECK YOUR INPUT FILE'S GRID SPECIFICATIONS!"
		$leftxtr end
		exit -1
	} else {
		$leftxtr end
	}
	
	set dom_left_spa [$dom_left split -I [list [expr $tpts_sg + \
		[[lindex $leftcons 0] getDimension] - 1] [expr $tpts_sg + [[lindex $leftcons 0] getDimension] \
			+ [[lindex $leftcons 1] getDimension] + [[lindex $leftcons 2] getDimension] - 3]]]
	
	set dom_left_spb [[lindex $dom_left_spa 0] split -I [list $tpts_sg]]
	
	set ref_con [[[lindex $dom_left_spb 0] getEdge 2] getConnector 1]
	
	set ref_con_length [$ref_con getLength -arc 1]
	set ref_con_dim [$ref_con getDimension]
	
	if { ! [string compare $GRD_TYP STR] } {
	
		set ref_consp [$ref_con split -I [list \
			[lindex [$ref_con closestCoordinate [$ref_con getPosition -arc 0.006]] 0]]]
	
	} elseif { ! [string compare $GRD_TYP HYB] } {
	
		set ref_consp [$ref_con split -I [list [lindex [$ref_con closestCoordinate \
					[$ref_con getPosition -grid  [expr int($ref_con_dim-2)]]] 0]]]
	
	} else {
	
		puts "PLEASE SELECT A VALID OPTION FOR GRID TYPE IN INPUT FILE."
		exit -1
	}
	
	foreach spdom $dom_left_spb {
		lappend dom_left_spc [$spdom split -J [[lindex $ref_consp 0] getDimension]]
	}
	
	lappend dom_left_spd [[lindex $dom_left_spa 2] split -J [[lindex $ref_consp 0] getDimension]]
	
	set spanSpc [pw::Examine create ConnectorEdgeLength]
	$spanSpc addEntity [lindex $leftcons 1]
	$spanSpc addEntity [lindex $leftcons 2]
	$spanSpc examine
	set spanSpcv [$spanSpc getMaximum]
	set trnstp [expr [llength $w1_y]-1]
	
	lappend alldoms [lindex $dom_left_spa 1]
	lappend alldoms [lindex [lindex $dom_left_spd 0] 1]
	lappend alldoms [lindex [lindex $dom_left_spc 0] 1]
	lappend alldoms [lindex [lindex $dom_left_spc 1] 1]

	set fstr [pw::FaceStructured createFromDomains $alldoms]
		
		
	for {set i 0} {$i<[llength $fstr]} {incr i} {
		lappend blk [pw::BlockStructured create]
		[lindex $blk $i] addFace [lindex $fstr $i]
	}

	set domtrn [pw::Application begin ExtrusionSolver $blk]
	
	foreach bl $blk {
		$bl setExtrusionSolverAttribute Mode Translate
		$bl setExtrusionSolverAttribute TranslateDirection {0 -1 0}
		$bl setExtrusionSolverAttribute TranslateDistance $span
	}
	
	
	if {[string compare $fixed_snodes NO]==0} {
		$domtrn run $trnstp
		$domtrn end
	} else {
		$domtrn run [expr $span_dimension-1]
		#checking stop condition
		if {[string compare [lindex [$domtrn getRunResult] 0] Completed]!=0} {
			puts "TRANSLATE EXTRUSION FAILED! PLEASE CHECK YOUR INPUT FILE!"
			$domtrn end
			exit -1
		}
		$domtrn end
	}
	
	lappend domBCs(1) [lindex $alldoms 0]
	lappend blkBCs(1) [lindex $blk 0]
	
	#collecting BCs | left
	foreach dom [lrange $alldoms 1 end] {
		lappend domBCs(1) $dom
		lappend blkBCs(1) [lindex $blk 1]
	}
	
	#collecting BCs | right and farfield
	foreach bk $blk {
		foreach dom [[$bk getFace 6] getDomains] {
			lappend domBCs(2) $dom
			lappend blkBCs(2) $bk
		}
		
		foreach dom [[$bk getFace 5] getDomains] {
			lappend domBCs(3) $dom
			lappend blkBCs(3) $bk
		}
	}
	
	set dq_database [pw::Layer getLayerEntities -type pw::Quilt 0]
	
	set airfoilfront [[[lindex $blk 0] getFace 3] getDomains]
	
	pw::Entity project -type ClosestPoint $airfoilfront $dq_database
	
	#collecting BCs | surface
	foreach dom $airfoilfront {
		lappend domBCs(0) $dom
		lappend blkBCs(0) [lindex $blk 0]
	}

	
	foreach bl $blk {
		$blkexam addEntity $bl
		lappend hyb_doms [[$bl getFace 1] getDomains]
	}

	foreach doms $hyb_doms {
		foreach dom $doms {
			lappend hyb_cons [[$dom getEdge 3] getConnector 1]
		}
	}
	
	set hyb_path [[[lindex [[[lindex $blk 1] getFace 5] getDomains] end] getEdge 2] getConnector 1]
	set hyb_spcon [[[lindex [[[lindex $blk 1] getFace 1] getDomains] end] getEdge 4] getConnector 1]
	
	set airTop_con [[[lindex $airfoilfront 1] getEdge 2] getConnector 1]
	set airBot_con [[[lindex $airfoilfront 0] getEdge 4] getConnector 1]

	set N_third [$airBot_con getDimension]
	
	set up_Seg [pw::SegmentSpline create]
		$up_Seg addPoint [[[lindex $leftcons 0] getNode End] getXYZ]
		$up_Seg addPoint [[$airTop_con getNode End] getXYZ]
	set up_Crv [pw::Curve create]
		$up_Crv addSegment $up_Seg
	
	set low_Seg [pw::SegmentSpline create]
		$low_Seg addPoint [[[lindex $leftcons 3] getNode Begin] getXYZ]
		$low_Seg addPoint [[$airBot_con getNode End] getXYZ]
	set low_Crv [pw::Curve create]
		$low_Crv addSegment $low_Seg
	
	set air_Crvs [list $up_Crv $low_Crv]
	
	
	set rmesh_trsdoms [list [lindex [lindex $dom_left_spc 0] 0] \
						[lindex [lindex $dom_left_spc 1] 0] \
							[lindex [lindex $dom_left_spd 0] 0]]

	set middoms [[[lindex $blk 1] getFace 3] getDomains]
	
	if { ! [string compare $GRD_TYP HYB] } { HYBRID_Mesh $hyb_cons $hyb_path $hyb_spcon $N_third}
	
}
