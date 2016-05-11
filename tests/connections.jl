# testing some connections stuff
workspace()
include("../SimpleCircuits.jl")
using SimpleCircuits

function test1()
	
	# implement a voltage divider circuit
	circ = Circuit()
	r1 = Resistor(5e+3)
	r2 = Resistor(10e+3)
	v_DC = DCVoltageSource(5.)
	connect!(circ, v_DC.pHigh, r1.p1)
	connect!(circ, r1.p2, r2.p1, "V_out")
	connect!(circ, r2.p2, v_DC.pLow)



	return circ
end

test1()
