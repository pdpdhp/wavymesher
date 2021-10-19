# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc CAE_Export { } {

	global blk blktop blkbot blkte hyb_blk scriptDir save_native
	global cae_solver POLY_DEG GRD_TYP symsepdd res_lev 
	global blkexamv wMinVolv cae_export fexmod
	global airfoil_mdl airfoil_input 
	
	global domBCs blkBCs
	
	#==============================================CAE Export--==========================================

	# gathering all domains
	set blk [list {*}$blk $blktop $blkbot $blkte]
	
	# creating general boundary conditions
	set bcairfoil [pw::BoundaryCondition create]
		$bcairfoil setName airfoil
	set bcleft [pw::BoundaryCondition create]
		$bcleft setName left
	set bcright [pw::BoundaryCondition create]
		$bcright setName right
	set bcfar [pw::BoundaryCondition create]
		$bcfar setName farfield

	set dashes [string repeat - 50]

	if {[string compare $cae_solver CGNS]==0} {
		pw::Application setCAESolverAttribute CGNS.FileType adf
		pw::Application setCAESolverAttribute ExportPolynomialDegree $POLY_DEG
	}

	if { ! [string compare $GRD_TYP HYB] } { set blk [list {*}$blk $hyb_blk] } 
	
	#assigning domains to BCs
	foreach domain $domBCs(0) block $blkBCs(0) {$bcairfoil apply [list [list $block $domain]]}

	foreach domain $domBCs(2) block $blkBCs(2) {$bcright apply [list [list $block $domain]]}

	foreach domain $domBCs(1) block $blkBCs(1) {$bcleft apply [list [list $block $domain]]}
	
	foreach domain $domBCs(3) block $blkBCs(3) {$bcfar apply [list [list $block $domain]]}

	foreach bl $blk {lappend blkncells [$bl getCellCount]}
		
	set blkncell [expr [join $blkncells +]]
	set blkorder [string length $blkncell]
	
	#collecting surface elements
	foreach dom $domBCs(0) { 
		lappend domelm [$dom getCellCount] 
		lappend dompts [$dom getPointCount]
	}
	
	set surface_elements [expr [join $domelm +]]
	set surface_nodes [expr [join $dompts +]]
	
	if {$blkorder<6} {
		set blkID "[string range $blkncell 0 1]k"
	} elseif {$blkorder>=6 && $blkorder<7} {
		set blkID "[string range $blkncell 0 2]k"
	} elseif {$blkorder>=7 && $blkorder<10} {
		set blkID "[string range [expr $blkncell/1000000] 0 2]m[string range \
								[expr int($blkncell%1000000)] 0 2]k"
	} elseif {$blkorder>=10 && $blkorder<13} {
		set blkID "[string range [expr $blkncell/1000000000] 0 2]b[string range \
								[expr int($blkncell%1000000000)] 0 2]m"
	}

	append 3dgridname $GRD_TYP "_" Q2D "_" lev $res_lev "_" $blkID "_" $POLY_DEG
	
	puts $fexmod [string repeat - 50]
		
	puts $fexmod "QUASI 2D MULTIBLOCK STRUCTURED GRID | FLATBACK PROFILE | GRID LEVEL $res_lev:"

	puts "QUASI 2D GRID GENERATED FOR LEVEL $res_lev | TOTAL CELLS: $blkncell CELLS"
	puts $symsepdd
	puts "SURFACE ELEMENTS: $surface_elements | SURFACE NODES: $surface_nodes"
	puts $symsepdd
	
	puts $fexmod [string repeat - 50]
	puts $fexmod "total blocks: [llength $blkncells]"
	puts $fexmod "total cells: $blkncell cells"
	puts $fexmod "total surface elements: $surface_elements cells"
	puts $fexmod "total surface mesh points: $surface_nodes nodes"
	puts $fexmod "min volume: [format "%*e" 5 [expr min($blkexamv, $wMinVolv)]]"

	if {[string compare $cae_export YES]==0} {
		# creating export directory
		set exportDir [file join $scriptDir grids/2dquasi]

		file mkdir $exportDir
		
		puts $fexmod [string repeat - 50]
		# CAE specificity in the output file!
		puts $fexmod "Current solver: [set curSolver [pw::Application getCAESolver]]"

		set validExts [pw::Application getCAESolverAttribute FileExtensions]
		puts $fexmod "Valid file extensions: '$validExts'"

		set defExt [lindex $validExts 0]

		set caex [pw::Application begin CaeExport $blk]

		set destType [pw::Application getCAESolverAttribute FileDestination]
		switch $destType {
			Filename { set dest [file join $exportDir "$3dgridname.$defExt"] }
			Folder   { set dest $exportDir }
			default  { return -code error "Unexpected FileDestination value" }
		}
		puts $fexmod "Exporting to $destType: '$dest'"
		puts $fexmod [string repeat - 50]

		# Initialize the CaeExport mode
		set status abort  ;
		if { ![$caex initialize $dest] } {
			puts $fexmod {$caex initialize failed!}
		} else {
			if { ![catch {$caex setAttribute FilePrecision Double}] } {
				puts $fexmod "setAttribute FilePrecision Double"
			}

			if { ![$caex verify] } {
				puts $fexmod {$caex verify failed!}
			} elseif { ![$caex canWrite] } {
				puts $fexmod {$caex canWrite failed!}
			} elseif { ![$caex write] } {
				puts $fexmod {$caex write failed!}
			} elseif { 0 != [llength [set feCnts [$caex getForeignEntityCounts]]] } {
			# print entity counts reported by the exporter
			set fmt {   %-22.22s | %6.6s |}
			puts $fexmod "Number of grid entities exported:"
			puts $fexmod [format $fmt {Entity Type} Count]
			puts $fexmod [format $fmt $dashes $dashes]
			dict for {key val} $feCnts {
				puts $fexmod [format $fmt $key $val]
			}
			set status end ;# all is okay now
			}
		}

		# Display any errors/warnings
		set errCnt [$caex getErrorCount]
		for {set ndx 1} {$ndx <= $errCnt} {incr ndx} {
			puts $fexmod "[$caex getErrorCode $ndx]: '[$caex getErrorInformation $ndx]'"
		}
		# abort/end the CaeExport mode
		$caex $status
	
		puts "info: QUASI 2D $POLY_DEG GRID: '$3dgridname.$defExt' EXPORTED IN GRID DIR."
	}

	if {[string compare $save_native YES]==0} {
		set exportDir [file join $scriptDir grids/2dquasi]
		file mkdir $exportDir
		pw::Application save "$exportDir/$3dgridname.pw"
		
		puts "info: NATIVE FORMAT: '$3dgridname.pw' SAVED IN GRID DIR."
	}
	
	proc WavyCAD_export { } {
		
		global domBCs airfoil_input scriptDir symsepdd
		
		set exportDir [file join $scriptDir grids/models]
		file mkdir $exportDir
		append wfltbackname [lindex [split $airfoil_input .] 0] "_" wavyflatback
		
		set wfltex [pw::Application begin GridExport $domBCs(0)]
		$wfltex initialize -strict -type IGES "$exportDir/$wfltbackname.iges"
		$wfltex setAttribute DomainSurfaceDegree Bicubic
		$wfltex setAttribute FileUnits Meters
		$wfltex verify
		$wfltex write
		$wfltex end
		
		set wavy_database [pw::Database import "$exportDir/$wfltbackname.iges"]
		
		set wavy_mdl \
		[pw::Model assemble -quiltMaximumAngle 180 -quiltBoundaryMaximumAngle 0 $wavy_database]
		
		set wfltex [pw::Application begin DatabaseExport $wavy_mdl]
		$wfltex initialize -strict -type IGES "$exportDir/$wfltbackname.iges"
		$wfltex setAttribute PointwiseCompatibilityMode false
		$wfltex setAttribute FileUnits Meters
		$wfltex verify
		$wfltex write
		$wfltex end
		
		puts "WAVY FLATBACK MODEL: '$wfltbackname.iges' EXPORTED IN GRID DIR."
		puts $symsepdd
		
	}
	
	global FLATBACK_export WAVY_FLATBACK_export
	
	if { ! [string compare $FLATBACK_export YES] } {
		
		set exportDir [file join $scriptDir grids/models]
		file mkdir $exportDir
		append fltbackname [lindex [split $airfoil_input .] 0] "_" flatback
		
		set fltex [pw::Application begin DatabaseExport $airfoil_mdl]
		$fltex initialize -strict -type IGES "$exportDir/$fltbackname.iges"
		$fltex setAttribute PointwiseCompatibilityMode false
		$fltex setAttribute FileUnits Meters
		$fltex verify
		$fltex write
		$fltex end
		
		puts "FLATBACK MODEL: '$fltbackname.iges' EXPORTED IN GRID DIR."
		puts $symsepdd
		
	}
	
	if { ! [string compare $WAVY_FLATBACK_export YES] } {
		
		WavyCAD_export
	}
	
}
