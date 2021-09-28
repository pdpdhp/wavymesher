# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc Topo_Prep_Mesh {wavyp} {
	
	global ypg dsg grg chord_sg ter_sg ler_sg tpts_sg exp_sg imp_sg vol_sg Total_Height res_lev
	global model_2D model_Q2D span fixed_snodes span_dimension
	global N_third rightcon_top rightcon_bot airfoilfront left_hte right_hte leftcons rmesh_trsdoms middoms
	global blk blkexam
	
	upvar 1 GRD_TYP grid_type
	upvar 1 cae_solver cae_fmt
	upvar 1 w1_y wavepts
	
	set Xzone [expr 1.0 - $wavyp/100.]
	
	set DBall [pw::Database getAll]
	
	pw::Entity transform [pwu::Transform rotation -anchor {0 0 0} {1 0 0} 90] $DBall
	
	set DBmod [pw::Database getAll -type pw::Model]
	
	set Consdb [pw::Connector createOnDatabase -parametricConnectors Aligned -merge 0 [list $DBmod]]
	
	set Refcon_sp [[lindex $Consdb end] split [[lindex $Consdb end] getParameter -Z 0]]
	
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
	
	set left_hte [lindex $Consdb 2]
	set right_hte [lindex $Consdb 0]
	$right_hte delete
	
	[lindex $Consdb 1] delete
	set usless2 [lrange $Consdb 3 end-1]
	
	foreach con2 $usless2 {
		$con2 delete
	} 
	
	$left_hte setDimension $tpts_sg
	
	lappend leftcons $left_hte
	
	set maxstepfac [list 10000 7000 5000 3000 2000]
	
	set leftedge [pw::Edge createFromConnectors $leftcons]
	set dom_left [pw::DomainStructured create]
	$dom_left addEdge $leftedge
	set leftxtr [pw::Application begin ExtrusionSolver [list $dom_left]]
	$dom_left setExtrusionSolverAttribute NormalMarchingMode Plane
	$dom_left setExtrusionSolverAttribute NormalMarchingVector {-0 1 -0}
	$dom_left setExtrusionSolverAttribute NormalInitialStepSize $dsg
	$dom_left setExtrusionSolverAttribute SpacingGrowthFactor $grg
	$dom_left setExtrusionSolverAttribute NormalMaximumStepSize \
		[expr [[lindex $leftcons 1] getAverageSpacing]*[lindex $maxstepfac $res_lev]]
	$dom_left setExtrusionSolverAttribute StopAtHeight $Total_Height
	$dom_left setExtrusionSolverAttribute NormalExplicitSmoothing $exp_sg
	$dom_left setExtrusionSolverAttribute NormalImplicitSmoothing $imp_sg
	$dom_left setExtrusionSolverAttribute NormalKinseyBarthSmoothing 0.0
	$dom_left setExtrusionSolverAttribute NormalVolumeSmoothing $vol_sg
	$leftxtr run 900
	$leftxtr end
	
	set dom_left_spa [$dom_left split -I [list [expr $tpts_sg + \
		[[lindex $leftcons 0] getDimension] - 1] [expr $tpts_sg + [[lindex $leftcons 0] getDimension] \
			+ [[lindex $leftcons 1] getDimension] + [[lindex $leftcons 2] getDimension] - 3]]]
	
	set dom_left_spb [[lindex $dom_left_spa 0] split -I [list $tpts_sg]]
	
	set ref_con [[[lindex $dom_left_spb 0] getEdge 2] getConnector 1]
	
	set ref_consp [$ref_con split -I [list \
			[lindex [$ref_con closestCoordinate [$ref_con getPosition -X 4]] 0]]]
	
	foreach spdom $dom_left_spb {
		lappend dom_left_spc [$spdom split -J [[lindex $ref_consp 0] getDimension]]
	}
	
	lappend dom_left_spd [[lindex $dom_left_spa 2] split -J [[lindex $ref_consp 0] getDimension]]
	
	set spanSpc [pw::Examine create ConnectorEdgeLength]
	$spanSpc addEntity [lindex $leftcons 1]
	$spanSpc addEntity [lindex $leftcons 2]
	$spanSpc examine
	set spanSpcv [$spanSpc getMaximum]
	set trnstp [expr [llength $wavepts]-1]
	
	pw::Application setCAESolver $cae_fmt 3
	
	lappend alldoms [lindex $dom_left_spa 1]
	lappend alldoms [lindex [lindex $dom_left_spd 0] 1]
	lappend alldoms [lindex [lindex $dom_left_spc 0] 1]
	lappend alldoms [lindex [lindex $dom_left_spc 1] 1]

	
	if {[string compare $grid_type STR]==0} {
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
		
	}
	
	if {[string compare $fixed_snodes NO]==0} {
		$domtrn run $trnstp
		$domtrn end
	} else {
		$domtrn run [expr $span_dimension-1]
		if {[string compare [lindex [$domtrn getRunResult] 0] Completed]!=0} {
			puts "TRANSLATE EXTRUSION FAILED! PLEASE CHECK YOUR INPUT FILE!"
			$domtrn end
			exit -1
		}
		$domtrn end
	}
	
	
	set dq_database [pw::Layer getLayerEntities -type pw::Quilt 0]
	
	set airfoilfront [[[lindex $blk 0] getFace 3] getDomains]
	
	pw::Entity project -type ClosestPoint $airfoilfront $dq_database
	
	foreach bl $blk {
		$blkexam addEntity $bl
	}

	set N_third [[[[lindex $airfoilfront 0] getEdge 4] getConnector 1] getDimension]
	
	set rmesh_trsdoms [list [lindex [lindex $dom_left_spc 0] 0] \
						[lindex [lindex $dom_left_spc 1] 0] \
							[lindex [lindex $dom_left_spd 0] 0]]
	
	set middoms [[[lindex $blk 1] getFace 3] getDomains]
}
