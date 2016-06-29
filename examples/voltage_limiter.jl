# DC sweep the input to a voltage limiter circuit, and plot the output voltage

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

v_range = -15.:0.1:15.
v_out = zeros(length(v_range))

for i = 1:length(v_range)
    params[:V] = v_range[i]
    soln = op(circ, params=params)
    v_out[i] = soln[p2(r1)]
end
