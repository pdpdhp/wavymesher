# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc Source_Unstr { } {
	
	upvar 1 spacecon wu

	#size field defination
	set base_rad [list 0.4 0.8 1.6 3.2 6.4]
	set top_rad [list 0.25 0.5 1.0 2.0 4.0]
	set cyn_len [list 1.5 4.5 13.5 40.5 121.5]
	
	set levspc [expr [$wu getAverageSpacing]*0.75]
	lappend cyndecayfactor 0.99
	
	for {set i 0} {$i<6} {incr i} {
		lappend cylinder_spcfactor [expr $levspc*(($i)**2.5+1)]
		lappend cyndecayfactor [expr [lindex $cyndecayfactor $i]-0.1]
	}
	
	
	for {set i 0} {$i<5} {incr i} {
		lappend cynsourcesh [pw::SourceShape create]
		[lindex $cynsourcesh $i] cylinder -radius \
			[lindex $base_rad $i] -topRadius [lindex $top_rad $i] -length [lindex $cyn_len $i]

		[lindex $cynsourcesh $i] setTransform \
				[list 0 0 1 0 0 1 0 0 -1 0 0 0 0.083520643853 -0.0109231602598 0 1]
		[lindex $cynsourcesh $i] setPivot Top
		[lindex $cynsourcesh $i] setSectionMinimum 0
		[lindex $cynsourcesh $i] setSectionMaximum 360
		[lindex $cynsourcesh $i] setSidesType Plane
		[lindex $cynsourcesh $i] setBaseType Sphere
		[lindex $cynsourcesh $i] setTopType Sphere
		[lindex $cynsourcesh $i] setEnclosingEntities {}
		[lindex $cynsourcesh $i] setSpecificationType AxisToPerimeter
		[lindex $cynsourcesh $i] setBeginSpacing [lindex $cylinder_spcfactor $i]
		[lindex $cynsourcesh $i] setBeginDecay [lindex $cyndecayfactor $i]
		[lindex $cynsourcesh $i] setEndSpacing [lindex $cylinder_spcfactor [expr $i+1]]
		[lindex $cynsourcesh $i] setEndDecay [lindex $cyndecayfactor [expr $i+1]]
	}

}

proc HYBRID_Mesh { cons path spacecon steps} {
	
	global HYB_HEIGHT grg leftcons res_lev maxstepfac exp_sg imp_sg vol_sg hyb_blk blkexam
	global domBCs blkBCs
	
	set avg_spc [$spacecon getAverageSpacing]
	
	set hleftedge [pw::Edge createFromConnectors $cons]
	set dom_hleft [pw::DomainStructured create]
	$dom_hleft addEdge $hleftedge
	set leftxtr [pw::Application begin ExtrusionSolver [list $dom_hleft]]
	$leftxtr setKeepFailingStep true
	$dom_hleft setExtrusionSolverAttribute NormalMarchingMode Plane
	$dom_hleft setExtrusionSolverAttribute NormalMarchingVector {0 -1 0}
	$dom_hleft setExtrusionSolverAttribute NormalInitialStepSize $avg_spc
	$dom_hleft setExtrusionSolverAttribute SpacingGrowthFactor $grg
	$dom_hleft setExtrusionSolverAttribute NormalMaximumStepSize \
		[expr [[lindex $leftcons 1] getAverageSpacing]*[lindex $maxstepfac $res_lev]]
	$dom_hleft setExtrusionSolverAttribute StopAtHeight $HYB_HEIGHT
	$dom_hleft setExtrusionSolverAttribute NormalExplicitSmoothing $exp_sg
	$dom_hleft setExtrusionSolverAttribute NormalImplicitSmoothing $imp_sg
	$dom_hleft setExtrusionSolverAttribute NormalKinseyBarthSmoothing 0.0
	$dom_hleft setExtrusionSolverAttribute NormalVolumeSmoothing $vol_sg
	$leftxtr run 900
	
	set stopCond [$leftxtr getStopConditionData [lindex [$leftxtr getRunResult] 1]]
	
	if { [string compare [lindex $stopCond 2] Height] } {
		puts "NORMAL EXTRUSION FAILED! PLEASE CHECK YOUR INPUT FILE'S GRID SPECIFICATIONS!"
		$leftxtr end
		exit -1
	} else {
		$leftxtr end
	}
	
	global domfarbc confarbc ncells confu2_con wu
	
	upvar 3 SIZE_DCY glob_decay
	upvar 3 UNS_ALG uns_algorithm
	upvar 3 UNS_CTYP uns_celltype
	
	pw::Application setGridPreference Unstructured
	
	set diagcol [pw::Collection create]
	$diagcol set $dom_hleft
	set diag [pw::Application begin Create]
	set triandoms [$diagcol do triangulate Initialized]
	$diag end
	
	pw::Entity delete $dom_hleft
	
	set dom_uns [pw::Grid getAll -type pw::DomainUnstructured]

	#size field defination
	set radius [list 1.5 4.5 13.5 40.5 121.5]
	
	set levspc [expr $avg_spc*2]
	lappend decayfactor 0.99
	
	for {set i 0} {$i<6} {incr i} {
		lappend spcfactor [expr $levspc*(($i)**3+1)]
		lappend decayfactor [expr [lindex $decayfactor $i]-0.1]
	}
	
	for {set i 0} {$i<5} {incr i} {
		lappend sourcesh [pw::SourceShape create]
		[lindex $sourcesh $i] cylinder -radius [lindex $radius $i] -length 0

		[lindex $sourcesh $i] setTransform [list 1 0 0 0 0 0 -1 0 0 1 0 0 0 0 0 1]
		[lindex $sourcesh $i] setPivot Base
		[lindex $sourcesh $i] setSectionMinimum 0
		[lindex $sourcesh $i] setSectionMaximum 360
		[lindex $sourcesh $i] setSidesType Plane
		[lindex $sourcesh $i] setBaseType Plane
		[lindex $sourcesh $i] setTopType Plane
		[lindex $sourcesh $i] setEnclosingEntities {}
		[lindex $sourcesh $i] setSpecificationType AxisToPerimeter
		[lindex $sourcesh $i] setBeginSpacing [lindex $spcfactor $i]
		[lindex $sourcesh $i] setBeginDecay [lindex $decayfactor $i]
		[lindex $sourcesh $i] setEndSpacing [lindex $spcfactor [expr $i+1]]
		[lindex $sourcesh $i] setEndDecay [lindex $decayfactor [expr $i+1]]
	}
	
	Source_Unstr
	
	set unstrsolve [pw::Application begin UnstructuredSolver $dom_uns]
	
	foreach dom $dom_uns {
		$dom setSizeFieldDecay $glob_decay
			foreach edge [$dom getEdges] {
				for {set i 1} {$i <= 4} {incr i} {
					lappend unstrbcs_trx [list $dom [$edge getConnector $i] \
								[$edge getConnectorOrientation $i]]
				}
				
				for {set i 5} {$i <= 7} {incr i} {
					lappend unstrbcs [list $dom [$edge getConnector $i] \
								[$edge getConnectorOrientation $i]]
				}
			}
	}
	
	set unstrbcondition [pw::TRexCondition create]
	$unstrbcondition setName trx
	$unstrbcondition apply $unstrbcs_trx
	$unstrbcondition setConditionType Wall
	$unstrbcondition setValue $avg_spc
	
	set unstrbcondition [pw::TRexCondition create]
	$unstrbcondition setName adapts
	$unstrbcondition apply $unstrbcs
	$unstrbcondition setAdaptation On
	
	$dom_uns setUnstructuredSolverAttribute TRexFullLayers 2
	$dom_uns setUnstructuredSolverAttribute TRexMaximumLayers 3
	$dom_uns setUnstructuredSolverAttribute TRexGrowthRate $grg
	$dom_uns setUnstructuredSolverAttribute TRexPushAttributes True
	$dom_uns setUnstructuredSolverAttribute TRexCellType $uns_celltype
	$dom_uns setUnstructuredSolverAttribute TRexIsotropicHeight 0.8
	$dom_uns setUnstructuredSolverAttribute TRexSpacingSmoothing 50
	$dom_uns setUnstructuredSolverAttribute TRexSpacingRelaxationFactor 0.9
	
	
	set UnsCol [pw::Collection create]
	$UnsCol set $dom_uns
	$UnsCol do setUnstructuredSolverAttribute Algorithm $uns_algorithm
	$UnsCol do setUnstructuredSolverAttribute IsoCellType $uns_celltype
	$unstrsolve run Initialize
	$unstrsolve end
	
	set hyb_face [pw::FaceUnstructured createFromDomains $dom_uns]
	
	set hyb_blk [pw::BlockExtruded create]
	$hyb_blk addFace $hyb_face
	
	set hyb_xtr [pw::Application begin ExtrusionSolver $hyb_blk]
	$hyb_blk setExtrusionSolverAttribute Mode Path
	$hyb_blk setExtrusionSolverAttribute PathConnectors $path
	$hyb_blk setExtrusionSolverAttribute PathUseTangent 1
	$hyb_xtr run [expr int($steps-1)]
	$hyb_xtr end
	
	set hdomfar []
	set hdomleft []
	set hdomright []
	
	lappend hdomfar [[lindex [$hyb_blk getFaces] end-1] getDomains]
	lappend hdomleft [[lindex [$hyb_blk getFaces] 0] getDomains]
	lappend hdomright [[lindex [$hyb_blk getFaces] end] getDomains]
	
	foreach dom $hdomfar {
		lappend domBCs(3) $dom
		lappend blkBCs(3) $hyb_blk
	}
	
	foreach dom $hdomleft {
		lappend domBCs(1) $dom
		lappend blkBCs(1) $hyb_blk
	}
	
	foreach dom $hdomright {
		lappend domBCs(2) $dom
		lappend blkBCs(2) $hyb_blk
	}
	
	$blkexam addEntity $hyb_blk
	
	pw::Display setShowSources 0
}

