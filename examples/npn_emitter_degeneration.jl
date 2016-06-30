SimpleCircuits.Tests.@circuit8

# simulate without emitter degeneration
println(op(circ))

# disconnect the emitter, and add in a new emitter resistor
disconnect!(circ, q1.pE)

re = Resistor(100.)
connect!(circ, re.p1, q1.pE)
connect!(circ, re.p2, vcc.pLow)

# try simulating
circ_soln = op(circ)
println(circ_soln)

# verify this .. ?
#soln_raw = op_raw(circ)
#sym_map = gen_sym_map(circ)
#F = gen_sys_F(:F, sym_map, circ)
#println(F(soln_raw, zeros(length(soln_raw))))
#
#println(circ_soln)

# now try sweeping on the 
