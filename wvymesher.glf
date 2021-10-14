# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

package require PWI_Glyph 3.18.3

proc Config_Prep { } {

	global guidelineDir MeshParameters defParas meshparacol res_lev WAVE_TYPE NUM_WAVE

	if { $MeshParameters != "" } {
		puts "GRID VARIABLES ARE SET BY $MeshParameters"
		ParamDefualt $MeshParameters
	} else {
		puts "DEFAULT GRID VARIABLES ARE SET BY defaultMeshParameters.glf"
	}
	
	#updating gridflow.py with new sets of variables
	GridFlowprop_Update [lrange $defParas end-8 end] [lrange $meshparacol end-8 end] $guidelineDir
	
	MGuideLine $res_lev $guidelineDir
	
	if {[string compare $WAVE_TYPE W2]==0 && [expr [lindex [split $NUM_WAVE ","] 0]%2] != 0} {
		puts "NUMBER OF WAVES FOR W2 (I.E. COSINE WAVE) MUST BE EVEN!"
		exit -1
	}
	
	if {[string compare $WAVE_TYPE W3]==0 && [expr [llength [split $NUM_WAVE ","]]-2] != 0} {
		puts "NUMBER OF WAVES FOR W3 (I.E. COSINE AND SINE WAVES) MUST BE TWO NUMBERS SEPERATED BY COMMA!"
		exit -1
	}
}

proc CAD_Read { airfoilp } {
	
	global cae_solver GRD_TYP nprofile nxnodes nynodes chordln NprofullFilename
	
	upvar 1 symsepdd asep
	
	#grid tolerance
	pw::Grid setNodeTolerance 1.0e-07
	pw::Grid setConnectorTolerance 1.0e-07
	pw::Grid setGridPointTolerance 1.0e-07

	pw::Connector setCalculateDimensionMaximum 100000
	pw::Application setCAESolver $cae_solver 3
	
	if { ! [string compare $GRD_TYP STR] } {
		puts "STRUCTURED MULTIBLOCK GRID IS SELECTED."
		puts $asep
	} elseif { ! [string compare $GRD_TYP HYB] } {
		puts "HYBRID GRID IS SELECTED."
		puts $asep
	}
	
	if { $NprofullFilename != "" } {
		
		set fpmod [open $airfoilp r]

		while {[gets $fpmod line] >= 0} {
			lappend nxnodes [expr [lindex [split $line ","] 0]*1000]
			lappend nynodes [expr [lindex [split $line ","] 1]*1000]
		}
		close $fpmod
		
		set chordln [expr [tcl::mathfunc::max {*}$nxnodes]/1000]
		
		puts "AIRFOIL COORDINATES ARE IMPORTED: $nprofile"
		puts $asep
		
	} else {
	
		puts "PLEASE INDICATE AIRFOIL COORDINATES AS INPUT."
		exit -1
	
	}
}

proc WAVYMESHER {} {
	
	global MeshParameters nprofile NprofullFilename
	global res_lev ypg dsg grg chord_sg
	global scriptDir fexmod waveDir blkexam blkexamv
	global defParas meshparacol wave_sg span 
	global symsepdd
	
	upvar 1 WAVE_PERCENT wv_prct
	upvar 1 WAVE_GEN_METHOD wv_mtd
	upvar 1 WAVE_TYPE wv_typ
	upvar 1 WAVE_DEPTH wv_dpth
	upvar 1 ENDSU endsu
	upvar 1 ENDSL endsl
	
	upvar 1 WAVE_Rotational_Angle_Top ZZ_Atop
	upvar 1 WAVE_Rotational_Angle_Bottom ZZ_Abot
	
	set symsep [string repeat = 105]
	set symsepd [string repeat . 105]
	set symsepdd [string repeat - 105]
	
	if { $NprofullFilename == "" } {
		if [pw::Application isInteractive] {
			set NprofullFilename [tk_getOpenFile]
		}
	}

	if { ! [file readable $NprofullFilename] } {
		puts "WITHOUT AIRFOIL COORDINATES AS INPUT THIS SCRIPT DOESN'T WORK."
		puts "AIRFOIL COORDINATES: $nprofile does not exist or is not readable"
		exit -1
	}
	
	#----------------------------------------------------------------------------
	#READING AND UPDATING GRID PARAMETERS AND VARIABLES
	Config_Prep

	puts $symsepdd
	puts "GRID GUIDELINE: Level: $res_lev | Y+: $ypg | Delta_S(m): $dsg | GR: $grg | Chordwise_Spacing(m): $chord_sg"
	puts $symsep

	set time_start [pwu::Time now]

	#----------------------------------------------------------------------------
	#READING INPUT AIRFOIL COORDINATES
	CAD_Read $NprofullFilename
	
	#GENERATING THE MODEL BASED ON INPUT AIRFOIL
	MDL_GEN [lrange $meshparacol 2 4]

	#----------------------------------------------------------------------------
	#INCOMPATIBLE WAVY SPECIFICATIONS
	if { [string compare $wv_mtd spline] && ! [string compare $wv_typ W1] } {
		puts "ONLY SPLINE WAVE METHOD IS COMPATIBLE WITH:"
		puts "$wv_typ (i.e. SINE WAVE) WITH $wv_dpth% WAVE DEPTH."
		puts $symsep
		exit -1
	}
	
	if { [string compare $wv_mtd spline] && ($ZZ_Abot!=0 || $ZZ_Atop!=0) } {
		puts "ONLY SPLINE WAVE METHOD IS COMPATIBLE WITH ROTATING WAVINESS."
		puts "info: wave's rotational angles is ignord."
		puts $symsep
		set ZZ_Abot 0
		set ZZ_Atop 0
	}

	#----------------------------------------------------------------------------
	#READING WAVE AT TRAILING EDGE
	set wavelist [list {*}[lrange $meshparacol 6 10] $wave_sg $span \
						$ZZ_Atop $ZZ_Abot $endsu $endsl]

	set wavelab [list {*}[lrange $defParas 6 10] WV_NOD span ZZ_Atop ZZ_Abot ENDSU ENDSL]
	set wscales [lrange $meshparacol 11 12]
	set woutdegs [lrange $meshparacol 13 14]

	Wave_Update $wavelab $wavelist $waveDir

	WaveRead
	
	puts "WAVE TYPE: $wv_typ | METHOD: $wv_mtd | DEPTH(%): $wv_dpth | WAVY PERCENT(%): $wv_prct "
	puts $symsep
	
	set blkexam [pw::Examine create BlockVolume]

	#----------------------------------------------------------------------------
	#PREPARING THE TOPOLOGY FOR MESH AND GENERATING THE MESH
	Topo_Prep_Mesh $wv_prct

	#----------------------------------------------------------------------------
	set fexmod [open "$scriptDir/CAE_export.out" w]

	#----------------------------------------------------------------------------

	WaveRemesh $wv_mtd $wv_dpth $wv_prct $wscales $woutdegs

	#DOMAIN EXAMINE
	$blkexam examine
	set blkexamv [$blkexam getMinimum]

	#----------------------------------------------------------------------------
	#CAE EXPORT
	CAE_Export

	pw::Display saveView 1 [list {0.50 -0.015 0.5} {-0.10 0.47 0.0} {-0.89 -0.28 -0.35} 86.46 2.53]
	pw::Display recallView 1

	set time_end [pwu::Time now]
	set runtime [pwu::Time subtract $time_end $time_start]
	set tmin [expr int([lindex $runtime 0]/60)]
	set tsec [expr [lindex $runtime 0]%60]
	set tmsec [expr int(floor([lindex $runtime 1]/1000))]

	puts $fexmod [string repeat - 50]
	puts $fexmod "runtime: $tmin min $tsec sec $tmsec ms" 
	puts $fexmod [string repeat - 50]
	close $fexmod

	puts "GRID INFO WRITTEN TO 'CAE_export.out'"
	puts $symsep
	puts "COMPLETE!"

	exit
}

#-------------------------------------- RESET APPLICATION--------------------------------------
pw::Application reset
pw::Application clearModified

set scriptDir [file dirname [info script]]
set guidelineDir [file join $scriptDir guideline]
set waveDir [file join $guidelineDir wave]

source [file join $scriptDir "ParamRead.glf"]
source [file join $guidelineDir "GridParamUpdate.glf"]
source [file join $scriptDir "MeshGuideline.glf"]
source [file join $scriptDir "mesh.glf"]
source [file join $scriptDir "Rmeshwvy.glf"]
source [file join $scriptDir "cae_exporter.glf"]
source [file join $scriptDir "dufunction.glf"]
source [file join $scriptDir "flatbackGen.glf"]
source [file join $scriptDir "quiltGen.glf"]
source [file join $scriptDir "Blendwvy.glf"]
source [file join $scriptDir "Hbrdmesh.glf"]

ParamDefualt [file join $scriptDir "defaultMeshParameters.glf"]

set MeshParameters ""
set nprofile ""
set NprofullFilename ""
set MparafullFilename ""

if [pw::Application isInteractive] {

	pw::Script loadTK

	set wkrdir [pwd]
	
	proc meshparametersgui { } {

		global wkrdir MeshParameters MparafullFilename
		cd $wkrdir

		if { $MeshParameters != "" } {
		
			file exists $MparafullFilename
			puts "Input parameters: $MeshParameters"

		} else {

			set types {
 				{{GLYPH Files}  {.glf}}
 				{{All Files}      *   }
 			}

			set initDir $::wkrdir
			set MparafullFilename [tk_getOpenFile -initialdir $initDir -filetypes $types]
			set MeshParameters [file tail $MparafullFilename]
		}
	}
	
	proc airfoilp { } {

		global wkrdir nprofile NprofullFilename
		cd $wkrdir

		if { $NprofullFilename != "" } {

			file exists $NprofullFilename
			puts "Input airfoil coordinates: $nprofile"

		} else {

			set types {
				{{Text Files}  {.txt}}
				{{All Files}      *  }
			}
			
			set initDir $::wkrdir
			set NprofullFilename [tk_getOpenFile -initialdir $initDir -filetypes $types]
			set nprofile [file tail $NprofullFilename]
		}
	}

	wm title . "WAVY MESHER"
	grid [ttk::frame .c -padding "5 5 5 5"] -column 0 -row 0 -sticky nwes
	grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1
	grid [ttk::labelframe .c.lf -padding "5 5 5 5" -text "SELECT MESH PARAMETERS"]
	grid [ttk::button .c.lf.mfl -text "MESHING INPUT" -command \
					meshparametersgui]                           -row 1 -column 1 -sticky e
	grid [ttk::entry .c.lf.mfe -width 60 -textvariable MeshParameters]           -row 1 -column 2 -sticky e
	grid [ttk::button .c.lf.ptl -text "PROFILE INPUT" -command airfoilp]         -row 2 -column 1 -sticky e
	grid [ttk::entry .c.lf.pte -width 60 -textvariable nprofile]                 -row 2 -column 2 -sticky e
	grid [ttk::button .c.lf.gob -text "WAVY MESH" -command WAVYMESHER]           -row 3 -column 2 -sticky e
	
	foreach w [winfo children .c.lf] {grid configure $w -padx 5 -pady 5}
	
	focus .c.lf.mfl
	
	::tk::PlaceWindow . widget
	
	bind . <Return> { WAVYMESHER }

} else {
	
	if {[llength $argv] == 2} {
		set MeshParameters [lindex $argv 0]
		set NprofullFilename [lindex $argv 1]
	} elseif {[llength $argv] == 1} {
		set NprofullFilename [lindex $argv 0]
	} else {
	  puts "Invalid command line input! WITHOUT AIRFOIL COORDINATES AS INPUT THIS PROGRAM DOESN'T WORK."
	  puts "pointwise -b wvymesher.glf ?MeshParameters.glf? airfoil_coordinates.txt <airfoil file>"
	  exit
	}
	
	WAVYMESHER
}
