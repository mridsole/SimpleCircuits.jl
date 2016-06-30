SimpleCircuits.Tests.@circuit8

# change the base resistance to a parameter
rb.R = :Rb

params = Dict(:Rb => 1e+3)

# sweep over values of the base resistor
rb_vals = logspace(1., 5., 200)
circ_soln = dc_sweep(circ, :Rb, rb_vals, params)

# plot both the base voltage and the collector voltage against rb
subplot(2, 1, 1)
plot(collect(rb_vals), circ_soln[q1.pB])
plot(collect(rb_vals), circ_soln[q1.pC])
grid(b=true, which="major")

# now, let's fix rb at 10kΩ and sweep over q1.Is
rb.R = 10e+3
q1.Is = :Is
params = Dict(:Is => 1e-12)

Is_vals = logspace(-15., -11., 200)
circ_soln = dc_sweep(circ, :Is, Is_vals, params)

subplot(2, 1, 2)
semilogx(collect(Is_vals), circ_soln[q1.pB])
semilogx(collect(Is_vals), circ_soln[q1.pC])
grid(b=true, which="major")
