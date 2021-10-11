# =============================================================
# This script is written to generate structured multi-block
# grid with almost any types of waviness at TE for almost any 
# airfoil according to the grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Oct 2021
#==============================================================

#setting epsilon
set eps [set tcl::mathfunc::epsilon 2.2e-16]
set pi 3.1415926535897931

#setting floating point
proc tcl::mathfunc::teq {x y} {
	variable epsilon
	expr {abs($x - $y) < $epsilon}
}

# du97 flatback's thickness distribution function
# Equation: '{thickness} =1.45*(({xu}-1.9*{thd})**3.6)*{thd} - 35.6*{thd}**3.3 +(0.499*({xu}-0.3))**4.3'
proc upper_flatback_thickness_dis {x thk flt_percent endtk te_tk} {\
	
	global chordln
	
	set ref_tk [expr (1.45*(($chordln-1.9*$endtk)**3.6)*$endtk \
			- 35.6*$endtk**3.3 +(0.499*($chordln-0.3))**4.3)+$te_tk*0.5]

	set te_thk [expr $flt_percent*$chordln*0.01]

	return [expr (($te_thk*0.5-$ref_tk)*(1/($ref_tk-$te_tk*0.5))+1)*(1.45*(($x-1.9*$thk)**3.6)*$thk -\
								 35.6*$thk**3.3 +(0.499*($x-0.3))**4.3)]
}

# du97 flatback's thickness distribution function
# Equation: '{thickness} =0.43*(({xl}-1.1*{thd})**2.8)*{thd} + 1.2*{thd}**3.3 - 0.3*(1.3*{thd})**3.9 '
proc lower_flatback_thickness_dis {x thk flt_percent endtk te_tk} {
	global chordln
	
	set ref_tk [expr (0.43*(($chordln-1.1*$endtk)**2.8)*$endtk + \
				1.2*$endtk**3.3 - 0.3*(1.3*$endtk)**3.9)+$te_tk*0.5 ]

	set te_thk [expr $flt_percent*$chordln*0.01]

	return [expr (($te_thk*0.5-$ref_tk)*(1/($ref_tk-$te_tk*0.5))+1)*(0.43*(($x-1.1*$thk)**2.8)*$thk +\
								 1.2*$thk**3.3 - 0.3*(1.3*$thk)**3.9) ]
}
