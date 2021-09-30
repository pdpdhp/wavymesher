# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

package require PWI_Glyph 3.18.3

proc Config_Prep { } {

	global guidelineDir MeshParameters defParas meshparacol res_lev Wave_Type Num_Wave

	if { $MeshParameters != "" } {
		puts "GRID VARIABLES ARE SET BY $MeshParameters"
		ParamDefualt $MeshParameters
	} else {
		puts "DEFAULT GRID VARIABLES ARE SET BY defaultMeshParameters.glf"
	}
	
	#updating gridflow.py with new sets of variables
	GridFlowprop_Update [lrange $defParas end-8 end] [lrange $meshparacol end-8 end] $guidelineDir
	
	MGuideLine $res_lev $guidelineDir
	
	if {[string compare $Wave_Type W2]==0 && [expr [lindex [split $Num_Wave ","] 0]%2] != 0} {
		puts "NUMBER OF WAVES FOR W2 (I.E. COSINE WAVE) MUST BE EVEN!"
		exit -1
	}
	
	if {[string compare $Wave_Type W3]==0 && [expr [llength [split $Num_Wave ","]]-2] != 0} {
		puts "NUMBER OF WAVES FOR W3 (I.E. COSINE AND SINE WAVES) MUST BE TWO NUMBERS SEPERATED BY COMMA!"
		exit -1
	}
}

proc CAD_Read { } {
	
	global cae_solver airfoil geoDir GRD_TYP model_Q2D model_2D
	
	upvar 1 symsepdd asep
	#grid tolerance
	pw::Grid setNodeTolerance 1.0e-07
	pw::Grid setConnectorTolerance 1.0e-07
	pw::Grid setGridPointTolerance 1.0e-07

	pw::Connector setCalculateDimensionMaximum 100000
	pw::Application setCAESolver $cae_solver 2
	
	if {[string compare $airfoil FLATBACK]==0} {
		if {[string compare $GRD_TYP STR]==0} {
			puts "STRUCTURED MULTIBLOCK GRID SELECTED | FLATBACK SECTION IMPORTED."
			puts $asep
		} 
	} else {
		puts "PLEASE SELECT THE RIGHT AIRFOIL!"
		exit -1
	}

	if {[string compare $airfoil FLATBACK]==0} {
		#Import Geometry
		set tmp_model [pw::Application begin DatabaseImport]
		  $tmp_model initialize -strict -type Automatic $geoDir/flatbackquilted.iges
		  $tmp_model read
		  $tmp_model convert
		$tmp_model end
		unset tmp_model
		
	} else {
		puts "PLEASE SELECT THE RIGHT AIRFOIL!"
		exit -1
	}

}

#-------------------------------------- RESET APPLICATION--------------------------------------
pw::Application reset
pw::Application clearModified

set scriptDir [file dirname [info script]]
set guidelineDir [file join $scriptDir guideline]
set geoDir [file join $scriptDir geo]

source [file join $scriptDir "ParamRead.glf"]
source [file join $guidelineDir "GridParamUpdate.glf"]
source [file join $scriptDir "MeshGuideline.glf"]
source [file join $scriptDir "mesh.glf"]
source [file join $scriptDir "WaveRemesh.glf"]
source [file join $scriptDir "cae_exporter.glf"]

ParamDefualt [file join $scriptDir "defaultMeshParameters.glf"]

set MeshParameters ""

set symsep [string repeat = 105]
set symsepd [string repeat . 105]
set symsepdd [string repeat - 105]

if {[llength $argv] != 0} {
	set MeshParameters [lindex $argv 0]
}

puts $symsepdd

#----------------------------------------------------------------------------
#READING AND UPDATING GRID PARAMETERS AND VARIABLES
Config_Prep

puts $symsepdd
puts "GRID GUIDELINE: Level: $res_lev | Y+: $ypg | Delta_S(m): $dsg | GR: $grg | Chordwise_Spacing(m): $chord_sg"
puts $symsep

set time_start [pwu::Time now]

#----------------------------------------------------------------------------
#READING CAD MODEL
CAD_Read

#----------------------------------------------------------------------------
#READING WAVE AT TRAILING EDGE
set wavelist [list {*}[lrange $meshparacol 4 10] $wave_sg $span]
set wavelab [list {*}[lrange $defParas 4 10] WV_NOD span]
set wscales [list $Wave_inVScale $Wave_outVScale]
set woutdegs [list $Wave_outTopVdeg $Wave_outBottomVdeg]

Wave_Update $wavelab $wavelist $geoDir

WaveRead

set blkexam [pw::Examine create BlockVolume]

#----------------------------------------------------------------------------
#PREPARING THE TOPOLOGY FOR MESH AND GENERATING THE MESH
Topo_Prep_Mesh $Wavy_Percent
#
#----------------------------------------------------------------------------
set fexmod [open "$scriptDir/CAE_export.out" w]
#
#----------------------------------------------------------------------------
WaveRemesh $wscales $woutdegs
#
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

puts "GRID INFO WRITTEN TO CAE_export.out"
puts $symsep
puts "COMPLETE!"
