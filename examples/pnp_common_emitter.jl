# assuming we have SimpleCircuits and PyPlot 
circ = Circuit()
q1 = PNP()
RB1 = Resistor(10e+3)
RB2 = Resistor(40e+3)
RE = Resistor(2e+3)
RC = Resistor(4e+3)
VEE = DCVoltageSource(10.7)
VBB = DCVoltageSource(10.0)

connect!(circ, VEE.pLow, circ.gnd)
connect!(circ, VBB.pLow, circ.gnd)
connect!(circ, RB1.p1, VBB.pHigh)
connect!(circ, RB1.p2, q1.pB)
connect!(circ, RB2.p1, q1.pB)
connect!(circ, RB2.p2, circ.gnd)
connect!(circ, RE.p1, VEE.pHigh)
connect!(circ, RE.p2, q1.pE)
connect!(circ, q1.pC, RC.p1)
connect!(circ, RC.p2, circ.gnd)

q1.Is = 4e-15
q1.βf = 100.

cop = op(circ)
