# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc CAE_Export { } {

	global blk blktop blkbot blkte scriptDir save_native
	
	upvar 1 cae_solver cae_fmt
	upvar 1 POLY_DEG ply_degree
	upvar 1 GRD_TYP grid_type
	upvar 1 symsepdd asep
	upvar 1 res_lev grid_level
	upvar 1 blkexamv minVol1
	upvar 1 wMinVolv minVol2
	upvar 1 cae_export caeexprt
	upvar 1 fexmod outfile
	
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

	if {[string compare $cae_fmt CGNS]==0} {
		pw::Application setCAESolverAttribute CGNS.FileType adf
		pw::Application setCAESolverAttribute ExportPolynomialDegree $ply_degree
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

	append 3dgridname $grid_type "_" Q2D "_" lev $grid_level "_" $blkID "_" $ply_degree
	
	puts $outfile [string repeat - 50]
		
	puts $outfile "QUASI 2D MULTIBLOCK STRUCTURED GRID | FLATBACK PROFILE | GRID LEVEL $grid_level:"
	puts $asep
	puts "QUASI 2D GRID GENERATED FOR LEVEL $grid_level | TOTAL CELLS: $blkncell HEX"
	puts $asep

	puts $outfile [string repeat - 50]
	puts $outfile "total blocks: [llength $blkncells]"
	puts $outfile "total cells: $blkncell cells"
	puts $outfile "min volume: [format "%*e" 5 [expr min($minVol1, $minVol2)]]"
		
		
	if {[string compare $caeexprt YES]==0} {
		# creating export directory
		set exportDir [file join $scriptDir grids/2dquasi]

		file mkdir $exportDir
		
		puts $outfile [string repeat - 50]
		# CAE specificity in the output file!
		puts $outfile "Current solver: [set curSolver [pw::Application getCAESolver]]"

		set validExts [pw::Application getCAESolverAttribute FileExtensions]
		puts $outfile "Valid file extensions: '$validExts'"

		set defExt [lindex $validExts 0]

		set caex [pw::Application begin CaeExport $blk]

		set destType [pw::Application getCAESolverAttribute FileDestination]
		switch $destType {
			Filename { set dest [file join $exportDir "$3dgridname.$defExt"] }
			Folder   { set dest $exportDir }
			default  { return -code error "Unexpected FileDestination value" }
		}
		puts $outfile "Exporting to $destType: '$dest'"
		puts $outfile [string repeat - 50]

		# Initialize the CaeExport mode
		set status abort  ;
		if { ![$caex initialize $dest] } {
			puts $outfile {$caex initialize failed!}
		} else {
			if { ![catch {$caex setAttribute FilePrecision Double}] } {
				puts $outfile "setAttribute FilePrecision Double"
			}

			if { ![$caex verify] } {
				puts $outfile {$caex verify failed!}
			} elseif { ![$caex canWrite] } {
				puts $outfile {$caex canWrite failed!}
			} elseif { ![$caex write] } {
				puts $outfile {$caex write failed!}
			} elseif { 0 != [llength [set feCnts [$caex getForeignEntityCounts]]] } {
			# print entity counts reported by the exporter
			set fmt {   %-22.22s | %6.6s |}
			puts $outfile "Number of grid entities exported:"
			puts $outfile [format $fmt {Entity Type} Count]
			puts $outfile [format $fmt $dashes $dashes]
			dict for {key val} $feCnts {
				puts $outfile [format $fmt $key $val]
			}
			set status end ;# all is okay now
			}
		}

		# Display any errors/warnings
		set errCnt [$caex getErrorCount]
		for {set ndx 1} {$ndx <= $errCnt} {incr ndx} {
			puts $outfile "[$caex getErrorCode $ndx]: '[$caex getErrorInformation $ndx]'"
		}
		# abort/end the CaeExport mode
		$caex $status
	
		puts "info: QUASI 2D $ply_degree GRID: $3dgridname.$defExt EXPORTED IN GRID DIR."
	}

	if {[string compare $save_native YES]==0} {
		set exportDir [file join $scriptDir grids/2dquasi]
		file mkdir $exportDir
		pw::Application save "$exportDir/$3dgridname.pw"
		
		puts "info: NATIVE FORMAT: $3dgridname.pw SAVED IN GRID DIR."
	}
}
