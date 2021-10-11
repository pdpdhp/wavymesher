# =============================================================
# This script is written to generate structured multi-block
# grid with different TE waviness over the DU97-flatback profile 
# according to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc GridFlowprop_Update {plablist meshvlist guidedir} {
	
	set k 20
		
	foreach label $plablist param $meshvlist {
		exec sed -i "0,/$label/{/$label/d;}" $guidedir/gridflowprop.py
		exec sed -i "$k a $label = \[$param\]" $guidedir/gridflowprop.py
		incr k 4
	} 
	
	exec python3 $guidedir/gridflowprop.py
	return 0
}

proc Wave_Update {plablist meshvlist waveDir} {
	
	set k 28
		
	foreach label $plablist param $meshvlist {
		exec sed -i "0,/$label/{/$label/d;}" $waveDir/wavegen.py
		exec sed -i "$k a $label = \[$param\]" $waveDir/wavegen.py
		incr k 4
	} 
	
	exec python3 $waveDir/wavegen.py
	return 0
}
