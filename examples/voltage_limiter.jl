# DC sweep the input to a voltage limiter circuit, and plot the output voltage

circ = Circuit()
r1 = Resistor(0.5e+3)
d1 = Diode(1e-11, 0.026, 1.)
d2 = Diode(1e-11, 0.026, 1.)
v_DC = DCVoltageSource(:V_in)
connect!(circ, v_DC.pLow, circ.gnd)
connect!(circ, p1(r1), v_DC.pHigh)
connect!(circ, p2(r1), p1(d1), "Vout")
connect!(circ, p2(r1), p2(d2))
connect!(circ, p2(d1), v_DC.pLow)
connect!(circ, p1(d2), v_DC.pLow)

# sweep over the input voltage
params = Dict(:V => -10.)

v_in_range = -15.:0.1:15.
circ_soln = dc_sweep(circ, :V_in, v_in_range, params)

# plot the input voltage against the output voltage - demonstrates that
# the output voltage is limited by the ~0.6 V 'on' voltage of the diodes
grid(b=true, which="major")
plot(v_in_range, circ_soln[p1(d1)])
