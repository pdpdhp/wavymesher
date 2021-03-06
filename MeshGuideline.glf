# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

proc MGuideLine {ref_lev guidedir} {
	
	global ypg dsg grg chord_sg wave_sg ter_sg ler_sg tpts_sg exp_sg imp_sg vol_sg
	
	#Reading Meshing Guidline
	set fp [open "$guidedir/grid_specification_metric.txt" r]

	set i 0
	while {[gets $fp line] >= 0} {
		set g_spec($i) {}
			foreach elem $line {
				lappend g_spec($i) [scan $elem %e]
			}
		incr i
	}
	close $fp

	for {set j 1} {$j<$i} {incr j} {
		lappend y_p [lindex $g_spec($j) 0]
		lappend d_s [lindex $g_spec($j) 1]
		lappend gr [lindex $g_spec($j) 2]
		lappend chord_s [lindex $g_spec($j) 3]
		lappend wave_s [lindex $g_spec($j) 4]
		lappend ter [lindex $g_spec($j) 5]
		lappend ler [lindex $g_spec($j) 6]
		lappend tpt [lindex $g_spec($j) 7]
		lappend exp [lindex $g_spec($j) 8]
		lappend imp [lindex $g_spec($j) 9]
		lappend vol [lindex $g_spec($j) 10]

	}

	set NUM_REF [llength $y_p]

	if {$ref_lev<$NUM_REF} {
		set ypg [lindex $y_p $ref_lev]
		set dsg [lindex $d_s $ref_lev]
		set grg [lindex $gr $ref_lev]
		set chord_sg [lindex $chord_s $ref_lev]
		set wave_sg [lindex $wave_s $ref_lev]
		set ter_sg [lindex $ter $ref_lev]
		set ler_sg [lindex $ler $ref_lev]
		set tpts_sg [lindex $tpt $ref_lev]
		set exp_sg [lindex $exp $ref_lev]
		set imp_sg [lindex $imp $ref_lev]
		set vol_sg [lindex $vol $ref_lev]
	} else {
		puts "PLEASE SELECT THE RIGHT REFINEMENT LEVEL ACCORDING TO YOUR GUIDELINE FILE: ref_lev"
		exit -1
	}

}

proc InterSect { bot top } {
	
	global extr_watchout
	
	foreach t $top b $bot {
		if { [expr ($t-$b)]<0 } {
			puts "WAVE IS INTERSECTING. PLEASE UPDATE YOUR WAVE'S INPUT PARAMETERS."
			exit -1
		}
	}
	
	set max_top [tcl::mathfunc::max {*}$top]
	set min_bot [tcl::mathfunc::min {*}$bot]
	set extr_watchout [expr abs($max_top - $min_bot)]
}

proc WaveRead { } {
	
	global waveDir w1_x w1_y w1_z w2_x w2_y w2_z
	global WAVE_TYPE WAVE_GEN_METHOD WAVE_PERCENT AMPLITUDE_RATIO wv_dpth_up

	set fp1 [open "$waveDir/wave_bot.txt" r]

	set i 0
	while {[gets $fp1 line] >= 0} {
		set wave1_spec($i) {}
			foreach elem $line {
				lappend wave1_spec($i) [scan $elem %e]
			}
		incr i
	}
	close $fp1
	
	set fp2 [open "$waveDir/wave_top.txt" r]

	set i 0
	while {[gets $fp2 line] >= 0} {
		set wave2_spec($i) {}
			foreach elem $line {
				lappend wave2_spec($i) [scan $elem %e]
			}
		incr i
	}
	close $fp2
	
	for {set j 0} {$j<$i} {incr j} {
		lappend w1_x [lindex $wave1_spec($j) 0]
		lappend w1_y [lindex $wave1_spec($j) 1]
		lappend w1_z [lindex $wave1_spec($j) 2]
	}
	
	for {set j 0} {$j<$i} {incr j} {
		lappend w2_x [lindex $wave2_spec($j) 0]
		lappend w2_y [lindex $wave2_spec($j) 1]
		lappend w2_z [lindex $wave2_spec($j) 2]
	}
	
	InterSect $w1_z $w2_z

	set min_w1_z [tcl::mathfunc::min {*}$w1_z]
	set min_w2_z [tcl::mathfunc::min {*}$w2_z]

	set max_w1_z [tcl::mathfunc::max {*}$w1_z]
	set max_w2_z [tcl::mathfunc::max {*}$w2_z]
	
	set wv_dpth_up [expr (abs($min_w2_z-$max_w1_z)/abs($max_w2_z-$min_w1_z))*100]

	puts "WAVE TYPE: $WAVE_TYPE | METHOD: $WAVE_GEN_METHOD | DEPTH: [format %.2f $wv_dpth_up]% \
		| WAVY PERCENT: $WAVE_PERCENT% | AMPL. RATIO: $AMPLITUDE_RATIO%"
}
