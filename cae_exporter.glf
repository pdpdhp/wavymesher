# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc CAE_Export { } {

	global blk blktop blkbot blkte hyb_blk hdoms scriptDir save_native
	global cae_solver POLY_DEG GRD_TYP symsepdd res_lev 
	global blkexamv wMinVolv cae_export fexmod
	global airfoil_mdl airfoil_input domairqbc
	
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

	#assigning BCs
	#CAE Boundary Condition
	set domairqbc []
	set blkairqbc []
	set domleftqbc []
	set blkleftqbc []
	set domrightqbc []
	set blkrightqbc []
	set domfarqbc []
	set blkfarqbc []
	
	array set dommairqbc []
	array set dommrightqbc []
	array set dommleftqbc []
	array set dommfarqbc []
	set k 1
	
	for {set k 1} {$k<=[llength $blk]} {incr k} {
		set dommairqbc($k) []
		set dommrightqbc($k) []
		set dommleftqbc($k) []
		set dommfarqbc($k) []
	}
	
	if { ! [string compare $GRD_TYP STR] } {
		# finding proper domains and blocks corresponding to BCs
		#block 0
		set dommairqbc(1) [[[lindex $blk 0] getFace 3] getDomains]
		set dommrightqbc(1) [[[lindex $blk 0] getFace 6] getDomains]
		set dommleftqbc(1) [[[lindex $blk 0] getFace 1] getDomains]
		set dommfarqbc(1) [[[lindex $blk 0] getFace 5] getDomains]
		
		foreach ent $dommairqbc(1) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 0]
		}
			
		foreach ent $dommrightqbc(1) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 0]
		}
			
		foreach ent $dommleftqbc(1) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 0]
		}
		
		foreach ent $dommfarqbc(1) {
			lappend domfarqbc $ent
			lappend blkfarqbc [lindex $blk 0]
		}
		
		#block 1
		set dommrightqbc(2) [[[lindex $blk 1] getFace 6] getDomains]
		set dommleftqbc(2) [[[lindex $blk 1] getFace 1] getDomains]
		set dommfarqbc(2) [[[lindex $blk 1] getFace 5] getDomains]
			
		foreach ent $dommrightqbc(2) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 1]
		}
		
		foreach ent $dommleftqbc(2) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 1]
		}
		
		foreach ent $dommfarqbc(2) {
			lappend domfarqbc $ent
			lappend blkfarqbc [lindex $blk 1]
		}
			
		#block 2
		set dommrightqbc(3) [[[lindex $blk 2] getFace 2] getDomains]
		set dommleftqbc(3) [[[lindex $blk 2] getFace 4] getDomains]
		set dommairqbc(2) [[[lindex $blk 2] getFace 1] getDomains]
			
		foreach ent $dommrightqbc(3) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 2]
		}
		
		foreach ent $dommleftqbc(3) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 2]
		}
		
		foreach ent $dommairqbc(2) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 2]
		}
			
		#block 3
		set dommrightqbc(4) [[[lindex $blk 3] getFace 2] getDomains]
		set dommleftqbc(4) [[[lindex $blk 3] getFace 4] getDomains]
		set dommairqbc(3) [[[lindex $blk 3] getFace 1] getDomains]
		
		foreach ent $dommrightqbc(4) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 3]
		}
		
		foreach ent $dommleftqbc(4) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 3]
		}
		
		foreach ent $dommairqbc(3) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 3]
		}
			
		#block 4
		set dommrightqbc(5) [[[lindex $blk 4] getFace 2] getDomains]
		set dommleftqbc(5) [[[lindex $blk 4] getFace 4] getDomains]
		set dommairqbc(4) [[[lindex $blk 4] getFace 1] getDomains]
		
		foreach ent $dommrightqbc(5) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 4]
		}
		
		foreach ent $dommleftqbc(5) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 4]
		}
		
		foreach ent $dommairqbc(4) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 4]
		}
	
	} elseif { ! [string compare $GRD_TYP HYB] } {
		
		set blk [list {*}$blk $hyb_blk]
		
		#block 0
		set dommairqbc(1) [[[lindex $blk 0] getFace 3] getDomains]
		set dommrightqbc(1) [[[lindex $blk 0] getFace 6] getDomains]
		set dommleftqbc(1) [[[lindex $blk 0] getFace 1] getDomains]
		
		foreach ent $dommairqbc(1) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 0]
		}
			
		foreach ent $dommrightqbc(1) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 0]
		}
			
		foreach ent $dommleftqbc(1) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 0]
		}

		#block 1
		set dommrightqbc(2) [[[lindex $blk 1] getFace 6] getDomains]
		set dommleftqbc(2) [[[lindex $blk 1] getFace 1] getDomains]
			
		foreach ent $dommrightqbc(2) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 1]
		}
		
		foreach ent $dommleftqbc(2) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 1]
		}
		
		#block 2
		set dommrightqbc(3) [[[lindex $blk 2] getFace 1] getDomains]
		set dommleftqbc(3) [[[lindex $blk 2] getFace 4] getDomains]
		set dommairqbc(2) [[[lindex $blk 2] getFace 2] getDomains]
			
		foreach ent $dommrightqbc(3) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 2]
		}
		
		foreach ent $dommleftqbc(3) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 2]
		}
		
		foreach ent $dommairqbc(2) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 2]
		}
		
		#block 3
		set dommrightqbc(4) [[[lindex $blk 3] getFace 2] getDomains]
		set dommleftqbc(4) [[[lindex $blk 3] getFace 4] getDomains]
		set dommairqbc(3) [[[lindex $blk 3] getFace 1] getDomains]
		
		foreach ent $dommrightqbc(4) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 3]
		}
		
		foreach ent $dommleftqbc(4) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 3]
		}
		
		foreach ent $dommairqbc(3) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 3]
		}
			
		#block 4
		set dommrightqbc(5) [[[lindex $blk 4] getFace 2] getDomains]
		set dommleftqbc(5) [[[lindex $blk 4] getFace 4] getDomains]
		set dommairqbc(4) [[[lindex $blk 4] getFace 1] getDomains]
		
		foreach ent $dommrightqbc(5) {
			lappend domrightqbc $ent
			lappend blkrightqbc [lindex $blk 4]
		}
		
		foreach ent $dommleftqbc(5) {
			lappend domleftqbc $ent
			lappend blkleftqbc [lindex $blk 4]
		}
		
		foreach ent $dommairqbc(4) {
			lappend domairqbc $ent
			lappend blkairqbc [lindex $blk 4]
		}
		
		#block hybrid
		lappend domfarqbc [lindex $hdoms 0]
		lappend blkfarqbc [lindex $blk end]
		
		lappend domleftqbc [lindex $hdoms 1]
		lappend blkleftqbc [lindex $blk end]
		
		lappend domrightqbc [lindex $hdoms 2]
		lappend blkrightqbc [lindex $blk end]

	} 
	
	#assigning domains to BCs
	foreach domain $domairqbc block $blkairqbc {
		$bcairfoil apply [list [list $block $domain]]
	}

	foreach domain $domrightqbc block $blkrightqbc {
		$bcright apply [list [list $block $domain]]
	}

	foreach domain $domleftqbc block $blkleftqbc {
		$bcleft apply [list [list $block $domain]]
	}
	
	foreach domain $domfarqbc block $blkfarqbc {
		$bcfar apply [list [list $block $domain]]
	}

	foreach bl $blk {
		lappend blkncells [$bl getCellCount]
	}
		
	set blkncell [expr [join $blkncells +]]
	set blkorder [string length $blkncell]

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

	puts "QUASI 2D GRID GENERATED FOR LEVEL $res_lev | TOTAL CELLS: $blkncell HEX"
	puts $symsepdd

	puts $fexmod [string repeat - 50]
	puts $fexmod "total blocks: [llength $blkncells]"
	puts $fexmod "total cells: $blkncell cells"
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
		
		global domairqbc airfoil_input scriptDir symsepdd
		
		set exportDir [file join $scriptDir grids/models]
		file mkdir $exportDir
		append wfltbackname [lindex [split $airfoil_input .] 0] "_" wavyflatback
		
		set wfltex [pw::Application begin GridExport $domairqbc]
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
