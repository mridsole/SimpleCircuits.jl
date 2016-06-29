# DC sweep the input to a voltage limiter circuit, and plot the output voltage

begin
workspace()
include("../SimpleCircuits.jl")
using SimpleCircuits

circ = Circuit()
r1 = Resistor(0.5e+3)
d1 = Diode(1e-11, 0.026, 1.)
d2 = Diode(1e-11, 0.026, 1.)
v_DC = DCVoltageSource(:V)
connect!(circ, v_DC.pLow, circ.gnd)
connect!(circ, p1(r1), v_DC.pHigh)
connect!(circ, p2(r1), p1(d1), "Vout")
connect!(circ, p2(r1), p2(d2))
connect!(circ, p2(d1), v_DC.pLow)
connect!(circ, p1(d2), v_DC.pLow)

params = Dict(:V => -10.)

op(circ, params=params)
end
